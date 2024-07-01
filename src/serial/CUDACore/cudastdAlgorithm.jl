module HeterogeneousCoreCUDAUtilitiesCudastdAlgorithm

include("../CUDACore/cudaCompat.jl")
using .heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat

module cuda_std

    struct Less{T}
    end

    function (op::Less{T})(lhs::T, rhs::T) where T
        return lhs < rhs
    end

    function lower_bound(first, last, value, comp::less{T}) where T
        count = last - first
        while count > 0
            it = first
            step =  count / 2
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

    function upper_bound(first, last, value, comp::less{T}) where T
        count = last - first

        while count > 0 
            step = count / 2
            it = it + step
            if !comp(value, it)
                first = it + 1
                count = count - (step + 1)
            else
                count = step
            end
        end
    end
    
    function binary_find(first, last, value, comp::less{T}) where T
        first = cuda_std::lower_bound(first, last, value, comp)
        return first != last && !comp(value, first) ? first : last
    end


end
end