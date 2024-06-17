module CondFormats_SiPixelFedIds_h

mutable struct SiPixelFedIds
    _fedIDs::Vector{UInt32}

    function SiPixelFedIds(fedIDs::Vector{UInt32})
        new(fedIDs)
    end
end

function fedIds(ids::SiPixelFedIds)
    return ids.fedIds
end

end # module CondFormats_SiPixelFedIds_h
