include("ProductRegistry.jl")

module edm

const StreamID = Int

abstract type WrapperBase end

struct Wrapper{T} <: WrapperBase
    obj::T
end

struct Event
    streamId::StreamID
    eventId::Int
    products::Vector{Union{WrapperBase, Nothing}}  # Union type to allow for null elements
end

streamID(event::Event) = event.streamId
eventID(event::Event) = event.eventId

function get(event::Event, token::EDGetTokenT)::T where T
    wrapper = event.products[token.index]
    return wrapper.obj
end

function emplace(event::Event, token::EDPutTokenT{T}, args...)
    event.products[token.index] = Wrapper{T}(args...)
end

end
