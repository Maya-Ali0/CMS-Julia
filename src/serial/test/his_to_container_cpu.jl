include("../CUDACore/hist_to_container.jl")
using Printf
using Random, Distributions
function go() where {T,N_BINS,S,DELTA}
    eng = MersenneTwister() # mt19937 MersenneTwister Random Number Generator

    # Minimum and Maximum values representable by type T
    rmin::T = typemin(T)
    rmax::T = typemax(T)

    if(N_BINS != 128)
        rmin = 0 
        rmax = 2*N_BINS - 1
    end

    rgen = Uniform(rmin,rmax)

    N = 12000

    v::Vector{T} = Vector{T}(undef,N)

    Hist = HisToContainer{T,N_BINS,N,S}
    Hist4 = HisToContainer{T,N_BINS,N,S,UInt16,4}
    
    println("HistoContainer ", nbits(Hist), ' ', nbins(Hist), ' ', totbins(Hist), ' ', capacity(Hist), ' ', (rmax - rmin) / nbins(Hist))
    println("bins ", bin(Hist, 0), ' ', bin(Hist, rmin), ' ', bin(Hist, rmax))
    println("HistoContainer4 ", nbits(Hist4), ' ', nbins(Hist4), ' ', totbins(Hist4), ' ', capacity(Hist4), ' ', (rmax - rmin) / nbins(Hist))

    for nh ∈ 0:3
        println("bins ", Int(bin(Hist4,0)) + hist_off(Hist4,nh)," ",Int(bin(Hist,rmin)) + hist_off(Hist4,nh)," ",Int(bin(Hist,rmax)) + hist_off(Hist4,nh))
    end

    h::Hist
    h4::Hist4


    for it ∈ 0:4 
        for j ∈ 1:N
            v[j] = rand(eng,rmin:rmax)
        end
        if(it == 2)
            for j ∈ (N/2 + 1): (N/2 + N/4) # default 6001 to 9000 set to 4
                v[j] = 4 
            end
        end
        # initialize the off arrays of h and h4 to zeros
        zero(h)
        zero(h4)
        @assert(size(h) == 0)
        @assert(size(h4) == 0)
        
        # Count values in histograms 
        for j ∈ 1:N
            count(h,v[j])
            if j <= 2000 # first 2000 values count them in third histogram
                count(h4,v[j],2)
            else
                count(h4,v[j],j % 4)
            end
        end
        
        @assert(size(h) == 0)
        @assert(size(h4) == 0)
        
        # Apply prefix sum on off array for both histograms
        finalize(h)
        finalize(h4)

        @assert(size(h) == N)
        @assert(size(h4) == N)
        
        # Fill histograms h and h4 with indices of v
        for j ∈ 1:N
            fill(h,v[j],j)
            if j <= 2000 # First 2000 values filled in third histogram
                fill(h4,v[j],j)
            else
                fill(h,v[j],j % 4)
            end
        end
        #@assert(h.off[0] == 0)
        #@assert(h4.off[0] == 0)
        @assert(size(h) == N)
        @assert(size(h4) == N)
        
        verify = (i::UInt32,j::UInt32,k::UInt32,t1::UInt32,t2::UInt32) -> begin
            @assert t1 <= N
            @assert t2 <= N
            if i != j && T(v[t1] - v[t2]) <= 0 
                @printf("for %i : %i failed %i %i \n",i,v[k],v[t1],v[t2])
            end
        end
        # loop over all bin indices
        for i ∈ 1:n_bins(Hist)
            if(size(h,i) == 0)
                continue 
            end
            k = val(h,begin_h(h,i)) # get the index of the first element in bins to belong to bin i going over bins array from left to right  
            @assert(k <= N)
            # Consider taking v[k] - DELTA and v[k] + DELTA and find the appropriate bins for those values. We must assert that kl <= i <= kh
            kl = N_BINS != 128 ? bin(h,max(rmin,v[k] - DELTA)) : bin(h,v[k] - T(DELTA))
            kh = N_BINS != 128 ? bin(h,min(rmax,v[k] + DELTA)) : bin(h,v[k] + T(DELTA))
            
            if(N_BINS == 128)
                @assert(kl != i)
                @assert(kh != i)
            end
            
            if(N_BINS != 128)
                @assert(kl <= i)
                @assert(kh >= i)
            end
            # i index of main bin , j index of bin to the left , t1 : first element in bin i , t2 : first element in bin j
            for j ∈ begin_h(h,kl):end_h(h,kl)-1
                verify(i,kl,k,k,val(h,j))
            end
            for j ∈ begin_h(h,kh):end_h(h,kh)-1
                verify(i,kh,k,val(h,j),k)
            end
        end
    end

    for j ∈ 1:N

        b0 = bin(h,v[j])
        w = 0 
        tot::Int = 0 

        ftest = (k) -> begin
            @assert(k >= 1 && k <= N)
            tot += 1
        end
        for_each_in_bins(h,v[j],w,ftest)
        rtot = end_h(h,b0) - begin_h(h,b0)
        @assert(tot == rtot)
        w = 1
        tot = 0 
        for_each_in_bins(h,v[j],w,ftest)
        bp::Int = b0 + 1
        bm::Int = b0 - 1
        if bp <= int(n_bins(h))
            rtot += end_h(h,bp) - begin_h(h,bp)
        end
        if bm >= 1
            rtot += end_h(h,bm) - begin_h(h,bm)
        end
        @assert(tot == rtot)
        w = 2 
        tot = 0 
        for_each_in_bins(h,v[j],w,ftest)
        bp+=1
        bm-=1
        if bp <= int(n_bins(h))
            rtot += end_h(h,bp) - begin_h(h,bp)
        end
        if bm >= 1
            rtot += end_h(h,bm) - begin_h(h,bm)
        end
        @assert(tot == rtot)
    end
end
g
function testing()
    go{Int16}()









        


            






end