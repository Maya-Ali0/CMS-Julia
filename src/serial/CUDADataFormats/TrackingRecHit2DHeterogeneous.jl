module CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
using ..CUDADataFormatsCommonHeterogeneousSoA_H

struct TrackingRecHit2DHeterogeneous{Traits} 
    n16::UInt32
    n32::UInt32

    m_store16::Vector{UInt16}
    m_store32::Vector{Float64}
    m_HistStore::Vector{TrackingRecHit2DSOAView::Hist}
    m_AverageGeometryStore::Vector{TrackingRecHit2DSOAView::AverageGeometry}
    m_view::Vector{TrackingRecHit2DSOAView}
    m_nHits::UInt32
    m_hitsModuleStart::UInt32
    m_hist::Hist
    m_hitsLayerStart::UInt32
    m_iphi::UInt16

end

end