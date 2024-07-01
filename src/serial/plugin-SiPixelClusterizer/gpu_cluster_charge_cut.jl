include("../CUDACore/cuda_assert.jl")
using .gpuConfig
include("../CUDACore/prefixScan.jl")
using .heterogeneousCoreCUDAUtilitiesInterfacePrefixScan
include("gpu_clustering_constants.jl")
using .Main.CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants



module gpuClustering
    using Printf
    function cluster_charge_cut(id, adc, moduleStart, nClustersInModule, moduleId, clusterId, numElements)
        charge = Vector(undef, MaxNumClusterPerModules)
        ok = Vector(undef, MaxNumClusterPerModules)
        newclusId = Vector(undef, MaxNumClusterPerModules)
        firstModule = 0
        endModule = moduleStart[0]

        for mod in firstModule:1:endModule-1
            firstPixel = moduleStart[1 + mod]
            thisModuleId = id[firstPixel]
            @assert thisModuleId < MaxNumModules
            @assert thisModuleId == moduleId[mod]

            nClus = nClustersInModule[thisModuleId]
            if nClus == 0
                continue
            end
            if nClus > MaxNumClusterPerModules
                @printf("Warning too many clusters in module %d in block %d: %d > %d\n",
               thisModuleId,
               0,
               nclus,
               MaxNumClustersPerModules)
            end
            
            first = firstPixel

            if nClus > MaxNumClusterPerModules
                for i in first:numElements-1
                    if id[i] == InvId
                        continue
                    end
                    if id[i] != thisModuleId
                        break
                    end
                    if clusterId[i] >= MaxNumClusterPerModules
                        id[i] = InvId 
                        clusterId[i] = InvId 
                    end
                end
                nClus = MaxNumClusterPerModules
            end

            @assert nClus <= MaxNumClusterPerModules
            for i in 0:nClus-1
                charge[i] = 0
            end

            for i in first:numElements-1
                if id[i] == InvId 
                    continue
                end
                if id[i] != thisModuleId
                    break
                end
                atomicAdd(charge[clusterId[i]], adc[i])
            end

            chargeCut = thisModuleId < 96 ? 2000 : 4000
            for i in 0:nClus -1
                newclusId[i] = ok[i] = charge[i] > chargeCut ? 1 : 0
            end

            cms.cuda.blockPrefixScan(newclusId, nClus)
            @assert nClus >= newclusId[nclus - 1]

            if nClus == newclusId[nClus - 1]
                continue
            end

            nClustersInModule[thisModuleId] =  newclusId[nClus - 1]

            for i in 0:nClus-1
                if ok[i] == 0 
                    newclusId[i] = InvId + 1
                end
            end

            for i in first:numElements-1 
                if id[i] == InvId 
                    continue
                end
                if id[i] != thisModuleId
                    break
                end
                clusterId[i] = newclusId[clusterId[i] - 1]
                if clusterId[i] == InvId 
                    id[i] = InvId 
                end
            end
        end
    end
end