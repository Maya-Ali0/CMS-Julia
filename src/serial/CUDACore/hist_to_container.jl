module histogram
    include("../CUDACore/prefix_scan.jl")
    using .cms:block_prefix_scan
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
        It represents the next available position where a new element can be inserted in array bins
    """
    struct HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS} # T is the type of discretized input values, NBINS is the number of bins, size is the maximum number of elements in bins, 
        off::Vector{UInt32} # goes from bin 1 to bin N_BINS*N_HISTS + 1 
        bins::Vector{I} # holds indices to the values placed within a certain bin that are of type I. Indices for bins range from 1 to SIZE
        psws::Int32 # prefix scan working place
        function HisToContainer{T,N_BINS,SIZE, S , I, N_HISTS}() where {T,N_BINS,SIZE,S,I,N_HISTS}
            new(Vector{UInt32}(undef,N_BINS*N_HISTS+1),Vector{I}(undef,SIZE),0)
        end
    end

    HisToContainer{T,N_BINS,SIZE,S,I}() where {T,N_BINS,SIZE,S,I} = HisToContainer{T,N_BINS,SIZE, S,I,1}() # outer constructor with N_HISTS set to 1


    """
        Type Alias for a histogram that does not store the inserted indices of the values
    """
    const CountersOnly{T,N_BINS,I,N_HISTS} = HisToContainer{T,N_BINS,0,I,N_HISTS}


    """
    function to find floor(log2(n)) in loglog(32)
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
    n_bits(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = i_log_2(UInt32(N_BINS - 1)) + 1 # in case the number of bins was a power of 2 
    capacity(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = SIZE
    hist_off(::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},nh::Int) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS * nh
    
    """
    functions given only the type but not an instance. Analogous to static members within structs in c++"
    """
    size_t(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = sizeof(T)*8
    n_bins(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS
    n_hists(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} =  N_HISTS
    tot_bins(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_HISTS * N_BINS + 1 # additional "overflow" or "catch-all" bin
    n_bits(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = i_log_2(UInt32(N_BINS - 1)) + 1 # in case the number of bins was a power of 2 
    capacity(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}}) where {T, N_BINS, SIZE, S, I, N_HISTS} = SIZE
    hist_off(::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}},nh::Int) where {T, N_BINS, SIZE, S, I, N_HISTS} = N_BINS * nh



    """
    Take as many bits needed to represent all bins from the Most Significant Bits of the inserted element to find the bin index
    """
    function bin(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},t::T)::unsigned(T) where {T, N_BINS, SIZE, S, I, N_HISTS}
        bits_to_represent_bins = n_bits(hist)
        shift::UInt32 = size_t(hist) - bits_to_represent_bins
        mask::UInt32 = 1 << bits_to_represent_bins - 1
        return ((t >> shift) & mask + 1)
    end

    function bin(hist::Type{HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}},t::T)::unsigned(T) where {T, N_BINS, SIZE, S, I, N_HISTS}
        bits_to_represent_bins = n_bits(hist)
        shift::UInt32 = size_t(hist) - bits_to_represent_bins
        mask::UInt32 = 1 << bits_to_represent_bins - 1
        return ((t >> shift) & mask + 1)
    end

    """
    fills the off array with zeros. Called before counting the elements to be inserted into the histogram
    """
    zero(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = fill!(hist.off,0)

    """
    adds to the histogram of interest hist1 the off array of another hist
    """
    function add(hist1::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},hist2::CountersOnly) where {T, N_BINS, SIZE, S, I, N_HISTS}
        for i ∈ 1:tot_bins(hist1)
            hist1.off[i] += hist2.off[i]
        end
    end
    """
    Increments the off array given a direct index b
    """
    function count_direct(hist::HisToContainer{T, N_BINS, SIZE, S, I, N_HISTS},b::T) where {T, N_BINS, SIZE, S, I, N_HISTS}
        @assert b <= n_bins(hist)
        hist.off[b]+=1
    end
    """
    inserts index j  the value of interest to be inserted to the histogram
    decrements off so that whens all values are filled off becomes an array that determines the number of elements to the left of bin b excluding elements at b
    """
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
        n::UInt32 = apc.n
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
        hist.off[b] += 1
    end

    @inline function fill(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,j::I) where {T, N_BINS, SIZE, S, I, N_HISTS}
        b::UInt32 = bin(hist,t)
        @assert(b <= n_bins(hist))
        w = hist.off[b]
        hist.off[b] -= 1
        @assert(w > 0)
        hist.bins[w] = j 
    end

    @inline function count(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,nh) where {T, N_BINS, SIZE, S, I, N_HISTS}
        b::UInt32 = bin(hist,t)
        @assert(b <= n_bins(hist))
        b+= hist_off(hist,nh)
        @assert(b <= tot_bins(hist))
        hist.off[b] += 1
    end

    @inline function fill(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},t::T,j::I,nh) where {T, N_BINS, SIZE, S, I, N_HISTS}
        b::UInt32 = bin(hist,t)
        @assert(b <= n_bins(hist))
        b+= hist_off(hist,nh)
        @assert(b <= tot_bins(hist))
        w = hist.off[b]
        hist.off[b] -= 1
        @assert(w > 0)
        hist.bins[w] = j
    end

    @inline function finalize(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS}
        @assert hist.off[tot_bins(hist)] == 0
        block_prefix_scan(hist.off,tot_bins(hist))
        @assert(hist.off[tot_bins(hist)] == hist.off[tot_bins(hist)-1])
    end
    size(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = UInt32(hist.off[tot_bins(hist)])
    size(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b) where {T, N_BINS, SIZE, S, I, N_HISTS} = hist.off[b+1] - hist.off[b]
    begin_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = 1 
    end_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS}) where {T, N_BINS, SIZE, S, I, N_HISTS} = size(hist)
    begin_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b::H) where {T, N_BINS, SIZE, S, I, N_HISTS, H <: Integer} = hist.off[b]+1 
    end_h(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b::H) where {T, N_BINS, SIZE, S, I, N_HISTS, H <: Integer} = hist.off[b+1]+1 # returns first index of next bin
    val(hist::HisToContainer{T,N_BINS,SIZE, S,I,N_HISTS},b) where {T, N_BINS, SIZE, S, I, N_HISTS} = hist.bins[b]
    """
    offsets[nh+1] contains the size of the data in vector V
    for nh elements in v, i need nh+1 elements for describing ranges in offsets
    """
    function count_from_vector(h::Histo,nh::UInt32,v::Vector{T},offsets::Vector{UInt32}) where {Histo, T}
        for i ∈ 1:offsets[nh+1]
            h.off = searchsortedfirst(offsets,i+1)
            @assert(off > 1)
            ih::UInt32 = off - 1 - 1 # number of histograms start indices to the left are off - 1 and another -1 for histogram index
            @assert(ih >= 0 )
            @assert(ih < Int(nh))
            count(h,v[i],ih)
        end
    end

    function fill_from_vector(h::Histo,nh::UInt32,v::Vector{T},offsets::Vector{UInt32}) where {Histo,T}
        for i ∈ 1::offsets[nh+1]
            h.off = searchsortedfirst(offsets,i+1)
            @assert(off > 1 )
            ih::UInt32 = off - 1 - 1
            @assert(ih >= 0 )
            @assert(ih < Int(nh))
            fill(h,v[i],i,ih)
        end
    end
    
    @inline function for_each_in_bins(hist::Hist,value::V,n::Int,func::Function) where {Hist,V}
        """
        find the bin number of v call it b and then goes over all values in bins bs till bin be where 
        bs = b - n 
        be = b + n 
        """
        bs::Int = bin(hist,value)
        bs = max(1,bs-n)
        be::Int = min(Int(n_bins(hist)),bs+n)
        @assert(be >= bs)
        # func.(begin_h(hist,bs):end_h(hist,be)-1)
        for pj ∈ begin_h(hist,bs):(end_h(hist,be)-1)
            func(hist.bins[pj])

        end
    end
end