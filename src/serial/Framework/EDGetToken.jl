module edm

const UNINITIALIZED_VALUE = UInt32(0xFFFFFFFF)

struct EDGetToken
    value::UInt32
    EDGetToken() = new(UNINITIALIZED_VALUE)
    function EDGetToken{T}(token::EDGetTokenT{T})
        new(token.value)
    end
end

function index(token::EDGetToken)
    return token.value
end

function isUninitialized(token::EDGetToken)
    return token.value == UNINITIALIZED_VALUE
end

struct EDGetTokenT{T}
    value::UInt32
    EDGetTokenT() = new(UNINITIALIZED_VALUE)
end

function index(token::EDGetTokenT{T})
    return token.value
end

function isUninitialized(token::EDGetTokenT{T})
    return token.value == UNINITIALIZED_VALUE
end

end 
