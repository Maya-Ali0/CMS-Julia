module CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants

module pixelGPUConstants
    if isdefined(Main, :GPU_SMALL_EVENTS)
        const MAX_NUMBER_OF_HITS::UInt32 = 24 * 1024
    else
        const MAX_NUMBER_OF_HITS::UInt32 = 48 * 1024 # data at pileup 50 has 18300 +/- 3500 hits; 40000 is around 6 sigma away
    end
end # module pixelGPUConstants

module gpuClustering
    using ..pixelGPUConstants
    if isdefined(Main, :GPU_SMALL_EVENTS)
        const max_hits_in_iter() = 64
    else
        const max_hits_in_iter() = 160 # optimized for real data PU 50
    end
    const max_hits_in_module() = 1024
    const MAX_NUM_MODULES::UInt32 = 2000
    const MAX_NUM_CLUSTERS_PER_MODULES::Int32 = max_hits_in_module()
    const MAX_HITS_IN_MODULE::UInt32 = max_hits_in_module() # as above
    const MAX_NUM_CLUSTERS::UInt32 = pixelGPUConstants.MAX_NUMBER_OF_HITS
    const INV_ID::UInt16 = 9999 # must be > MaxNumModules

end # module gpuClustering

end # module CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
