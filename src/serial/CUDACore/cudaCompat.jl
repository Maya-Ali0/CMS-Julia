module heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat

module cms

module cudacompat

    """
    Atomic Compare-And-Swap operation for a single element in a vector.
    
    ## Arguments
    - `address::Vector{T1}`: Vector containing the element to modify atomically.
    - `compare::T1`: Value to compare against the current value at `address[1]`.
    - `val::T2`: New value to store at `address[1]` if `compare` matches the current value.
    
    ## Returns
    - `T1`: The old value stored at `address[1]`.
    """
    function atomicCAS(address::Vector{T1}, compare::T1, val::T2)::T1 where {T1, T2}
        old = address[1]  # Retrieve the current value at address[1]
        if old == compare
            address[1] = val  # Perform atomic update if the current value matches compare
        end
        return old  # Return the old value
    end
    
    """
    Atomic Increment operation for a single element in a vector.
    
    ## Arguments
    - `a::Vector{T1}`: Vector containing the element to increment atomically.
    - `b::T2`: Value to increment by, if the current value at `a[1]` is less than `T1(b)`.
    
    ## Returns
    - `T1`: The old value stored at `a[1]`.
    """
    function atomicInc(a::Vector{T1}, b::T2)::T1 where {T1, T2}
        ret = a[1]  # Retrieve the current value at a[1]
        if ret < T1(b)
            a[1] += ret  # Increment a[1] if its current value is less than b
        end
        return ret  # Return the old value
    end

    """
    Atomic Add operation for a single element in a vector.
    
    ## Arguments
    - `a::Vector{T1}`: Vector containing the element to add to atomically.
    - `b::T2`: Value to add to `a[1]`.
    
    ## Returns
    - `T1`: The old value stored at `a[1]`.
    """
    function atomicAdd(a::Vector{T1}, b::T2)::T1 where {T1, T2}
        ret = a[1]  # Retrieve the current value at a[1]
        a[1] += b  # Add b to a[1]
        return ret  # Return the old value
    end
    
    """
    Atomic Subtract operation for a single element in a vector.
    
    ## Arguments
    - `a::Vector{T1}`: Vector containing the element to subtract from atomically.
    - `b::T2`: Value to subtract from `a[1]`.
    
    ## Returns
    - `T1`: The old value stored at `a[1]`.
    """
    function atomicSub(a::Vector{T1}, b::T2)::T1 where {T1, T2}
        ret = a[1]  # Retrieve the current value at a[1]
        a[1] -= b  # Subtract b from a[1]
        return ret  # Return the old value
    end

    """
    Atomic Minimum operation for a single element in a vector.
    
    ## Arguments
    - `a::Vector{T1}`: Vector containing the element to compare and potentially update atomically.
    - `b::T2`: Value to compare against `a[1]` and store the minimum.
    
    ## Returns
    - `T1`: The old value stored at `a[1]`.
    """
    function atomicMin(a::Vector{T1}, b::T2)::T1 where {T1, T2}
        ret = a[1]  # Retrieve the current value at a[1]
        a[1] = min(ret, T1(b))  # Update a[1] with the minimum of its current value and b
        return ret  # Return the old value
    end

    """
    Atomic Maximum operation for a single element in a vector.
    
    ## Arguments
    - `a::Vector{T1}`: Vector containing the element to compare and potentially update atomically.
    - `b::T2`: Value to compare against `a[1]` and store the maximum.
    
    ## Returns
    - `T1`: The old value stored at `a[1]`.
    """
    function atomicMax(a::Vector{T1}, b::T2)::T1 where {T1, T2}
        ret = a[1]  # Retrieve the current value at a[1]
        a[1] = max(ret, T1(b))  # Update a[1] with the maximum of its current value and b
        return ret  # Return the old value
    end

end

end

end

# Test cases
using .heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat.cms.cudacompat

# AtomicCAS test
arr = [1]
old_value = cudacompat.atomicCAS(arr, 1, 2)
println("AtomicCAS test: Original value = 1, New value = $(arr[1]), Returned old value = $old_value")

# AtomicInc test
old_value = cudacompat.atomicInc(arr, 2)
println("AtomicInc test: Original value = 1, New value = $(arr[1]), Returned old value = $old_value")

# AtomicAdd test
old_value = cudacompat.atomicAdd(arr, 2)
println("AtomicAdd test: Original value = 1, New value = $(arr[1]), Returned old value = $old_value")

# AtomicSub test
old_value = cudacompat.atomicSub(arr, 2)
println("AtomicSub test: Original value = 5, New value = $(arr[1]), Returned old value = $old_value")

# AtomicMin test
old_value = cudacompat.atomicMin(arr, 2)
println("AtomicMin test: Original value = 3, New value = $(arr[1]), Returned old value = $old_value")

# AtomicMax test
old_value = cudacompat.atomicMax(arr, 5)
println("AtomicMax test: Original value = 3, New value = $(arr[1]), Returned old value = $old_value")
