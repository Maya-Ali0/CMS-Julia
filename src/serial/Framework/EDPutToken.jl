module edm

const UNINITIALIZED_VALUE = UInt32(0xFFFFFFFF)

struct EDPutToken
    value::UInt32

    EDPutToken() = new(UNINITIALIZED_VALUE)

    function EDPutToken{T}(token::EDPutTokenT{T}) 
        new(token.value)
    end

end


function index(token::EDPutToken)::UInt32
    return token.value
end

function isUninitialized(token::EDPutToken)::Bool
    return token.value == UNINITIALIZED_VALUE
end


struct EDPutTokenT{T}
    value::UInt32

    EDPutTokenT() = new(UNINITIALIZED_VALUE)
end

function index(token::EDPutTokenT{T})::UInt32
    return token.value
end

function isUninitialized(token::EDPutTokenT{T})::Bool
    return token.value == UNINITIALIZED_VALUE
end

end 
