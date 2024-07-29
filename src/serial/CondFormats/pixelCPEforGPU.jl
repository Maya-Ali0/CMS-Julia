module PixelGPU_h

using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology: AverageGeometry, local_x, local_y, is_big_pix_y, is_big_pix_x
using ..SOA_h
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants.pixelGPUConstants

export CommonParams, DetParams, LayerGeometry, ParamsOnGPU, ClusParamsT, averageGeometry, MaxHitsInIter, commonParams, detParams, position_corr

# Struct for common detector parameters including thickness, pitch, and default values.
struct CommonParams
    theThicknessB::Float32
    theThicknessE::Float32
    thePitchX::Float32
    thePitchY::Float32

    function CommonParams()
        new(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    end

    function CommonParams(a::Float32, b::Float32, c::Float32, d::Float32)
        new(a, b, c, d)
    end
end

# Struct for detector-specific parameters, including error values and positional offsets.
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

    frame::SOAFrame{Float32}

    function DetParams()
        new(
            false,          # isBarrel
            false,          # isPosZ
            0x0000,         # layer
            0x0000,         # index
            0x00000000,     # rawId
            0.0f0,          # shiftX
            0.0f0,          # shiftY
            0.0f0,          # chargeWidthX
            0.0f0,          # chargeWidthY
            0.0f0,          # x0
            0.0f0,          # y0
            0.0f0,          # z0
            (0.0f0, 0.0f0, 0.0f0),  # sx
            (0.0f0, 0.0f0, 0.0f0),  # sy
            SOAFrame{Float32}()  # frame
        )
    end

    function DetParams(isBarrel::Bool, isPosZ::Bool, layer::UInt16, index::UInt16, rawId::UInt32,
                       shiftX::Float32, shiftY::Float32, chargeWidthX::Float32, chargeWidthY::Float32,
                       x0::Float32, y0::Float32, z0::Float32,
                       sx::NTuple{3, Float32}, sy::NTuple{3, Float32}, frame::SOAFrame{Float32})
        new(isBarrel, isPosZ, layer, index, rawId, shiftX, shiftY, chargeWidthX, chargeWidthY, x0, y0, z0, sx, sy, frame)
    end
end

# Struct for layer geometry including start indices and layer numbers.
struct LayerGeometry
    layerStart::Vector{UInt32}
    layer::Vector{UInt8}

    function LayerGeometry()
        new(Vector{UInt32}(), Vector{UInt8}())
    end

    function LayerGeometry(a::Vector{UInt32}, b::Vector{UInt8})
        new(a, b)
    end
end

# Struct for storing parameters needed on GPU, including common parameters, detector parameters, 
# layer geometry, and average geometry.
struct ParamsOnGPU
    m_commonParams::CommonParams
    m_detParams::Vector{DetParams}
    m_layerGeometry::LayerGeometry
    m_averageGeometry::AverageGeometry

    function ParamsOnGPU()
        temp_vec = [DetParams()]
        new(CommonParams(), temp_vec, LayerGeometry(), AverageGeometry())
    end

    function ParamsOnGPU(commonParams::CommonParams, detParams::Vector{DetParams}, 
                         layerGeometry::LayerGeometry, averageGeometry::AverageGeometry)
        new(commonParams, detParams, layerGeometry, averageGeometry)
    end
end

function commonParams(params::ParamsOnGPU)
    return params.m_commonParams
end

function detParams(params::ParamsOnGPU, i::UInt32)
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

const MaxHitsInIter = MAX_HITS_IN_ITER()

# Template struct for cluster parameters with a fixed size N.

struct ClusParamsT{N}
    minRow::Vector{UInt32}
    maxRow::Vector{UInt32}
    minCol::Vector{UInt32}
    maxCol::Vector{UInt32}

    Q_f_X::Vector{Int32}
    Q_l_X::Vector{Int32}
    Q_f_Y::Vector{Int32}
    Q_l_Y::Vector{Int32}

    charge::Vector{Int32}

    xpos::Vector{Float32}
    ypos::Vector{Float32}

    xerr::Vector{Float32}
    yerr::Vector{Float32}

    xsize::Vector{Int16}
    ysize::Vector{Int16}

    function ClusParamsT{N}() where N
        return new(
            zeros(UInt32, N), zeros(UInt32, N), zeros(UInt32, N), zeros(UInt32, N),
            zeros(Int32, N), zeros(Int32, N), zeros(Int32, N), zeros(Int32, N),
            zeros(Int32, N),
            zeros(Float32, N), zeros(Float32, N),
            zeros(Float32, N), zeros(Float32, N),
            zeros(Int16, N), zeros(Int16, N)
        )
    end
    

end
# Computes the angles of a position relative to the detector.
function computeAnglesFromDet(detParams::DetParams, x::Float32, y::Float32)
    gvx = x - detParams.x0
    gvy = y - detParams.y0
    gvz = -1.0f0 / detParams.z0

    cotalpha = gvx * gvz
    cotbeta = gvy * gvz
    return cotalpha, cotbeta
end

# Calculates the correction factor based on cluster size, charge values, and detector parameters.
function correction(sizeM1::Int32, Q_f::Int32, Q_l::Int32, upper_edge_first_pix::UInt16, lower_edge_last_pix::UInt16,
                    lorentz_shift::Float32, theThickness::Float32, cot_angle::Float32, pitch::Float32,
                    first_is_big::Bool, last_is_big::Bool)::Float32
    if sizeM1 == 0
        return 0.0f0
    end

    W_eff = 0.0f0
    simple = true
    if sizeM1 == 1
        W_inner = pitch * Float32(lower_edge_last_pix - upper_edge_first_pix)
        W_pred = theThickness * cot_angle - lorentz_shift
        W_eff = abs(W_pred) - W_inner
        simple = (W_eff < 0.0f0) || (W_eff > pitch)
    end

    if simple
        sum_of_edge = 2.0f0
        sum_of_edge += first_is_big ? 1.0f0 : 0.0f0
        sum_of_edge += last_is_big ? 1.0f0 : 0.0f0
        W_eff = pitch * 0.5f0 * sum_of_edge
    end

    Qdiff = Float32(Q_l - Q_f)
    Qsum = Float32(Q_l + Q_f)
    Qsum = Qsum == 0.0f0 ? 1.0f0 : Qsum

    return 0.5f0 * (Qdiff / Qsum) * W_eff
end

# Computes the position of a cluster in the detector and applies corrections.
function position_corr(comParams::CommonParams, detParams::DetParams, cp::ClusParamsT{MAX_HITS_IN_ITER}, 
                       x::Vector{Float32}, y::Vector{Float32}, layer::UInt8)
    for i in 1:MAX_HITS_IN_ITER
        if x[i] == 0.0f0 && y[i] == 0.0f0
            continue
        end

        cotalpha, cotbeta = computeAnglesFromDet(detParams, x[i], y[i])
        
        xsize = cp.xsize[i]
        ysize = cp.ysize[i]

        xcorr = correction(xsize - 1, cp.Q_f_X[i], cp.Q_l_X[i], 
                           cp.minRow[i], cp.maxRow[i], 
                           comParams.lorentzShiftX, comParams.theThicknessB, 
                           cotalpha, comParams.thePitchX,
                           detParams.is_big_pix_x[cp.minRow[i]], detParams.is_big_pix_x[cp.maxRow[i]])

        ycorr = correction(ysize - 1, cp.Q_f_Y[i], cp.Q_l_Y[i],
                           cp.minCol[i], cp.maxCol[i],
                           comParams.lorentzShiftY, comParams.theThicknessB,
                           cotbeta, comParams.thePitchY,
                           detParams.is_big_pix_y[cp.minCol[i]], detParams.is_big_pix_y[cp.maxCol[i]])

        x[i] += xcorr
        y[i] += ycorr
    end
end

end # module PixelGPU_h
