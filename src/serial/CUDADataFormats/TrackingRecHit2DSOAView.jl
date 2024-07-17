using .histogram:HisToContainer
using .CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants:MaxNumClusters
using .Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology:AverageGeometry
module CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h

module pixelCPEforGPU
    struct ParamsOnGPU end
end

struct TrackingRecHit2DSOAView
    m_xl::float
    n_yl::float
    m_xerr::float
    m_yerr::float
    m_xg::float
    m_yg::float
    m_zg::float
    m_rg::float
    m_iphi::UInt16
    m_charge::UInt32
    m_xsize::UInt16
    m_ysize::UInt16
    m_detInd::UInt16
    m_averageGeometry::AverageGeometry
    m_cpeParams::ParamsOnGPU
    m_hitsModuleStart::UInt32
    m_hitsLayerStart::UInt32
    Hist = HisToContainer{UInt16, 128, MaxNumClusters, 8 * size(UInt16), UInt16, 10}
    m_hist::Hist
    m_nHits::UInt32
    
end

function maxHits()
    return MaxNumClusters
end

@inline function nHits(self::TrackingRecHit2DSOAView):UInt32
    return self.m_nHits
end
@inline function xLocal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_xl[i]
end
@inline function ylocal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_yl[i]
end
@inline function xerrLocal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_xerr[i]
end
@inline function yerrLocal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_yerr[i]
end
@inline function xGlobal(self::TrackingRecHit2DSOAView,i)::float
    return self.x_xg[i]
end
@inline function yGlobal(self::TrackingRecHit2DSOAView,i)::float
    return self.yGlobal[i]
end
@inline function zGlobal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_zg[i]
end
@inline function rGlobal(self::TrackingRecHit2DSOAView,i)::float
    return self.m_rg[i]
end
@inline function iphi(self::TrackingRecHit2DSOAView,i)::UInt32
    return self.m_iphi[i]
end
@inline function charge(self::TrackingRecHit2DSOAView,i)::UInt32
    return self.m_charge[i]
end
@inline function clusterSizeX(self::TrackingRecHit2DSOAView,i)::UInt16
    return self.m_xsize[i]
end
@inline function clusterSizeY(self::TrackingRecHit2DSOAView,i)::UInt16
    return self.m_ysize[i]
end
@inline function detectorIndex(self::TrackingRecHit2DSOAView,i)::UInt16
    return self.m_detInd[i]
end
@inline function cpeParams(self::TrackingRecHit2DSOAView)::ParamsOnGPU
    return self.m_cpeParams
end
@inline function hitsModuleStart(self::TrackingRecHit2DSOAView)::UInt32
    return self.hitsLayerStart
end
@inline function hitsLayerStart(self::TrackingRecHit2DSOAView)::UInt32
    return self.m_hitsLayerStart
end
@inline function phiBinner(self::TrackingRecHit2DSOAView)::Hist
    return self.m_hist
end
@inline function averageGeometry(self::TrackingRecHit2DSOAView)::AverageGeometry
    return self.m_averageGeometry
end

end


