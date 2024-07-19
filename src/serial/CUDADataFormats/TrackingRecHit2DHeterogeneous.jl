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

    function TrackingRecHit2DHeterogeneous(nHits::Integer, cpe_params::ParamsOnGPU, hitsModuleStart::Vector{UInt32}, Hist::HisToContainer)
        n16 = 4
        n32 = 9
    
        if nHits == 0
            return new(n16, n32, Nothing, Nothing, Nothing, Nothing, Nothing, nHits, hitsModuleStart, Nothing, Nothing, Nothing)
        end
    
        m_store16 = [Vector{UInt16}(undef, 0) for _ in 1:(nHits * n16)]
        m_store32 = [Vector{Float64}(undef, 0) for _ in 1:(nHits * n32 + 11)]
    
    
       
        obj2 = AverageGeometry()
        m_HistStore = Vector{HisToContainer}()
        push!(m_HistStore, Hist)
        m_AverageGeometryStore = Vector{AverageGeometry}()
        push!(m_AverageGeometryStore, obj2)
    
        
        function get16(i)
            println("get16 called")
            return  m_store16[i + 1]
        end
        function get32(i) 
            println("get32 called")
            return m_store32[i + 1] 
        end
    
        hits_layer_start = reinterpret(UInt32, get32(n32))
        m_iphi = reinterpret(UInt16, get16(0))
    
        println("calling the constructor here")
        obj = TrackingRecHit2DSOAView(
            get32(0),
            get32(1),
            get32(2),
            get32(3),
            get32(4),
            get32(5),
            get32(6),
            get32(7),
            m_iphi,
            reinterpret(Int32, get32(8)),
            reinterpret(Int16, get16(2)),
            reinterpret(Int16, get16(3)),
            get16(1),
            obj2,
            cpe_params,
            hitsModuleStart,
            hits_layer_start,
            m_HistStore,
            nHits
        )
        println("finished constructor")
    
        m_view = Vector{TrackingRecHit2DSOAView}()
        push!(m_view, obj)

        println(m_view)
    
        return new(n16, n32, m_store16, m_store32, m_HistStore, m_AverageGeometryStore, m_view, nHits, hitsModuleStart, m_HistStore[1], hits_layer_start, m_iphi)
    end
    
end

view(hit::TrackingRecHit2DHeterogeneous) = hit.m_view

n_hits(hit::TrackingRecHit2DHeterogeneous) = hit.m_nHits

hits_module_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsModuleStart

hits_layer_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsLayerStart

phi_binner(hit::TrackingRecHit2DHeterogeneous) = hit.m_hist

iphi(hit::TrackingRecHit2DHeterogeneous) = hit.m_iphi


function test_tracking_rec_hit()
    hitsModuleStart = UInt32[1, 2, 3]  # Ensure hitsModuleStart is of type Vector{UInt32}
    cpe_params = ParamsOnGPU()
    Hist = HisToContainer{UInt16, 128, 10, 8 * sizeof(UInt16), UInt16, 10}()
    hits = TrackingRecHit2DHeterogeneous(3, cpe_params, hitsModuleStart, Hist)
    
    println("Number of hits: ", n_hits(hits))
    println("Hits module start: ", hits_module_start(hits))
    
    if !isempty(view(hits))
        println("First view element: ", view(hits)[1])
    end
end
test_tracking_rec_hit()

end
