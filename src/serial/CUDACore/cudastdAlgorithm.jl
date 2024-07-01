# Module definition for CUDA utilities and algorithms
module HeterogeneousCoreCUDAUtilitiesCudastdAlgorithm

# Include the CUDA compatibility definitions
include("../CUDACore/cudaCompat.jl")
using .heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat

# Nested module for standard CUDA algorithms
module cuda_std

    # Define a struct `Less` to be used as a comparator
    struct Less{T}
    end

    # Define the call operator for the `Less` struct to compare two values
    function (op::Less{T})(lhs::T, rhs::T) where T
        return lhs < rhs
    end

    # Function to find the lower bound using binary search
    # Arguments:
    # - first: The beginning of the range
    # - last: The end of the range
    # - value: The value to compare against
    # - comp: The comparator of type `Less`
    function lower_bound(first, last, value, comp::Less{T}) where T
        count = last - first
        while count > 0
            it = first
            step = count ÷ 2  # Use integer division to avoid potential type issues
            it = it + step
            if comp(it, value)
                first = it + 1
                count = count - (step + 1)
            else
                count = step
            end
        end
        return first
    end

    # Function to find the upper bound using binary search
    # Arguments:
    # - first: The beginning of the range
    # - last: The end of the range
    # - value: The value to compare against
    # - comp: The comparator of type `Less`
    function upper_bound(first, last, value, comp::Less{T}) where T
        count = last - first
        while count > 0
            step = count ÷ 2  # Use integer division to avoid potential type issues
            it = first + step 
            if !comp(value, it)
                first = it + 1
                count = count - (step + 1)
            else
                count = step
            end
        end
        return first  
    end
    
    # Function to perform a binary search
    # Arguments:
    # - first: The beginning of the range
    # - last: The end of the range
    # - value: The value to search for
    # - comp: The comparator of type `Less`
    function binary_find(first, last, value, comp::Less{T}) where T
        first = cuda_std::lower_bound(first, last, value, comp)
        return first != last && !comp(value, first) ? first : last
    end

end  # End of nested module `cuda_std`
end  # End of module `HeterogeneousCoreCUDAUtilitiesCudastdAlgorithm`
