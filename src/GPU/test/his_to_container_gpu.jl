include("../CUDACore/prefix_scan.jl")
include("../CUDACore/hist_to_container.jl")
using Printf
using Random, Distributions
using .histogram: n_bits , HisToContainer, n_bins , tot_bins, capacity, bin, hist_off, zero, size, count!, finalize!, fill!, begin_h, val, end_h, for_each_in_bins
using CUDA
function go(::Type{T}, ::Val{N_BINS}, ::Val{S}, ::Val{DELTA},copy,put) where {T, N_BINS, S, DELTA}
    # eng = MersenneTwister()  # mt19937 MersenneTwister Random Number Generator
    

    rmin::T = typemin(T)
    rmax::T = typemax(T)


    if N_BINS != 128
        rmin = 0
        rmax = 2 * N_BINS - 1
    end


    N = 2000
    v = @cuStaticSharedMem(T,N)
    Hist = HisToContainer{T, N_BINS, N, S, UInt32, 1,CuDeviceVector{UInt32,AS.Shared},CuDeviceVector{UInt32,AS.Shared}}


    if threadIdx().x == 1
        @cuprintln("HistoContainer ", n_bits(Hist), ' ', n_bins(Hist), ' ', tot_bins(Hist), ' ', capacity(Hist), ' ', (rmax - rmin) ÷ n_bins(Hist))
        @cuprintln("bins ", bin(Hist, T(0)), ' ', bin(Hist, T(rmin)), ' ', bin(Hist, T(rmax)))
    end

    h = @cuStaticSharedMem(Hist,1)
    if threadIdx().x == 1
        h[1] = Hist()
    end
    sync_threads()
    h = h[1]

    
    for it in 0:20

        for i in threadIdx().x:blockDim().x:N
            v[i] = copy[i]
        end
        sync_threads()
        for i ∈ threadIdx().x:blockDim().x:N_BINS+1
            h.off[i] = 0 
        end
        
        if threadIdx().x == 1
            @cuassert size(h) == 0
        end
        sync_threads()
        for j in threadIdx().x:blockDim().x:N 
            count!(h, v[j])
        end
        sync_threads()
        if threadIdx().x == 1
            @cuassert size(h) == 0
        end
        ws = @cuStaticSharedMem(UInt32,32)
        finalize!(h,ws)
        sync_threads()
        if threadIdx().x == 1
            @cuassert size(h) == N
        end

        for j in threadIdx().x:blockDim().x:N 
            fill!(h, v[j], UInt32(j))
        end
        sync_threads()

        if threadIdx().x == 1
            @cuassert h.off[1] == 0
            @cuassert size(h) == N
        end

        verify = (i, j, k, t1, t2) -> begin
            @cuassert t1 <= N
            @cuassert t2 <= N
            if i != j && T(v[t1] - v[t2]) <= 0
                @cuprintf("for %i : %i failed %i %i\n", i, v[k], v[t1], v[t2])
            end
        end
        sync_threads()
        for i in threadIdx().x:blockDim().x:n_bins(Hist)
            if i != 1
                @assert h.off[i] >= h.off[i-1]
            end
        end
        sync_threads()
        for i in threadIdx().x:blockDim().x:N
            put[i] = v[i]
        end
        # for i in threadIdx().x:blockDim().x:n_bins(Hist)
        #     if size(h, i) == 0
        #         continue
        #     end
        #     k = val(h,begin_h(h,i)) # get the index of the first element in bins to belong to bin i going over bins array from left to right  
        #     @assert(k <= N)
        #     # Consider taking v[k] - DELTA and v[k] + DELTA and find the appropriate bins for those values. We must assert that kl <= i <= kh
        #     kl = bin(h,T(max(rmin,v[k] - DELTA)))
        #     kh = bin(h,T(min(rmax,v[k] + DELTA)))
        #     for j in begin_h(h, kl):end_h(h, kl) - 1
        #         verify(i, kl, k, k, val(h, j))
        #     end
        #     for j in begin_h(h, kh):end_h(h, kh) - 1
        #         verify(i, kh, k, val(h, j), k)
        #     end
        # end
    end
    # for j in 1:N
    #     b0 = bin(h, v[j])
    #     w = 0
    #     tot = 0

    #     ftest = (k) -> begin
    #         @assert k >= 1 && k <= N
    #         tot += 1
    #     end
    #     for_each_in_bins(h,v[j],w,ftest)
    #     rtot = end_h(h,b0) - begin_h(h,b0)
    #     @assert(tot == rtot)
    #     w = 1
    #     tot = 0 
    #     for_each_in_bins(h,v[j],w,ftest)
    #     bp::Int = b0 + 1
    #     bm::Int = b0 - 1
    #     if bp <= Int(n_bins(h))
    #         rtot += end_h(h,bp) - begin_h(h,bp)
    #     end
    #     if bm >= 1
    #         rtot += end_h(h, bm) - begin_h(h, bm)
    #     end
    #     @assert(tot == rtot)
    #     w = 2 
    #     tot = 0 
    #     for_each_in_bins(h,v[j],w,ftest)
    #     bp = b0 + 2
    #     bm = b0 - 2
    #     if bp <= Int(n_bins(h))
    #         rtot += end_h(h,bp) - begin_h(h,bp)
    #     end
    #     if bm >= 1
    #         rtot += end_h(h, bm) - begin_h(h, bm)
    #     end
    #     @assert tot == rtot
    # end
    
end

go(::Type{T}) where {T} = go(T, Val{128}(), Val{8 * sizeof(T)}(), Val{1000}())

function testing()
    put = cu(Vector{Int16}(undef,2000))
    copy = cu([i for i in 1:2000])
    @cuda blocks = 1 threads = 256 go(Int16, Val{128}(), Val{8 * sizeof(Int16)}(), Val{1000}(),copy,put)
    put = Array(put)
    copy = Array(copy)
    copy == put
    # go(UInt8, Val{128}(), Val{8}(), Val{4}())
    # go(UInt16, Val{313 ÷ 2}(), Val{9}(), Val{4}())
end

testing()
