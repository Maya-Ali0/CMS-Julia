module CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h

export TrackingRecHit2DHeterogeneous, hist_view, ParamsOnGPU, hits_layer_start, phi_binner, iphi, Hist
export n_hits

# Import necessary types and functions from other modules
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView, ParamsOnGPU
using ..histogram: HisToContainer
using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology: AverageGeometry
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using ..Adapt
using ..CUDA
"""
    Struct representing the heterogeneous data for 2D tracking hits.

    ## Fields
    - `n16::UInt32`: Number of 16-bit data elements per hit.
    - `n32::UInt32`: Number of 32-bit data elements per hit.
    - `m_store16::Union{Nothing, Vector{Vector{UInt16}}}`: Optional storage for 16-bit data, initialized as Nothing or a vector of vectors.
    - `m_store32::Union{Nothing, Vector{Vector{Float64}}}`: Optional storage for 32-bit data, initialized as Nothing or a vector of vectors.
    - `m_HistStore::Union{Nothing, Vector{HisToContainer}}`: Optional storage for histogram data, initialized as Nothing or a vector of histogram containers.
    - `m_AverageGeometryStore::Union{Nothing, Vector{AverageGeometry}}`: Optional storage for average geometry data, initialized as Nothing or a vector of AverageGeometry.
    - `m_view::Union{Nothing, Vector{TrackingRecHit2DSOAView}}`: Optional storage for 2D structure of arrays view, initialized as Nothing or a vector of TrackingRecHit2DSOAView.
    - `m_nHits::UInt32`: Number of hits.
    - `m_hitsModuleStart::Vector{UInt32}`: Start indices for hits in modules.
    - `m_hist::Union{Nothing, HisToContainer}`: Optional histogram container for hits, initialized as Nothing or a HisToContainer.
    - `m_hitsLayerStart::Union{Nothing, Vector{UInt32}}`: Optional start indices for hits in layers, initialized as Nothing or a vector of UInt32.
    - `m_iphi::Union{Nothing, Vector{UInt16}}`: Optional vector of indices in phi, initialized as Nothing or a vector of UInt16.
"""

    Hist = HisToContainer{Int16, 128, MAX_NUM_CLUSTERS, 8 * sizeof(UInt16), UInt16, 10, Vector{UInt32}, Vector{UInt16}}
    


mutable struct TrackingRecHit2DHeterogeneous{U <: AbstractVector{UInt16},V <: AbstractVector{Float32}, w <:AbstractVector{UInt32}}
    n16::UInt32
    n32::UInt32
    m_store16::U # UInt16 unique_ptr<uint16_t[]>
    m_store32::V # Float32 unique_ptr<float[]>

    m_xl::UInt32
    m_yl::UInt32
    m_xerr::UInt32
    m_yerr::UInt32

    m_xg::UInt32
    m_yg::UInt32
    m_zg::UInt32
    m_rg::UInt32

    m_charge::UInt32
    m_hitsLayerStart::UInt32

    m_iphi::UInt32
    m_detInd::UInt32
    m_xsize::UInt32
    m_ysize::UInt32

    m_HistStore::HisToContainer{Int16, 128, MAX_NUM_CLUSTERS, 8 * sizeof(UInt16), UInt16, 10, w, U}
    m_AverageGeometryStore::AverageGeometry

    m_nHits::UInt32
    m_hitsModuleStart::CuArray{UInt32}


    m_cpe_params::ParamsOnGPU

    

end

Adapt.@adapt_structure TrackingRecHit2DHeterogeneous





"""
Constructor for TrackingRecHit2DHeterogeneous.

## Arguments
- `nHits::Integer`: Number of hits.
- `cpe_params::ParamsOnGPU`: Parameters for charge propagation estimation (CPE).
- `hitsModuleStart::Vector{Integer}`: Start indices of modules for hits.
- `Hist::HisToContainer`: Histogram container for hits.

## Fields Initialized
- `n16`: Set to 4.
- `n32`: Set to 9.
- `m_store16`: Initialized as a vector of vectors of UInt16.
- `m_store32`: Initialized as a vector of vectors of Float64.
- `m_HistStore`: Set to `Hist`.
- `m_AverageGeometryStore`: Initialized with a vector containing one `AverageGeometry` object.
- `m_view`: Initialized with one `TrackingRecHit2DSOAView` object.
"""
function TrackingRecHit2DHeterogeneous(nHits::UInt32, cpe_params::ParamsOnGPU, hitsModuleStart::CuArray{UInt32})
    n16 = 4
    n32 = 9

    # if nHits == 0 # to fix later
    #     return new(n16, n32, Vector{Vector{Int16}}()
    #     , Vector{Vector{Float64}}(), HisToContainer{0,0,0,0,UInt32}(), AverageGeometry(), TrackingRecHit2DSOAView(), nHits, hitsModuleStart, Hist(), Vector{UInt32}(), Vector{Int16}()) #added dummy values for HisToContainer
    # end

    # Initialize storage 
    
    m_store16 = Vector{UInt16}(undef,n16*nHits)
    m_store32 = Vector{Float32}(undef,n32*nHits + 11)


    # Initialize AverageGeometry and Histogram store
    m_AverageGeometryStore = AverageGeometry()
    m_HistStore = Hist()

    # Define local functions to access storage
    function get16(i)
        return  1 + (i+1)*nHits
    end
    function get32(i) 
        return 1 + (i+1)*nHits
    end

    m_xl::UInt32 = get32(0)
    m_yl::UInt32 = get32(1)
    m_xerr::UInt32 = get32(2)
    m_yerr::UInt32 = get32(3)

    m_xg::UInt32 = get32(4)
    m_yg::UInt32 = get32(5)
    m_zg::UInt32 = get32(6)
    m_rg::UInt32 = get32(7)

    m_charge::UInt32 = get32(8)
    m_hitsLayerStart::UInt32 = get32(9)

    m_iphi::UInt32 = get16(0)
    m_detInd::UInt32 = get16(1)
    m_xsize::UInt32 = get16(2)
    m_ysize::UInt32 = get16(3)

    # Return a new instance of TrackingRecHit2DHeterogeneous
    return TrackingRecHit2DHeterogeneous{typeof(m_store16),typeof(m_store32),Vector{UInt32}}(n16, n32, m_store16, m_store32, m_xl, m_yl, m_xerr, m_yerr, m_xg, m_yg, m_zg, m_rg, m_charge, m_hitsLayerStart, m_iphi, m_detInd, m_xsize, m_ysize, m_HistStore, m_AverageGeometryStore, nHits, hitsModuleStart, cpe_params)
end





















"""
    Accessor function for retrieving the view from TrackingRecHit2DHeterogeneous.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_view`: The stored view of type `Vector{TrackingRecHit2DSOAView}`.
"""
hist_view(hit::TrackingRecHit2DHeterogeneous) = hit.m_view

"""
    Accessor function for retrieving the number of hits.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_nHits`: The number of hits as `UInt32`.
"""
n_hits(hit::TrackingRecHit2DHeterogeneous) = hit.m_nHits

"""
    Accessor function for retrieving the start indices of hits in modules.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_hitsModuleStart`: The vector of start indices for hits in modules.
"""
hits_module_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsModuleStart

"""
    Accessor function for retrieving the start indices of hits in layers.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_hitsLayerStart`: The vector of start indices for hits in layers.
"""
hits_layer_start(hit::TrackingRecHit2DHeterogeneous) = hit.m_hitsLayerStart

"""
    Accessor function for retrieving the histogram container.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_hist`: The histogram container (`HisToContainer`).
"""
phi_binner(hit::TrackingRecHit2DHeterogeneous) = hit.m_hist

"""
    Accessor function for retrieving the phi indices.

    ## Arguments
    - `hit::TrackingRecHit2DHeterogeneous`: The tracking hit object.

    ## Returns
    - `hit.m_iphi`: The vector of phi indices.
"""
iphi(hit::TrackingRecHit2DHeterogeneous) = hit.m_iphi

function test_tracking_rec_hit()
    hitsModuleStart = Integer[1, 2, 3] 
    cpe_params = ParamsOnGPU()
    Hist = HisToContainer{Int16, 128, MAX_NUM_CLUSTERS, 8 * sizeof(UInt16), UInt16, 10}()
    hits = TrackingRecHit2DHeterogeneous(3, cpe_params, hitsModuleStart, Hist)
    
    println("Number of hits: ", n_hits(hits))
    println("Hits module start: ", hits_module_start(hits))
    
    if !isempty(view(hits))
        println("First view element: ", view(hits)[1])
    end
end
# test_tracking_rec_hit()

end
