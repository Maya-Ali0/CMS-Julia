module gpuClusterCharge
    include("../CUDACore/cuda_assert.jl")
    using .gpuConfig
    include("../CUDACore/prefix_scan.jl")
    using .prefix_scan
    include("../CUDADataFormats/gpu_clustering_constants.jl")
    using .CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants.pixelGPUConstants:INV_ID, MAX_NUM_CLUSTERS_PER_MODULES, MAX_NUM_MODULES
    include("../CUDACore/cudaCompat.jl")
    using .heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat.cms


    using Printf
    function cluster_charge_cut(id, adc, moduleStart, nClustersInModule, moduleId, clusterId, numElements)
        charge = Vector(undef, MAX_NUM_CLUSTERS_PER_MODULES)
        ok = Vector(undef, MAX_NUM_CLUSTERS_PER_MODULES)
        newclusId = Vector(undef, MAX_NUM_CLUSTERS_PER_MODULES)
        firstModule = 0
        endModule = moduleStart[1]

        for mod in firstModule + 1:endModule
            firstPixel = moduleStart[1 + mod]
            thisModuleId = id[firstPixel]
            @assert thisModuleId < MAX_NUM_MODULES
            @assert thisModuleId == moduleId[mod]

            nClus = nClustersInModule[thisModuleId]
            if nClus == 0
                continue
            end
            if nClus > MAX_NUM_CLUSTERS_PER_MODULES
                @printf("Warning too many clusters in module %d in block %d: %d > %d\n",
               thisModuleId,
               0,
               nclus,
               MaxNumClustersPerModules)
            end
            
            first = firstPixel

            if nClus > MAX_NUM_CLUSTERS_PER_MODULES
                for i in first:numElements
                    if id[i] == InvId
                        continue
                    end
                    if id[i] != thisModuleId
                        break
                    end
                    if clusterId[i] >= MAX_NUM_CLUSTERS_PER_MODULES
                        id[i] = InvId 
                        clusterId[i] = InvId 
                    end
                end
                nClus = MAX_NUM_CLUSTERS_PER_MODULES
            end

            if isdefined(Main, :GPU_DEBUG)
                if thisModuleId % 100 == 1
                    @printf("start cluster charge cut for module %d in block %d\n", thisModuleId, 0)
                end
            end

            @assert nClus <= MAX_NUM_CLUSTERS_PER_MODULES
            for i in 1:nClus
                charge[i] = 0
            end

            for i in first:numElements
                if id[i] == INV_ID 
                    continue
                end
                if id[i] != thisModuleId
                    break
                end
                cms.cudacompat.atomicAdd(charge[clusterId[i]], adc[i])
            end

            chargeCut = thisModuleId < 96 ? 2000 : 4000
            for i in 1:nClus
                newclusId[i] = ok[i] = charge[i] > chargeCut ? 1 : 0
            end

            prefix_scan.blockPrefixScan(newclusId, nClus)
            @assert nClus >= newclusId[nclus - 1]

            if nClus == newclusId[nClus - 1]
                continue
            end

            nClustersInModule[thisModuleId] =  newclusId[nClus - 1]

            for i in 1:nClus
                if ok[i] == 0 
                    newclusId[i] = InvId + 1
                end
            end

            for i in first:numElements
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