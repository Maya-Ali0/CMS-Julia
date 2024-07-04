include("../CUDACore/hist_to_container.jl")
using Printf
using Random, Distributions
using .histogram: n_bits , HisToContainer, n_bins , tot_bins, capacity, bin, hist_off, zero, size, count, finalize, fill, begin_h, val, end_h, for_each_in_bins

function go(::Type{T}, ::Val{NBINS}, ::Val{S}, ::Val{DELTA}) where {T, NBINS, S, DELTA}
    eng = MersenneTwister()  # mt19937 MersenneTwister Random Number Generator

    rmin::T = typemin(T)
    rmax::T = typemax(T)
    if NBINS != 128
        rmin = 0
        rmax = 2 * NBINS - 1
    end

    N = 12000
    v = Vector{T}(undef, N)

    Hist = HisToContainer{T, NBINS, N, S, UInt32, 1}
    Hist4 = HisToContainer{T, NBINS, N, S, UInt16, 4}
    println("HistoContainer ", n_bits(Hist), ' ', n_bins(Hist), ' ', tot_bins(Hist), ' ', capacity(Hist), ' ', (rmax - rmin) ÷ n_bins(Hist))
    println("bins ", bin(Hist, T(0)), ' ', bin(Hist, T(rmin)), ' ', bin(Hist, T(rmax)))
    println("HistoContainer4 ", n_bits(Hist4), ' ', n_bins(Hist4), ' ', tot_bins(Hist4), ' ', capacity(Hist4), ' ', (rmax - rmin) ÷ n_bins(Hist))
    for nh in 0:3
        println("bins ", Int(bin(Hist4, T(0))) + hist_off(Hist4, nh), " ", Int(bin(Hist, T(rmin))) + hist_off(Hist4, nh), " ", Int(bin(Hist, T(rmax))) + hist_off(Hist4, nh))
    end

    h = Hist()
    h4 = Hist4()
    for it in 0:4
        for j in 1:N
            v[j] = rand(eng, rmin:rmax)
        end
        if it == 2
            for j in (N ÷ 2 + 1):(N ÷ 2 + N ÷ 4)
                v[j] = 4
            end
        end
        zero(h)
        zero(h4)
        @assert size(h) == 0
        @assert size(h4) == 0

        for j in 1:N
            count(h, v[j])
            if j <= 2000
                count(h4, v[j], 2)
            else
                count(h4, v[j], j % 4)
            end
        end
        @assert size(h) == 0
        @assert size(h4) == 0

        finalize(h)
        finalize(h4)
        @assert size(h) == N
        @assert size(h4) == N

        for j in 1:N
            fill(h, v[j], UInt32(j))
            if j <= 2000
                fill(h4, v[j], UInt16(j), 2)
            else
                fill(h4, v[j], UInt16(j % 4), j % 4)
            end
        end
        @assert h.off[1] == 0
        @assert h4.off[1] == 0
        @assert size(h) == N
        @assert size(h4) == N

        verify = (i, j, k, t1, t2) -> begin
            @assert t1 <= N
            @assert t2 <= N
            if i != j && T(v[t1] - v[t2]) <= 0
                @printf("for %i : %i failed %i %i\n", i, v[k], v[t1], v[t2])
            end
        end

        for i in 1:n_bins(Hist)
            if size(h, i) == 0
                continue
            end
            k = val(h, begin_h(h, i))
            @assert k <= N
            kl = NBINS != 128 ? bin(h, max(rmin, v[k] - DELTA)) : bin(h, v[k] - T(DELTA))
            kh = NBINS != 128 ? bin(h, min(rmax, v[k] + DELTA)) : bin(h, v[k] + T(DELTA))

            if NBINS == 128
                @assert kl != i
                @assert kh != i
            end

            if NBINS != 128
                @assert kl <= i
                @assert kh >= i
            end

            for j in begin_h(h, kl):end_h(h, kl) - 1
                verify(i, kl, k, k, val(h, j))
            end
            for j in begin_h(h, kh):end_h(h, kh) - 1
                verify(i, kh, k, val(h, j), k)
            end
        end
    end

    for j in 1:N
        b0 = bin(h, v[j])
        w = 0
        tot = 0

        ftest = (k) -> begin
            @assert k >= 1 && k <= N
            tot += 1
        end

        for_each_in_bins(h, v[j], w, ftest)
        rtot = end_h(h, b0) - begin_h(h, b0)
        @assert tot == rtot
        w = 1
        tot = 0
        for_each_in_bins(h, v[j], w, ftest)
        bp = min(b0 + 1, n_bins(h))
        bm = max(b0 - 1, 1)
        if bp <= n_bins(h)
            rtot += end_h(h, bp) - begin_h(h, bp)
        end
        if bm >= 1
            rtot += end_h(h, bm) - begin_h(h, bm)
        end
        println(tot, " ", rtot)
        @assert tot == rtot
        w = 2
        tot = 0
        for_each_in_bins(h, v[j], w, ftest)
        bp = min(b0 + 2, n_bins(h))
        bm = max(b0 - 2, 1)
        if bp <= n_bins(h)
            rtot += end_h(h, bp) - begin_h(h, bp)
        end
        if bm >= 1
            rtot += end_h(h, bm) - begin_h(h, bm)
        end
        @assert tot == rtot
    end
end

go(::Type{T}) where {T} = go(T, Val{128}(), Val{8 * sizeof(T)}(), Val{1000}())

function testing()
    go(UInt8, Val{128}(), Val{8}(), Val{4}())
    go(UInt16, Val{313 ÷ 2}(), Val{9}(), Val{4}())
end

testing()
