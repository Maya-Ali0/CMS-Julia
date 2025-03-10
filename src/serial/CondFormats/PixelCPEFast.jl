using .PixelGPU_h
using .Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology


struct PixelCPEFast{v <: AbstractVector{DetParams}}
    m_detParamsGPU::v
    m_commonParamsGPU::CommonParams
    m_layerGeometry::LayerGeometry
    m_averageGeometry::AverageGeometry
    cpuData_::ParamsOnGPU
end

Adapt.@adapt_structure PixelCPEFast


# Define the getCPUProduct method
function getCPUProduct(pixelCPE::PixelCPEFast)::ParamsOnGPU
    return pixelCPE.cpuData_
end

