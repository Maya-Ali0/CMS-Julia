module RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPUWrapper_h

using ..CondFormats.SiPixelFedCablingMapGPU
import .RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPU_h: SiPixelFedCablingMapGPU

mutable struct SiPixelFedCablingMapGPUWrapper
    _cablingMapHost::SiPixelFedCablingMapGPU
    _modToUnpDefault::Vector{UInt8}
    _hasQuality::Bool

    function SiPixelFedCablingMapGPUWrapper(cablingMap::SiPixelFedCablingMapGPU, modToUnp::Vector{UInt8})
        new(cablingMap, modToUnp, false)
    end
end

function hasQuality(wrapper::SiPixelFedCablingMapGPUWrapper)::Bool
    return wrapper.hasQuality
end

function getCPUProduct(wrapper::SiPixelFedCablingMapGPUWrapper)::SiPixelFedCablingMapGPU
    return wrapper.cablingMapHost
end

function getModToUnpAll(wrapper::SiPixelFedCablingMapGPUWrapper)::Vector{UInt8}
    return wrapper.modToUnpDefault
end

end # module RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPUWrapper_h
