using .PixelGPU_h
using .Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology


struct PixelCPEFast{v <: AbstractVector{DetParams},r <: AbstractVector{UInt32},s <: AbstractVector{UInt8},z <: AbstractVector{Float32}}
    m_detParamsGPU::v
    m_commonParamsGPU::CommonParams
    m_layerGeometry::LayerGeometry{r,s}
    m_averageGeometry::AverageGeometry{z}
    cpuData_::ParamsOnGPU{v,z,r,s}
end

Adapt.@adapt_structure PixelCPEFast


struct PixelCPEFastWrapper
    xx::PixelCPEFast
end


# Define the getCPUProduct method
function getCPUProduct(pixelCPE::PixelCPEFast)::ParamsOnGPU
    return pixelCPE.cpuData_
end

