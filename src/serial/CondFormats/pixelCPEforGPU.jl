# using .Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology
include("../DataFormats/SOARotation.jl")
using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology: AverageGeometry

struct CommonParams
    theThicknessB::Float32
    theThicknessE::Float32
    thePitchX::Float32
    thePitchY::Float32
    function CommonParams()
        new(0,0,0,0)
    end

    function CommonParams(a, b, c, d)
        new(a, b, c, d)
    end
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
end

# const AverageGeometry = Phase1PixelTopology.AverageGeometry

struct LayerGeometry
    layerStart::Vector{UInt32}
    layer::Vector{UInt8}

    function LayerGeometry(a, b)
        new(a, b)
    end
    function LayerGeometry()
        new(
            Vector{UInt32}(),  # Empty vector for layerStart
            Vector{UInt8}()    # Empty vector for layer
        )
    end
end

struct ParamsOnGPU
    m_commonParams::CommonParams
    m_detParams::Vector{DetParams}
    m_layerGeometry::LayerGeometry
    m_averageGeometry::AverageGeometry

    function ParamsOnGPU(
        commonParams::CommonParams,
        detParams::Vector{DetParams},
        layerGeometry::LayerGeometry,
        averageGeometry::AverageGeometry
    )
        new(commonParams, detParams, layerGeometry, averageGeometry)
    end
    function ParamsOnGPU()
        temp_vec = [DetParams()]
        new(CommonParams(),temp_vec,LayerGeometry(),AverageGeometry())
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


function computeAnglesFromDet(detParams::DetParams, x::Float32, y::Float32)
    gvx = x - detParams.x0
    gvy = y - detParams.y0
    gvz = -1.0f0 / detParams.z0

    cotalpha = gvx * gvz
    cotbeta = gvy * gvz
    return cotalpha, cotbeta
end

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

function position(comParams::CommonParams, detParams::DetParams, cp::ClusParamsT{N}, ic::UInt32) where {N}
    llx = cp.minRow[ic] + 1
    lly = cp.minCol[ic] + 1
    urx = cp.maxRow[ic]
    ury = cp.maxCol[ic]

    llxl = localX(llx)
    llyl = localY(lly)
    urxl = localX(urx)
    uryl = localY(ury)

    mx = llxl + urxl
    my = llyl + uryl

    xsize = Int32(urxl) + 2 - Int32(llxl)
    ysize = Int32(uryl) + 2 - Int32(llyl)
    @assert xsize >= 0
    @assert ysize >= 0

    if isBigPixX(cp.minRow[ic])
        xsize += 1
    end
    if isBigPixX(cp.maxRow[ic])
        xsize += 1
    end
    if isBigPixY(cp.minCol[ic])
        ysize += 1
    end
    if isBigPixY(cp.maxCol[ic])
        ysize += 1
    end

    unbalanceX = 8 * abs(Float32(cp.Q_f_X[ic] - cp.Q_l_X[ic])) / Float32(cp.Q_f_X[ic] + cp.Q_l_X[ic])
    unbalanceY = 8 * abs(Float32(cp.Q_f_Y[ic] - cp.Q_l_Y[ic])) / Float32(cp.Q_f_Y[ic] + cp.Q_l_Y[ic])
    xsize = 8 * xsize - unbalanceX
    ysize = 8 * ysize - unbalanceY

    cp.xsize[ic] = min(xsize, 1023)
    cp.ysize[ic] = min(ysize, 1023)

    if cp.minRow[ic] == 0 || cp.maxRow[ic] == lastRowInModule
        cp.xsize[ic] = -cp.xsize[ic]
    end
    if cp.minCol[ic] == 0 || cp.maxCol[ic] == lastColInModule
        cp.ysize[ic] = -cp.ysize[ic]
    end

    xPos = detParams.shiftX + comParams.thePitchX * (0.5f0 * Float32(mx) + Float32(xOffset))
    yPos = detParams.shiftY + comParams.thePitchY * (0.5f0 * Float32(my) + Float32(yOffset))

    cotalpha, cotbeta = computeAnglesFromDet(detParams, xPos, yPos)

    thickness = detParams.isBarrel ? comParams.theThicknessB : comParams.theThicknessE

    xcorr = correction(cp.maxRow[ic] - cp.minRow[ic], cp.Q_f_X[ic], cp.Q_l_X[ic], llxl, urxl, detParams.chargeWidthX,
                       thickness, cotalpha, comParams.thePitchX, isBigPixX(cp.minRow[ic]), isBigPixX(cp.maxRow[ic]))

    ycorr = correction(cp.maxCol[ic] - cp.minCol[ic], cp.Q_f_Y[ic], cp.Q_l_Y[ic], llyl, uryl, detParams.chargeWidthY,
                       thickness, cotbeta, comParams.thePitchY, isBigPixY(cp.minCol[ic]), isBigPixY(cp.maxCol[ic]))

    cp.xpos[ic] = xPos + xcorr
    cp.ypos[ic] = yPos + ycorr
end

function errorFromSize(comParams::CommonParams, detParams::DetParams, cp::ClusParamsT{N}, ic::Int) where {N}
    # Edge cluster errors
    cp.xerr[ic] = 0.0050f0
    cp.yerr[ic] = 0.0085f0

    # FIXME these are errors from Run1
    xerr_barrel_l1 = (0.00115f0, 0.00120f0, 0.00088f0)
    xerr_barrel_l1_def = 0.00200f0
    yerr_barrel_l1 = (0.00375f0, 0.00230f0, 0.00250f0, 0.00250f0, 0.00230f0, 0.00230f0, 0.00210f0, 0.00210f0, 0.00240f0)
    yerr_barrel_l1_def = 0.00210f0
    xerr_barrel_ln = (0.00115f0, 0.00120f0, 0.00088f0)
    xerr_barrel_ln_def = 0.00200f0
    yerr_barrel_ln = (0.00375f0, 0.00230f0, 0.00250f0, 0.00250f0, 0.00230f0, 0.00230f0, 0.00210f0, 0.00210f0, 0.00240f0)
    yerr_barrel_ln_def = 0.00210f0
    xerr_endcap = (0.0020f0, 0.0020f0)
    xerr_endcap_def = 0.0020f0
    yerr_endcap = (0.00210f0,)
    yerr_endcap_def = 0.00210f0

    sx = cp.maxRow[ic] - cp.minRow[ic]
    sy = cp.maxCol[ic] - cp.minCol[ic]

    # is edgy ?
    isEdgeX = cp.minRow[ic] == 0 || cp.maxRow[ic] == lastRowInModule
    isEdgeY = cp.minCol[ic] == 0 || cp.maxCol[ic] == lastColInModule
    # is one and big?
    isBig1X = (0 == sx) && isBigPixX(cp.minRow[ic])
    isBig1Y = (0 == sy) && isBigPixY(cp.minCol[ic])

    if !isEdgeX && !isBig1X
        if !detParams.isBarrel
            cp.xerr[ic] = sx < length(xerr_endcap) ? xerr_endcap[sx] : xerr_endcap_def
        elseif detParams.layer == 1
            cp.xerr[ic] = sx < length(xerr_barrel_l1) ? xerr_barrel_l1[sx] : xerr_barrel_l1_def
        else
            cp.xerr[ic] = sx < length(xerr_barrel_ln) ? xerr_barrel_ln[sx] : xerr_barrel_ln_def
        end
    end

    if !isEdgeY && !isBig1Y
        if !detParams.isBarrel
            cp.yerr[ic] = sy < length(yerr_endcap) ? yerr_endcap[sy] : yerr_endcap_def
        elseif detParams.layer == 1
            cp.yerr[ic] = sy < length(yerr_barrel_l1) ? yerr_barrel_l1[sy] : yerr_barrel_l1_def
        else
            cp.yerr[ic] = sy < length(yerr_barrel_ln) ? yerr_barrel_ln[sy] : yerr_barrel_ln_def
        end
    end
end

function errorFromDB(comParams::CommonParams, detParams::DetParams, cp::ClusParamsT{N}, ic::Int) where {N}
    # Edge cluster errors
    cp.xerr[ic] = 0.0050f0
    cp.yerr[ic] = 0.0085f0

    sx = cp.maxRow[ic] - cp.minRow[ic]
    sy = cp.maxCol[ic] - cp.minCol[ic]

    # is edgy ?
    isEdgeX = cp.minRow[ic] == 0 || cp.maxRow[ic] == lastRowInModule
    isEdgeY = cp.minCol[ic] == 0 || cp.maxCol[ic] == lastColInModule
    # is one and big?
    ix = (0 == sx) ? 1 : 0
    iy = (0 == sy) ? 1 : 0
    ix += (0 == sx) && isBigPixX(cp.minRow[ic]) ? 1 : 0
    iy += (0 == sy) && isBigPixY(cp.minCol[ic]) ? 1 : 0

    if !isEdgeX
        cp.xerr[ic] = detParams.sx[ix + 1]
    end
    if !isEdgeY
        cp.yerr[ic] = detParams.sy[iy + 1]
    end
end
