const UNINITIALIZED_VALUE = UInt32(0xFFFFFFFF)

struct EDGetTokenT{T}
    value::UInt32
    EDGetTokenT() = new{T}(UNINITIALIZED_VALUE)
end

function index(token::EDGetTokenT{T}) where T 
    return token.value
end

function isUninitialized(token::EDGetTokenT{T}) where T
    return token.value == UNINITIALIZED_VALUE
end


struct EDGetToken
    value::UInt32
    EDGetToken() = new(UNINITIALIZED_VALUE)
    function EDGetToken(token::EDGetTokenT{T}) where T
        new(token.value)
    end
end

function index(token::EDGetToken)
    return token.value
end

function isUninitialized(token::EDGetToken)
    return token.value == UNINITIALIZED_VALUE
end

struct EDPutTokenT{T}
    value::UInt32

    EDPutTokenT() = new{T}(UNINITIALIZED_VALUE)

    function EDPutTokenT{T}(x::UInt32) where T
        new{T}(x)
    end
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

