module edm

const UNINITIALIZED_VALUE = UInt32(0xFFFFFFFF)

export EDGetTokenT, EDGetToken

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


end 
