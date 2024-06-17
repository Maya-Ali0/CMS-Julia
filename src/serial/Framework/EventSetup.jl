module edm

# ESWrapperBase class definition
abstract type ESWrapperBase end

# ESWrapper class definition
struct ESWrapper{T} <: ESWrapperBase
    obj::T
end

# EventSetup class definition
mutable struct EventSetup
    typeToProduct::Dict{DataType, ESWrapperBase}
end

# put method for EventSetup
function put(es::EventSetup, prod::T) where T
    es.typeToProduct[T] = ESWrapper(prod)
end

# get method for EventSetup
function get(es::EventSetup, ::Type{T}) where T
    if haskey(es.typeToProduct, T)
        return es.typeToProduct[T].obj
    else
        throw(ErrorException("Product of type $(T) is not produced"))
    end
end

end  

