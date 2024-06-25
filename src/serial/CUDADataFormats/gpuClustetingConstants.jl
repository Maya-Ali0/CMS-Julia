module CUDADataFormatsSiPixelClusterInterfaceGpuClusteringConstants

    module pixelGPUConstants
        module GPUSmallEvents
            global is_enabled = false
            global maxNumberOfHits :: UInt32
            if(!is_enabled)
                maxNumberOfHits = 24 *1024
                is_enabled = true
            else
                maxNumberOfHits = 48 *1024
            end
        end
    end

    using .pixelGPUConstants
    
    module gpuClustering
            global is_enabled = false
            if(!is_enabled)
                function maxHitsInIter()::UInt32
                    return 64
                end
                is_enabled = true
            else
                function maxHitsInIter()::UInt32
                    return 1024
                end
            end
            function maxHitsInModule()::UInt32
                return 160
            end
            
            MaxNumModules::UInt32 = 2000
            MaxNumClustersPerModules::UInt32 = maxHitsInModule()
            MaxHitsInModule::UInt32 = maxHitsInModule()
            MaxNumClusters::UInt32 = pixelGPUConstants::maxNumberOfHits
            InvId::UInt16 = 9999
    end
end