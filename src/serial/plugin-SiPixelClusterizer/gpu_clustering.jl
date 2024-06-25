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
* (`module_start`) that stores the starting index for each module within the `id` array.
*
* @param id A constant array of type `UInt16` containing pixel IDs.
* @param module_start An output array of type `UInt32` where the starting index of each module will be stored.
* @param cluster_id An output array of type `UInt32` where each element is initially set to its own index (potentially used for cluster identification later).
* @param num_elements The number of elements (pixels) in the `id` array.
* InvId refers to Invalid pixel 
*
"""
function count_modules(id::UInt16, module_start::UInt32, cluster_id::UInt32, num_elements::Int)
    first = 0
    for i in first:num_elements
        cluster_id[i] = i
        if id[i] == InvId 
            continue
        end
        j = i - 1
        while j >= 0 && id[j] == InvId 
            j -= 1
        end
        if j < 0 || id[j] != id[i]
            loc = atomicInc(module_start, Max_num_modules)
            module_start[loc + 1] = i
        end
    end
end

"""
* @brief Finds and labels clusters of pixels within a module based on their coordinates and IDs.
*
* This function identifies clusters of pixels within a module by iterating through
* pixel IDs (`id`), and coordinates (`x`, `y`). It uses atomic operations for concurrency
* management to update `cluster_id`, which stores the cluster ID for each pixel.
*
* @param id Array of UInt16, representing pixel IDs.
* @param x Array of UInt16, representing pixel x-coordinates.
* @param y Array of UInt16, representing pixel y-coordinates.
* @param module_start Array of UInt32, specifying start indices for modules and pixel boundaries.
* @param n_clusters_in_module UInt32, output array to store the number of clusters found per module.
* @param moduleId UInt32, output array to store module IDs.
* @param cluster_id UInt32, array to store cluster IDs for each pixel.
* @param num_elements Int, the number of elements (pixels) in the `id` array.
*
* @remarks InvId refers to an invalid pixel ID.
"""
function find_clus(id:: UInt16, x::UInt16, y::UInt16, module_start::UInt32, n_clusters_in_module:: UInt32, moduleId::UInt32, cluster_id::UInt32, num_elements::Int)
    
    # julia is 1 indexed
    first_module = 1
    end_module = module_start[1]
    for mod in first_module:end_module
        first_pixel = module_start[1+ mod]
        this_module_id = id[first_pixel]
        @assert this_module_id < Max_num_modules

    first = first_pixel
    msize = num_elements

    for i in first:num_elements
        if id[i] == InvId 
            continue
        end
        if id[i] != this_module_id
            atomicMin(msize, i)
            break
        end
    end

    # init hist  (ymax=416 < 512 : 9bits)
    max_pix_in_module = 4000
    nbins = phase1PixelTopology::numColsInModule + 2;

    const Hist{T, N, M, K, U} = cms.cu.HistoContainer{T, N, M, K, U}
    hist = Hist{UInt16, nbins, max_pix_in_module, 9, UInt16}()

    for j in 1:Hist::totbins()
        hist.off[j] = 0
    end
   
    @assert msize == num_elements || (msize < num_elements && id[msize] != this_module_id)

    if msize - first_pixel > max_pix_in_module
        using Printf
        @Printf ("too many pixels in module %d: %d > %d\n", this_module_id, msize - first_pixel, max_pix_in_module)
        msize = max_pix_in_module + first_pixel
    end

    @assert msize - first_pixel <= max_pix_in_module

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
        hist.fill(y[i], i - first_pixel)
    end

    max_iter = hist.size()
    # allocate space for duplicate pixels: a pixel can appear more than once with different charge in the same event
    max_neighbours = 10
    @assert (hist.size() / 1) <= max_iter
    # nearest neighbour 
    nn[max_iter][max_neighbours]
    nnn[max_iter]
    for k in 0:max_iter
        nnn[k] = 0
    end

    # for hit filling!

    # fill NN
    for (j, k) in zip(1:hist.size()-1, 1:hist.size()-1)
       @assert k < max_iter
       p = hist.begin() + j 
       i = p +first_pixel
       @assert id[i] != InvId
       @assert id[i] == this_module_id
       be = Hist::bin(y[i] + 1)
       e = hist.end(be)
       p += 1
       @assert 0 == nnn[k]
       while p<e 
            p += 1
            m = p + first_pixel
            @assert m != i
            @assert y[m] - y[i] >= 0
            @assert y[m] - y[i] <= 1
            if( abs(x[m] - x[i]) > 1)
                continue
            end
            l = nnn[k] +=1
            @assert l < max_neighbours
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
                i = p + first_pixel
                m = cluster_id[i]
                while m != cluster_id[m]
                    m = cluster_id[m]
                end
                cluster_id[i] = m
            end
        else
            more = false
            for (j, k) in zip(1:hist.size()-1, 1:hist.size()-1)
                p = hist.begin() + j 
                i = p + first_pixel
                for kk in 1:nnn[k]
                    l = nn[k][kk]
                    m = l + first_pixel
                    @assert m != i
                    old = atomicMin(cluster_id[m], cluster_id[i])
                    if old != cluster_id[i]
                        more = true
                    end
                    atomicMin(cluster_id[i], old)
                end
            end

        end
        nloops += 1
    end

    found_clusters = 0
    for i in first:msize
        if id[i] == InvId
            continue
        end
        if cluster_id[i] == i
            old = atomicInc(found_clusters, 0xffffffff) #The 0xffffffff is a bitmask that ensures the operation wraps around when it reaches the maximum value of UInt32.
            cluster_id[i] = -(old + 1)
        end
    end

    for i in first:msize
        if id[i] == InvId 
            continue
        end
        if cluster_id[i] >= 0
            cluster_id[i] = cluster_id[cluster_id[i]]
        end
    end

    for i in first:msize
        if id[i] == InvId 
            cluster_id[i] == -9999
            continue
        end
        cluster_id[i] = - cluster_id[i] -2
    end

    n_clusters_in_module[this_module_id] = found_clusters
    moduleId[mod] = this_module_id
end
end

end

end

end
