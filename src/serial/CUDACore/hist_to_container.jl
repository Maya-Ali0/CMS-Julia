module cms
    module cuda
        struct AtomicPairCounter
            n::UInt32
            m::UInt32
        end
        function add(self::AtomicPairCounter,val)
            old_val = AtomicPairCounter(self.n,self.m)
            self.m += val
            self.n += 1
            return old_val
        end
        """
         The off array within the struct stores the number of elements in the bins to its left excluding the elements inserted at bin indexed at b
         It represents the next available position where a new element can be inserted, 
         which is why it's decremented with each addition.
        """
        struct HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS} # T is the type of discretized input values, NBINS is the number of bins, size is the maximum number of elements in bins, 
            off::Vector{UInt32} 
            bins::Vector{I} # holds indices to the values placed within a certain bin that are of type I
            psws::Int32 # prefix scan working place 
            function HisToContainer{T,N_BINS,SIZE, S , I, N_HISTS}() where {T,N_BINS,SIZE,S,I,N_HISTS}
                new(Vector{UInt32}(undef,N_BINS*N_HISTS+1),Vector{I}(undef,SIZE),0)
            end
        end

        HisToContainer{T,N_BINS,SIZE,S,I}() where {T,N_BINS,SIZE,S,I} = HisToContainer{T,N_BINS,SIZE, S,I,1}()


        """
            Histogram type that stores only the off, but not the indices of elements added from another array into the histogram
        """
        const CountersOnly{T,N_BINS,I,N_HISTS} = HisToContainer{T,N_BINS,0,I,N_HISTS}


        """
        function to find floor(log2(n)) in loglog(64)
        """
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

        size_t(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = sizeof(T)*8
        n_bins(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS
        n_hists(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} =  N_HISTS
        tot_bins(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_HISTS * N_BINS + 1 # additional "overflow" or "catch-all" bin
        n_bits(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = ilog2(N_BINS - 1) + 1 # in case the number of bins was a power of 2 
        capacity(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = SIZE
        hist_off(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},nh::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS * nh
        
        """
        functions given only the type but not an instance. Analogous to static members within structs in c++"
        """
        size_t(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = sizeof(T)*8
        n_bins(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS
        n_hists(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} =  N_HISTS
        tot_bins(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_HISTS * N_BINS + 1 # additional "overflow" or "catch-all" bin
        n_bits(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = ilog2(N_BINS - 1) + 1 # in case the number of bins was a power of 2 
        capacity(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = SIZE
        hist_off(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}},nh::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS * nh



        """
        Take leftmost bits of size number of bits to represent the bins in the histogram to choose the index of the bin that element t is mapped to
        """
        function bin(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},t::T)::unsigned(T) where {T, N_BINS, SIZE, S, I, N_HISTS}
            bits_to_represent_bins = n_bits(hist)
            shift::UInt32 = size_t(hist) - bits_to_represent_bins
            mask::Uint32 = 1 << bits_to_represent_bins - 1
            return (t >> shift) & mask
        end

        """
        fills the off array with zeros. Called before counting the elements to be inserted into the histogram
        """
        zero(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = fill!(hist.off,0)

        
        function add(hist1::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},hist2::CountersOnly) where {T, N_BINS, SIZE, S, I, N_HISTS}
            for i ∈ 1:tot_bins(hist1)
                hist1.off[i] = hist2.off[i]
            end
        end

        function count_direct(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},b::T) where {T, N_BINS, SIZE, S, I, N_HISTS}
            @assert b <= n_bins(hist)
            hist.off[b]+=1
        end

        function fill_direct(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},b::T,j::I) where {T, N_BINS, SIZE, S, I, N_HISTS}
            @assert b <= n_bins(hist)
            w::UInt32 = off[b]
            off[b] -= 1
            @assert w > 0
            bins[w] = j
        end
        """
        first upper 32 bits of apc represent the bin index while the lower 32 bits represent the number of elements within each bin
        increment lower 32 bits by the number of elements to add to bin c.m. I don't know why set off[c.m] = c.n
        Doesnt resemble how i thought the representation was interms of offsets.
        """
        @inline function bulk_fill(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},apc::AtomicPairCounter,v::Vector{I},n::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS}
            c = add(apc,n)
            if c.m > n_bins(hist)
                return -1*Int32(c.m)
            end
            off[c.m] = c.n 
            for i ∈ 0:n-1
                bins[c.n+i] = v[i+1]
            end
            return c.m
        end

        @inline bulk_finalize(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}, apc::AtomicPairCounter) where {T, N_BINS, SIZE, S, I, N_HISTS} = off[apc.m] = apc.n

        @inline function bulk_finalize_fill(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}, apc::AtomicPairCounter) where {T, N_BINS, SIZE, S, I, N_HISTS}
            m::UInt32 = apc.m
            n::Uint32 = apc.n
            n_bins = n_bins(hist)
            if(m > n_bins) # OverFlow
                off[n_bins+1] = UInt32(off[n_bins])
                return
            end
            for i ∈ m:tot_bins(hist)
                off[i] = n
            end
        end

        @inline function count(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T) where {T, N_BINS, SIZE, S, I, N_HISTS}
            b::UInt32 = bin(hist,t)
            @assert(b <= n_bins(hist))
            off[b] += 1
        end

        @inline function fill(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,j::I) where {T, N_BINS, SIZE, S, I, N_HISTS}
            b::UInt32 = bin(hist,t)
            @assert(b <= n_bins(hist))
            w = off[b]
            off[b] -= 1
            @assert(w > 0)
            bins[w] = j 
        end

        @inline function count(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,nh::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS}
            b::UInt32 = bin(hist,t)
            @assert(b <= n_bins(hist))
            b+= hist_off(hist,nh)
            @assert(b <= tot_bins(hist))
            off[b] += 1
        end

        @inline function fill(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,j::I,nh::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS}
            b::UInt32 = bin(hist,t)
            @assert(b <= n_bins(hist))
            b+= hist_off(hist,nh)
            @assert(b <= tot_bins(hist))
            w = off[b]
            off[b] -= 1
            @assert(w > 0)
            bins[w] = j
        end

        @inline function finalize(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS}
            @assert off[tot_bins(hist)] == 0
            block_prefix_scan(off,tot_bins(hist))
            @assert(off[tot_bins(hist)] == off[tot_bins(hist)-1])
        end
        size(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = UInt32(hist.off[tot_bins(hist)])
        size(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS} = hist.off[b+1] - hist.off[b]
        begin_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = 1 
        end_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = size(hist)
        begin_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS} = off[b]+1 
        end_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b::UInt32) where {T, N_BINS, SIZE, S, I, N_HISTS} = off[b+1]+1
    end

    """
    offsets[nh] contains the size of the data in vector V
    """
    function count_from_vector(h::Histo,nh::UInt32,v::Vector{T},offsets::Vector{UInt32}) where {Histo, T}
        for i ∈ 1:offsets[nh+1]
            off = searchsortedfirst(offsets,i+1)
            @assert(off > 1)
            ih::UInt32 = off - 1 - 1 # number of histograms start indices to the left are off - 1 and another -1 for histogram index
            @assert(ih >= 0 )
            @assert(ih < Int(nh))
            count(h,v[i],ih)
        end
    end

    function fill_from_vector(h::Histo,nh::UInt32,v::Vector{T},offsets::Vector{UInt32}) where {Histo,T}
        for i ∈ 1::offsets[nh+1]
            off = searchsortedfirst(offsets,i+1)
            @assert(off > 1 )
            ih::Uint32 = off - 1 - 1
            @assert(ih >= 0 )
            @assert(ih < Int(nh))
            fill(h,v[i],i,ih)
        end
    end






end