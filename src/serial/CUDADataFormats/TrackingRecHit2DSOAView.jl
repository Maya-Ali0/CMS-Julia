module CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h

using ..histogram: HisToContainer
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants: MaxNumClusters
using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology

struct ParamsOnGPU
end

struct TrackingRecHit2DSOAView
    m_xl::Vector{Float64}
    m_yl::Vector{Float64}
    m_xerr::Vector{Float64}
    m_yerr::Vector{Float64}
    m_xg::Vector{Float64}
    m_yg::Vector{Float64}
    m_zg::Vector{Float64}
    m_rg::Vector{Float64}
    m_iphi::Vector{UInt16}
    m_charge::Vector{UInt32}
    m_xsize::Vector{UInt16}
    m_ysize::Vector{UInt16}
    m_detInd::Vector{UInt16}
    m_averageGeometry::AverageGeometry
    m_cpeParams::ParamsOnGPU
    m_hitsModuleStart::UInt
    m_hitsLayerStart::UInt
    m_hist::HisToContainer
    m_nHits::UInt32
end

# Constructor for TrackingRecHit2DSOAView
function TrackingRecHit2DSOAView(
        m_xl::Vector{Float64},
        m_yl::Vector{Float64},
        m_xerr::Vector{Float64},
        m_yerr::Vector{Float64},
        m_xg::Vector{Float64},
        m_yg::Vector{Float64},
        m_zg::Vector{Float64},
        m_rg::Vector{Float64},
        m_iphi::Vector{UInt16},
        m_charge::Vector{UInt32},
        m_xsize::Vector{UInt16},
        m_ysize::Vector{UInt16},
        m_detInd::Vector{UInt16},
        m_averageGeometry::AverageGeometry,
        m_cpeParams::ParamsOnGPU,
        m_hitsModuleStart::UInt32,
        m_hitsLayerStart::UInt32,
        m_hist::HisToContainer,
        m_nHits::UInt32
    )
    
    return TrackingRecHit2DSOAView(
        m_xl,
        m_yl,
        m_xerr,
        m_yerr,
        m_xg,
        m_yg,
        m_zg,
        m_rg,
        m_iphi,
        m_charge,
        m_xsize,
        m_ysize,
        m_detInd,
        m_averageGeometry,
        m_cpeParams,
        m_hitsModuleStart,
        m_hitsLayerStart,
        m_hist,
        m_nHits
    )
end

function maxHits()
    return MaxNumClusters
end

@inline function nHits(self::TrackingRecHit2DSOAView)::UInt32
    return self.m_nHits
end

@inline function xLocal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_xl[i]
end

@inline function ylocal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_yl[i]
end

@inline function xerrLocal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_xerr[i]
end

@inline function yerrLocal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_yerr[i]
end

@inline function xGlobal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_xg[i]
end

@inline function yGlobal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_yg[i]
end

@inline function zGlobal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_zg[i]
end

@inline function rGlobal(self::TrackingRecHit2DSOAView, i)::Float64
    return self.m_rg[i]
end

@inline function iphi(self::TrackingRecHit2DSOAView, i)::UInt16
    return self.m_iphi[i]
end

@inline function charge(self::TrackingRecHit2DSOAView, i)::UInt32
    return self.m_charge[i]
end

@inline function clusterSizeX(self::TrackingRecHit2DSOAView, i)::UInt16
    return self.m_xsize[i]
end

@inline function clusterSizeY(self::TrackingRecHit2DSOAView, i)::UInt16
    return self.m_ysize[i]
end

@inline function detectorIndex(self::TrackingRecHit2DSOAView, i)::UInt16
    return self.m_detInd[i]
end

@inline function cpeParams(self::TrackingRecHit2DSOAView)::ParamsOnGPU
    return self.m_cpeParams
end

@inline function hitsModuleStart(self::TrackingRecHit2DSOAView)::UInt32
    return self.m_hitsModuleStart
end

@inline function hitsLayerStart(self::TrackingRecHit2DSOAView)::UInt32
    return self.m_hitsLayerStart
end

@inline function phiBinner(self::TrackingRecHit2DSOAView)::HisToContainer
    return self.m_hist
end

@inline function averageGeometry(self::TrackingRecHit2DSOAView)::AverageGeometry
    return self.m_averageGeometry
end

end
# test case
# using .CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h:TrackingRecHit2DSOAView,ParamsOnGPU,maxHits,nHits,xLocal,ylocal,xerrLocal,yerrLocal,xGlobal,yGlobal,zGlobal,rGlobal,iphi,charge,clusterSizeX,clusterSizeY,detectorIndex,cpeParams,hitsModuleStart,hitsLayerStart,phiBinner,averageGeometry
# using .Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology:AverageGeometry
# using .histogram:HisToContainer
# using .CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants:MaxNumClusters

# avg_geom = AverageGeometry()
# params_gpu = ParamsOnGPU()
# Hist = HisToContainer{UInt16, 128, MaxNumClusters, 8 * sizeof(UInt16), UInt16, 10}()

# number_Hits = 100
# tracking_view = TrackingRecHit2DSOAView(
#     rand(Float64, number_Hits),  # m_xl
#     rand(Float64, number_Hits),  # m_yl
#     rand(Float64, number_Hits),  # m_xerr
#     rand(Float64, number_Hits),  # m_yerr
#     rand(Float64, number_Hits),  # m_xg
#     rand(Float64, number_Hits),  # m_yg
#     rand(Float64, number_Hits),  # m_zg
#     rand(Float64, number_Hits),  # m_rg
#     rand(UInt16, number_Hits),   # m_iphi
#     rand(UInt32, number_Hits),   # m_charge
#     rand(UInt16, number_Hits),   # m_xsize
#     rand(UInt16, number_Hits),   # m_ysize
#     rand(UInt16, number_Hits),   # m_detInd
#     avg_geom,              # m_averageGeometry
#     params_gpu,            # m_cpeParams
#     0,                     # m_hitsModuleStart
#     0,                     # m_hitsLayerStart
#     Hist,                  # m_hist
#     UInt32(number_Hits)          # m_nHits
# )

# println("Max Hits: ", maxHits())
# println("Number of Hits: ", nHits(tracking_view))

# for i in 1:number_Hits
#     println("Hit $i: ")
#     println("  xLocal: ", xLocal(tracking_view, i))
#     println("  yLocal: ", ylocal(tracking_view, i))
#     println("  xerrLocal: ", xerrLocal(tracking_view, i))
#     println("  yerrLocal: ", yerrLocal(tracking_view, i))
#     println("  xGlobal: ", xGlobal(tracking_view, i))
#     println("  yGlobal: ", yGlobal(tracking_view, i))
#     println("  zGlobal: ", zGlobal(tracking_view, i))
#     println("  rGlobal: ", rGlobal(tracking_view, i))
#     println("  iphi: ", iphi(tracking_view, i))
#     println("  charge: ", charge(tracking_view, i))
#     println("  clusterSizeX: ", clusterSizeX(tracking_view, i))
#     println("  clusterSizeY: ", clusterSizeY(tracking_view, i))
#     println("  detectorIndex: ", detectorIndex(tracking_view, i))
# end

# println("CPE Params: ", cpeParams(tracking_view))
# println("Hits Module Start: ", hitsModuleStart(tracking_view))
# println("Hits Layer Start: ", hitsLayerStart(tracking_view))
# println("Phi Binner: ", phiBinner(tracking_view))
# println("Average Geometry: ", averageGeometry(tracking_view))
