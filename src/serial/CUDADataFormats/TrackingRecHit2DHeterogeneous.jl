module CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView, ParamsOnGPU, HisToContainer, AverageGeometry
# using ..CUDADataFormatsCommonHeterogeneousSoA_H

struct TrackingRecHit2DHeterogeneous
    n16::UInt32
    n32::UInt32
    m_store16::Union{Nothing, Vector{Vector{UInt16}}} 
    m_store32::Union{Nothing, Vector{Vector{Float64}}}
    m_HistStore::Union{Nothing, Vector{HisToContainer}}
    m_AverageGeometryStore::Union{Nothing, Vector{AverageGeometry}}
    m_view::Union{Nothing, Vector{TrackingRecHit2DSOAView}}
    m_nHits::UInt32
    m_hitsModuleStart::Vector{UInt32}
    m_hist::Union{Nothing, HisToContainer}
    m_hitsLayerStart::Union{Nothing, Vector{UInt32}}
    m_iphi::Union{Nothing, Vector{UInt16}}

    function TrackingRecHit2DHeterogeneous(nHits::Integer, cpe_params::ParamsOnGPU, hitsModuleStart::Vector{UInt32})
        n16 = 4
        n32 = 9

        if nHits == 0
            return new(n16, n32, Nothing, Nothing, Nothing, Nothing, Nothing, nHits, hitsModuleStart, Nothing, Nothing, Nothing)
        end

        # Initialize the m_store16 and m_store32 vectors with default values
        m_store16 = [Vector{UInt16}(undef, n16) for _ in 1:(nHits * n16)]
        m_store32 = [Vector{Float64}(undef, n32) for _ in 1:(nHits * n32 + 11)]

        m_HistStore = Vector{HisToContainer}(undef, 1)
        m_AverageGeometryStore = Vector{AverageGeometry}(undef, 1)

        get16(i) = m_store16[(i + 1) * nHits]
        get32(i) = m_store32[(i + 1) * nHits]

        m_view = Vector{TrackingRecHit2DSOAView}(undef, 1)

        hits_layer_start = reinterpret(UInt32, get32(n32)) # vector will be doubled since each Float64 will be reinterpreted as 2 UInt32
        m_iphi = reinterpret(Int16, get16(0))

        m_view[1] = TrackingRecHit2DSOAView(
            get32(0),
            get32(1),
            get32(2),
            get32(3),
            get32(4),
            get32(5),
            get32(6),
            get32(7),
            m_iphi, 
            reinterpret(Int32, get32(8)), # vector will be doubled since each Float64 will be reinterpreted as 2 Int32
            reinterpret(Int16, get16(2)),
            reinterpret(Int16, get16(3)),
            get16(1),
            m_AverageGeometryStore[1],
            cpe_params,
            hitsModuleStart,
            m_hitsLayerStart,
            m_HistStore[1],
            nHits
        )

        return new(n16, n32, m_store16, m_store32, m_HistStore, m_AverageGeometryStore, m_view, nHits, hitsModuleStart, m_HistStore[1], hits_layer_start, m_iphi)
    end
end

view(hit::TrackingRecHit2DHeterogeneous) = hit.m_view

n_hits(hit::TrackingRecHit2DHeterogeneous) = hit.m_nHits

hits_module_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsModuleStart

hits_layer_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsLayerStart

phi_binner(hit::TrackingRecHit2DHeterogeneous) = hit.m_hist

iphi(hit::TrackingRecHit2DHeterogeneous) = hit.m_iphi

end
