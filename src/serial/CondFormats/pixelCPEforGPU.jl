module PixelCPEForGPU


const Frame = SOAFrame{Float32}
const Rotation = SOARotation{Float32}

struct CommonParams
    theThicknessB::Float32
    theThicknessE::Float32
    thePitchX::Float32
    thePitchY::Float32
end

struct DetParams
    isBarrel::Bool
    isPosZ::Bool
    layer::UInt16
    index::UInt16
    rawId::UInt32

    shiftX::Float32
    shiftY::Float32
    chargeWidthX::Float32
    chargeWidthY::Float32

    x0::Float32
    y0::Float32
    z0::Float32

    sx::NTuple{3, Float32}
    sy::NTuple{3, Float32}

    frame::Frame
end

# const AverageGeometry = Phase1PixelTopology.AverageGeometry

struct LayerGeometry
    layerStart::NTuple{Phase1PixelTopology.numberOfLayers + 1, UInt32}
    layer::NTuple{phase1PixelTopology.layerIndexSize, UInt8}
end

struct ParamsOnGPU
    m_commonParams::CommonParams
    m_detParams::vector{DetParams}
    m_layerGeometry::LayerGeometry
    m_averageGeometry::AverageGeometry

    function ParamsOnGPU(
        commonParams::CommonParams,
        detParams::DetParams,
        layerGeometry::LayerGeometry,
        averageGeometry::AverageGeometry
    )
        new(commonParams, detParams, layerGeometry, averageGeometry)
    end
end

function commonParams(params::ParamsOnGPU)
    return params.m_commonParams
end

function detParams(params::ParamsOnGPU, i::Int)
    return params.m_detParams[i]
end

function layerGeometry(params::ParamsOnGPU)
    return params.m_layerGeometry
end

function averageGeometry(params::ParamsOnGPU)
    return params.m_averageGeometry
end

function layer(params::ParamsOnGPU, id::UInt16)
    return params.m_layerGeometry.layer[id ÷ Phase1PixelTopology.maxModuleStride]
end

# const MaxHitsInIter = GPUClustering.maxHitsInIter()

struct ClusParamsT{N}
    minRow::NTuple{N, UInt32}
    maxRow::NTuple{N, UInt32}
    minCol::NTuple{N, UInt32}
    maxCol::NTuple{N, UInt32}

    Q_f_X::NTuple{N, Int32}
    Q_l_X::NTuple{N, Int32}
    Q_f_Y::NTuple{N, Int32}
    Q_l_Y::NTuple{N, Int32}

    charge::NTuple{N, Int32}

    xpos::NTuple{N, Float32}
    ypos::NTuple{N, Float32}

    xerr::NTuple{N, Float32}
    yerr::NTuple{N, Float32}

    xsize::NTuple{N, Int16}
    ysize::NTuple{N, Int16}
end

# const ClusParams = ClusParamsT{MaxHitsInIter}()

