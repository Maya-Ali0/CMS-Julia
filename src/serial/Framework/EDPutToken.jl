module edm_edputoken

export EDPutToken, EDPutTokenT
const UNINITIALIZED_VALUE = UInt32(0xFFFFFFFF)


struct EDPutTokenT{T}
    value::UInt32

    EDPutTokenT() = new{T}(UNINITIALIZED_VALUE)
end

function index(token::EDPutTokenT{T})::UInt32 where T
    return token.value
end

function isUninitialized(token::EDPutTokenT{T})::Bool where T
    return token.value == UNINITIALIZED_VALUE
end


struct EDPutToken
    value::UInt32

    EDPutToken() = new(UNINITIALIZED_VALUE)

    function EDPutToken(token::EDPutTokenT{T}) where T
        new(token.value)
    end

end


function index(token::EDPutToken)::UInt32
    return token.value
end

function isUninitialized(token::EDPutToken)::Bool
    return token.value == UNINITIALIZED_VALUE
end


end 
