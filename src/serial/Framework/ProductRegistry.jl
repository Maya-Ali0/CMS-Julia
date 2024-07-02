include("EDGetToken.jl")
using .edm_edgettoken
include("EDPutToken.jl")
using .edm_edputoken

module edm_product

struct ProductRegistry
    currentModuleIndex::Int
    consumedModules::Set{UInt}
    typeToIndex::Dict{DataType, Tuple{UInt, UInt}}
end

function produces(registry::ProductRegistry,::Type{T})::EDPutTokenT{T} where T
    ind = length(registry.typeToIndex)
    if haskey(registry.typeToIndex, T)
        throw(RuntimeError("Product of type $T already exists"))
    end
    registry.typeToIndex[T] = (registry.currentModuleIndex, ind)
    return EDPutTokenT{T}(ind)
end

function consumes(registry::ProductRegistry,::Type{T})::EDGetTokenT{T} where T
    if !haskey(registry.typeToIndex, T)
        throw(RuntimeError("Product of type $T is not produced"))
    end
    indices = registry.typeToIndex[T]
    push!(registry.consumedModules, indices[1])
    return EDGetTokenT{T}(indices[2])
end

function size(registry::ProductRegistry)::Int
    return length(registry.typeToIndex)
end

function beginModuleConstruction(registry::ProductRegistry, i::Int)
    registry.currentModuleIndex = i
    empty!(registry.consumedModules)
end

function consumedModules(registry::ProductRegistry)::Set{UInt}
    return registry.consumedModules
end


end