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
# TODO: check memory alignment efficiency and neccessity as well as the need for a constructor
struct SiPixelFedCablingMapGPU
    fed::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    link::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    roc::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    RawId::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    rocInDet::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    moduleId::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt32}
    badRocs::NTuple{Pixel_GPU_Details.MAX_SIZE, UInt8}
    size::UInt32

    function SiPixelFedCablingMapGPU()
        fed = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        link = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        roc = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        RawId = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        rocInDet = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        moduleId = ntuple(i -> UInt32(0), Pixel_GPU_Details.MAX_SIZE)
        badRocs = ntuple(i -> UInt8(0), Pixel_GPU_Details.MAX_SIZE)
        size = UInt32(0)
        new(fed, link, roc, RawId, rocInDet, moduleId, badRocs, size)
    end
end

end # module RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPU_h
