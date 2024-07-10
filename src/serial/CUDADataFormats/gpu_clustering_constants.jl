module CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants

module pixelGPUConstants
    if isdefined(Main, :GPU_SMALL_EVENTS)
        const MAX_NUMBER_OF_HITS::UInt32 = 24 * 1024
    else
        const MAX_NUMBER_OF_HITS::UInt32 = 48 * 1024 # data at pileup 50 has 18300 +/- 3500 hits; 40000 is around 6 sigma away
    end
end # module pixelGPUConstants

end # module CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
