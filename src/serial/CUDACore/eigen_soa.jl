module eigenSOA

    is_power_2(v::Integer) = ((v != 0) && ((v & (v-1)) == 0)) # For positive integers

    struct ScalarSOA{Scalar,S}
        data::MArray{Tuple{S},Scalar}
        function ScalarSOA{Scalar,S}() where {Scalar,S}
            @assert typeof(S) <: Integer
            @assert is_power_2(S) "SOA Stride not power of 2"
            @assert sizeof(Scalar)*S % 128 == 0
            new{Scalar,S}(MArray{Tuple{S},Scalar}(undef))
        end
    end




end