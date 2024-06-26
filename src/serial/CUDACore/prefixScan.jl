module heterogeneousCoreCUDAUtilitiesInterfacePrefixScan

module cms

module cuda

"""
    blockPrefixScan(ci::AbstractVector{T}, co::AbstractVector{T}, size::UInt32) where T

Performs an inclusive prefix scan (cumulative sum) on the input vector `ci` and stores the result in the output vector `co`.

# Arguments
- `ci::AbstractVector{T}`: Input vector of type `T`.
- `co::AbstractVector{T}`: Output vector of type `T`.
- `size::UInt32`: Number of elements to scan.
"""
function blockPrefixScan(ci::AbstractVector{T}, co::AbstractVector{T}, size::UInt32) where T
    co[1] = ci[1]
    for i in 2:size
        co[i] = ci[i] + co[i - 1]
    end
end

"""
    blockPrefixScan(c::AbstractArray{T}, size::UInt32) where T

Performs an in-place inclusive prefix scan (cumulative sum) on the input array `c`.

# Arguments
- `c::AbstractArray{T}`: Input/output array of type `T`.
- `size::UInt32`: Number of elements to scan.
"""
function blockPrefixScan(c::AbstractArray{T}, size::UInt32) where T
    for i in 2:size
        c[i] = c[i] + c[i - 1]
    end
end

"""
    multiBlockPrefixScan(ici::AbstractArray{T}, ico::AbstractArray{T}, size::UInt32, pc::AbstractArray{UInt32}) where T

Performs a multi-block prefix scan on the input array `ici` and stores the result in the output array `ico`.

# Arguments
- `ici::AbstractArray{T}`: Input array of type `T`.
- `ico::AbstractArray{T}`: Output array of type `T`.
- `size::UInt32`: Number of elements to scan.
- `pc::AbstractArray{UInt32}`: Array used for atomic operations to coordinate between multiple blocks.
"""
function multiBlockPrefixScan(ici::AbstractArray{T}, ico::AbstractArray{T}, size::UInt32, pc::AbstractArray{UInt32}) where T
    ci = ici
    co = ico
    ws = Vector{T}(undef, 32)  # Workspace vector
    @assert size >= 1  # Ensure size is greater than or equal to 1
    off = 0
    if size - off > 0
        blockPrefixScan(ci[off+1:end], co[off+1:end], min(32, size - off))
    end
    is_last_block_done = AtomicAdd(pc, 1) == 0  # Atomic addition to coordinate blocks

    if !is_last_block_done
        return
    end
    @assert 1 == pc[1]

    psum = Vector{T}(undef, size)  # Partial sum vector
    for i in 1:size
        psum[i] = (i <= size) ? co[i] : T(0)
    end
    blockPrefixScan(psum, psum, size)

    for i in 1:size
        co[i] += psum[1]
    end
end

end  # module cuda

end  # module cms

end  # module heterogeneousCoreCUDAUtilitiesInterfacePrefixScan
