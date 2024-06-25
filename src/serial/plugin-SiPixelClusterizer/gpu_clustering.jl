# How is this implemented in JULIA?
# #ifdef GPU_DEBUG
# uint32_t gMaxHit = 0;
# #endif

include("../Geometry/phase1PixelTopology.jl")
using .
include("../CUDACore/HistoContainer.jl")
using .

include("../CUDACore/cuda_assert.jl")
using .__CUDA_ARCH__
include("gpu_clustering_constants.jl")
using .RecoLocalTrackerSiPixelClusterizePluginsGPUClusteringConstants

module RecoLocalTrackerSiPixelClusterizerPluginsGpuClustering

module gpuClustering

module GPU_DEBUG

"""
* @brief Counts modules and assigns starting indices for each module in the data.
*
* This function iterates through an array of pixel IDs (`id`) and identifies 
* module boundaries. It utilizes an atomic operation to update an output array 
* (`moduleStart`) that stores the starting index for each module within the `id` array.
*
* @param id A constant array of type `UInt16` containing pixel IDs.
* @param moduleStart An output array of type `UInt32` where the starting index of each module will be stored.
* @param clusterId An output array of type `UInt32` where each element is initially set to its own index (potentially used for cluster identification later).
* @param numElements The number of elements (pixels) in the `id` array.
* InvId refers to Invalid pixel 
*
"""
function countModules(id::UInt16, moduleStart::UInt32, clusterId::UInt32, numElements::Int)
    first = 0
    for i in first:numElements
        clusterId[i] = i
        if id[i] == InvId 
            continue
        end
        j = i - 1
        while j >= 0 && id[j] == InvId 
            j -= 1
        end
        if j < 0 || id[j] != id[i]
            loc = atomicInc(moduleStart, MaxNumModules)
            moduleStart[loc + 1] = i
        end
    end
end

"""
* @brief Finds and labels clusters of pixels within a module based on their coordinates and IDs.
*
* This function identifies clusters of pixels within a module by iterating through
* pixel IDs (`id`), and coordinates (`x`, `y`). It uses atomic operations for concurrency
* management to update `clusterId`, which stores the cluster ID for each pixel.
*
* @param id Array of UInt16, representing pixel IDs.
* @param x Array of UInt16, representing pixel x-coordinates.
* @param y Array of UInt16, representing pixel y-coordinates.
* @param moduleStart Array of UInt32, specifying start indices for modules and pixel boundaries.
* @param nClustersInModule UInt32, output array to store the number of clusters found per module.
* @param moduleId UInt32, output array to store module IDs.
* @param clusterId UInt32, array to store cluster IDs for each pixel.
* @param numElements Int, the number of elements (pixels) in the `id` array.
*
* @remarks InvId refers to an invalid pixel ID.
"""
function findClus(id:: UInt16, x::UInt16, y::UInt16, moduleStart::UInt32, nClustersInModule:: UInt32, moduleId::UInt32, clusterId::UInt32, numElements::Int)
    
    # julia is 1 indexed
    firstModule = 1
    endModule = moduleStart[1]
    for mod in firstModule:endModule
        firstPixel = moduleStart[1+ mod]
        thisModuleId = id[firstPixel]
        @assert thisModuleId < MaxNumModules

    first = firstPixel
    msize = numElements

    for i in first:numElements
        if id[i] == InvId 
            continue
        end
        if id[i] != thisModuleId
            atomicMin(msize, i)
            break
        end
    end

    # init hist  (ymax=416 < 512 : 9bits)
    maxPixInModule = 4000
    nbins = phase1PixelTopology::numColsInModule + 2;

    const Hist{T, N, M, K, U} = cms.cu.HistoContainer{T, N, M, K, U}
    hist = Hist{UInt16, nbins, maxPixInModule, 9, UInt16}()

    for j in 1:Hist::totbins()
        hist.off[j] = 0
    end
   
    @assert msize == numElements || (msize < numElements && id[msize] != thisModuleId)

    if msize - firstPixel > maxPixInModule
        using Printf
        @Printf ("too many pixels in module %d: %d > %d\n", thisModuleId, msize - firstPixel, maxPixInModule)
        msize = maxPixInModule + firstPixel
    end

    @assert msize - firstPixel <= maxPixInModule

    # fill histo
    for i in first:msize
        if(id[i] == InvId)
            continue
        end
        hist.count(y[i])
    end
    
    hist.finalize()

    for i in first:msize
        if(id[i] == InvId)
            continue 
        end
        hist.fill(y[i], i - firstPixel)
    end

    maxiter = hist.size()
    # allocate space for duplicate pixels: a pixel can appear more than once with different charge in the same event
    maxNeighbours = 10
    @assert (hist.size() / 1) <= maxiter
    # nearest neighbour 
    nn[maxiter][maxNeighbours]
    nnn[maxiter]
    for k in 0:maxiter
        nnn[k] = 0
    end

    # for hit filling!

    # fill NN
    for (j, k) in zip(1:hist.size()-1, 1:hist.size()-1)
       @assert k < maxiter
       p = hist.begin() + j 
       i = p +firstPixel
       @assert id[i] != InvId
       @assert id[i] == thisModuleId
       be = Hist::bin(y[i] + 1)
       e = hist.end(be)
       p += 1
       @assert 0 == nnn[k]
       while p<e 
            p += 1
            m = p + firstPixel
            @assert m != i
            @assert y[m] - y[i] >= 0
            @assert y[m] - y[i] <= 1
            if( abs(x[m] - x[i]) > 1)
                continue
            end
            l = nnn[k] +=1
            @assert l < maxNeighbours
            nn[k][l] = p
       end

    end
    # for each pixel, look at all the pixels until the end of the module;
    # when two valid pixels within +/- 1 in x or y are found, set their id to the minimum;
    # after the loop, all the pixel in each cluster should have the id equeal to the lowest
    # pixel in the cluster ( clus[i] == i ).

    more = true
    nloops = 0
    while more
        if 1 == nloops % 2
            for (j, k) in zip(1:hist.size()-1, 1:hist.size()-1)
                p = hist.begin() + j
                i = p + firstPixel
                m = clusterId[i]
                while m != clusterId[m]
                    m = clusterId[m]
                end
                clusterId[i] = m
            end
        else
            more = false
            for (j, k) in zip(1:hist.size()-1, 1:hist.size()-1)
                p = hist.begin() + j 
                i = p + firstPixel
                for kk in 1:nnn[k]
                    l = nn[k][kk]
                    m = l + firstPixel
                    @assert m != i
                    old = atomicMin(clusterId[m], clusterId[i])
                    if old != clisterId[i]
                        more = true
                    end
                    atomicMin(clusterId[i], old)
                end
            end

        end
        nloops += 1
    end

    foundClusters = 0
    for i in first:msize
        if id[i] == InvId
            continue
        end
        if clusterId[i] == i
            old = atomicInc(foundClusters, 0xffffffff) #The 0xffffffff is a bitmask that ensures the operation wraps around when it reaches the maximum value of UInt32.
            clusterId[i] = -(old + 1)
        end
    end

    for i in first:msize
        if id[i] == InvId 
            continue
        end
        if clusterId[i] >= 0
            clusterId[i] = clusterId[clusterId[i]]
        end
    end

    for i in first:msize
        if id[i] == InvId 
            clusterId[i] == -9999
            continue
        end
        clusterId[i] = - clusterId[i] -2
    end

    nClustersInModule[thisModuleId] = foundClusters
    moduleId[mod] = thisModuleId
end
end

end

end

end
