module edm

include("ProductRegistry.jl")
using .edm_product

# Define StreamID as an alias for Int
const StreamID = Int

# Abstract type for type erasure
abstract type WrapperBase end

# Wrapper type for holding objects of type T
struct Wrapper{T} <: WrapperBase
    obj::T
end

# Event class
struct Event
    streamId::StreamID
    eventId::Int
    products::Vector{Union{WrapperBase, Nothing}}  # Union type to allow for null elements
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

end
