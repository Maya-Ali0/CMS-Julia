module prefix_scan
using CUDA
    """
        blockPrefixScan(ci::Vector{T}, co::Vector{T}, size::UInt32) where T

    Performs an inclusive prefix scan (cumulative sum) on the input vector `ci` and stores the result in the output vector `co`.

    # Arguments
    - `ci::Vector{T}`: Input vector of type `T`.
    - `co::Vector{T}`: Output vector of type `T`.
    - `size::UInt32`: Number of elements to scan.
    """
    function block_prefix_scan(ci, co, size)
        co[1] = ci[1]
        for i in 2:size
            co[i] = ci[i] + co[i - 1]
        end
    end

    function warp_prefix_scan(c::AbstractVector{T},i::Integer,mask::UInt32) where T
        lane_id = mod1(i,32)
        off_set = 1 
        val = c[i]
        while off_set < 32
            val2 = CUDA.shfl_up_sync(mask,val,off_set)
            if lane_id >= off_set + 1
                val += val2
            end
            off_set <<= 1
        end
        c[i] = val
    end

    """
        blockPrefixScan(c::Vector{T}, size::UInt32) where T

    Performs an in-place inclusive prefix scan (cumulative sum) on the input array `c`.

    # Arguments
    - `c::Vector{T}`: Input/output array of type `T`.
    - `size::UInt32`: Number of elements to scan.
    """
    function block_prefix_scan(c::AbstractVector{T},size::Integer,ws::AbstractVector{U}) where {T,U}

        @assert size <= 1024
        @assert blockDim().x % 32 == 0
        first = threadIdx().x
        mask = CUDA.vote_ballot_sync(0xffffffff,first <= size)

        for i ∈ first:blockDim().x:size
            warp_prefix_scan(c,i,mask)
            lane_id = mod1(i,32)
            warp_id = (i +31) / 32
            if lane_id == 32
                ws[warp_id] = c[i]
            end
            mask = CUDA.vote_ballot_sync(mask,i+blockDim().x <= size)
        end
        sync_threads()
        if size <= 32
            return
        end
        if threadIdx().x <= 32
            warp_prefix_scan(ws,threadIdx().x,mask)
        end
        sync_threads()

        for i ∈ first+32:blockDim().x:size
            warp_id = (i +31) / 32
            c[i] += ws[warp_id-1]
        end
        # for i in 2:size
        #     c[i] = c[i] + c[i - 1]
        # end
    end

    """
        multiBlockPrefixScan(ici::Vector{T}, ico::Vector{T}, size::UInt32, pc::Vector{UInt32}) where T

    Performs a multi-block prefix scan on the input array `ici` and stores the result in the output array `ico`.

    # Arguments
    - `ici::Vector{T}`: Input array of type `T`.
    - `ico::Vector{T}`: Output array of type `T`.
    - `size::UInt32`: Number of elements to scan.
    - `pc::Vector{UInt32}`: Array used for atomic operations to coordinate between multiple blocks.
    """
    # function multi_block_prefix_scan(ici::Vector{T}, ico::Vector{T}, size::UInt32, pc::Vector{UInt32}) where T
    #     ci = ici
    #     co = ico
    #     ws = Vector{T}(undef, 32)  # Workspace vector
    #     @assert size >= 1  # Ensure size is greater than or equal to 1
    #     off = 0
    #     if size - off > 0
    #         blockPrefixScan(ci[off+1:end], co[off+1:end], min(32, size - off))
    #     end
    #     is_last_block_done = AtomicAdd(pc, 1) == 0  # Atomic addition to coordinate blocks

    #     if !is_last_block_done
    #         return
    #     end
    #     @assert 1 == pc[1]

    #     psum = Vector{T}(undef, size)  # Partial sum vector
    #     for i in 1:size
    #         psum[i] = (i <= size) ? co[i] : T(0)
    #     end
    #     blockPrefixScan(psum, psum, size)

    #     for i in 1:size
    #         co[i] += psum[1]
    #     end
    # end


end  # module prefix_scan
