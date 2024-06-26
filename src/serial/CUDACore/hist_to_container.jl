module cms
    module cuda
        struct HistToContainer{T,N_BINS,SIZE,S,I,N_HISTS}
            counter::Vector{UInt32}
            bins::Vector{I}
            psws::Int32 # prefix scan working place
        end
        
        function i_log_2(v::UInt32)::UInt32
            b::Vector{UInt32} = [0x2,0xC,0xF0,0xFF00,0xFFFF0000]
            s::Vector{UInt32} = [ 1,2,4,8,16]
            r::UInt32 = 0 
            
            for i ∈ 5:-1:1
                if (v & b[i]) != 0
                    v >>= s[i]
                    r |= s[i]
                end
            end
            return r
        end

        size_t(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = sizeof(T)*8
        n_bins(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS
        n_hists(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} =  N_HISTS
        tot_bins(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_HISTS * N_BINS + 1 # additional "overflow" or "catch-all" bin
        n_bits(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = ilog2(N_BINS - 1) + 1 # in case the number of bins was a power of 2 
        capacity(::HistToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = SIZE
        



    end

end