# Everything you need to run cuda code in plain sequential c++ code

module heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat

# Define type alias for cudaStream_t
const cudaStream_t = Ptr{Cvoid}

# Define constant for cudaStreamDefault
const cudaStreamDefault = C_NULL

module cms

module cudacompat
    function atomicCAS(address::AbstractArray{T1}, compare::T1, val::T2)::T1 where {T1, T2}
        old = address[]
        address = old == compare ? val : old
        return old
    end
    
    function atomicInc(a::AbstractArray{T1}, b::AbstractArray{T2})::T1 where {T1,T2}
        ret = a[]
        if a[] < T1(b)
            a[] = a[] + 1
        end
        return ret
    end

    function atomicAdd(a::AbstractArray{T1}, b::AbstractArray{T2})::T1 where {T1,T2}
        ret = a[]
        a[] = a[] + b
        return ret
    end
    
    function atomicSub(a::AbstractArray{T1}, b::AbstractArray{T2})::T1 where {T1, T2}
        ret = a[]
        a[] = a[] - b
        return ret
    end

    function atomicMin(a::AbstractArray{T1}, b::AbstractArray{T2})::T1 where {T1,T2}
        ret = a[]
        a[] = min(a[], T1(b))
        return a
    end

    function atomicMax(a::AbstractArray{T1}, b::AbstractArray{T2})::T1 where {T1,T2}
        ret = a[]
        a[] = max(a[], T1(b))
        return a
    end
end

end


end