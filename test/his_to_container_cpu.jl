include("../CUDACore/hist_to_container.jl")
using Random, Distributions
function go() where {T,N_BINS,S,DELTA}
    eng = MersenneTwister() # mt19937
    rmin::T = typemin(T)
    rmax::T = typemax(T)

    if(N_BINS != 128)
        rmin = 0 
        rmax = 2*N_BINS - 1
    end
    rgen = Uniform(rmin,rmax)

    N = 12000

    v::Vector{T} = Vector{T}(undef,N)

    Hist = HisToContainer{T,N_BINS,N,S}()
    Hist4 = HisToContainer{T,N_BINS,N,S,UInt16,4}
    
    println("HistoContainer ", nbits(Hist), ' ', nbins(Hist), ' ', totbins(Hist), ' ', capacity(Hist), ' ', (rmax - rmin) / nbins(Hist))
    println("bins ", bin(Hist, 0), ' ', bin(Hist, rmin), ' ', bin(Hist, rmax))
    println("HistoContainer4 ", nbits(Hist4), ' ', nbins(Hist4), ' ', totbins(Hist4), ' ', capacity(Hist4), ' ', (rmax - rmin) / nbins(Hist))

    for nh ∈ 0:3
        println("bins ", Int(bin(Hist4,0)) + hist_off(Hist4,nh)," ",Int(bin(Hist,rmin)) + hist_off(Hist4,nh)," ",Int(bin(Hist,rmax)) + hist_off(Hist4,nh))
    end

    h::Hist
    h4::Hist4




end