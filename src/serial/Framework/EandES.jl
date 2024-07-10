include("EDTokens.jl")

abstract type WrapperBase end

struct Wrapper{T} <: WrapperBase
    obj::T
end

struct Event
    streamId::Int
    eventId::Int
    products::Vector{Union{WrapperBase, Nothing}}  # Union type to allow for null elements

    function Event(streamIDD::Int,eventIDD::Int)
        return new(streamIDD,eventIDD,Vector{Union{WrapperBase, Nothing}}())
    end
end

# Accessor functions for Event
streamID(event::Event) = event.streamId
eventID(event::Event) = event.eventId

# Function to retrieve a product of type T from Event
function get(event::Event, token::EDGetTokenT{T})::T where T
    wrapper = event.products[token.index]
    return wrapper.obj 
end

# Function to insert a product of type T into Event
function emplace(event::Event, token::EDPutTokenT{T}, args...) where T
    event.products[token.index] = Wrapper{T}(args...)
end

########################################################################


abstract type ESWrapperBase end

struct ESWrapper{T} <: ESWrapperBase
    obj::T
end

mutable struct EventSetup
    typeToProduct::Dict{DataType, ESWrapperBase}

    function EventSetup()
        return new(Dict{DataType, ESWrapperBase}())
    end
end

function put!(es::EventSetup, prod::T) where T
    es.typeToProduct[T] = ESWrapper(prod)
end

function get(es::EventSetup, ::Type{T}) where T
    if haskey(es.typeToProduct, T)
        return es.typeToProduct[T].obj
    else
        throw(ErrorException("Product of type $(T) is not produced"))
    end
end

