module RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPU_h

export SiPixelFedCablingMapGPU

module Pixel_GPU_Details
    # Maximum fed for phase1 is 150 but not all of them are filled
    # Update the number FED based on maximum fed found in the cabling map
    const MAX_FED::UInt32 = 150
    const MAX_LINK::UInt32 = 48  # maximum links/channels for Phase 1
    const MAX_ROC::UInt32 = 8
    const MAX_SIZE::UInt32 = MAX_FED * MAX_LINK * MAX_ROC
    const MAX_SIZE_BYTE_BOOL::UInt32 = MAX_SIZE * sizeof(UInt8)
end # module Pixel_GPU_Details

# TODO: since this has more information than just cabling map, maybe we should invent a better name?
# TODO: check memory alignment efficiency and necessity as well as the need for a constructor
# TODO: ntuples or vectors?
struct SiPixelFedCablingMapGPU
    fed::Array{UInt32, 1}
    link::Array{UInt32, 1}
    roc::Array{UInt32, 1}
    RawId::Array{UInt32, 1}
    rocInDet::Array{UInt32, 1}
    moduleId::Array{UInt32, 1}
    badRocs::Array{UInt8, 1}
    size::UInt32

    function SiPixelFedCablingMapGPU()
        fed = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        link = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        roc = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        RawId = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        rocInDet = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        moduleId = fill(UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        badRocs = fill(UInt8(0), Pixel_GPU_Details.MAX_SIZE)
        size = UInt32(0)
        new(fed, link, roc, RawId, rocInDet, moduleId, badRocs, size)
    end
end

end # module RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPU_h
