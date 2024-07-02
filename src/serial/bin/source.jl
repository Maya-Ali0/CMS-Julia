include(joinpath(@__DIR__, "..", "Framework", "Event.jl"))

include(joinpath(@__DIR__, "..", "DataFormats", "FEDRawDataCollection.jl"))
include(joinpath(@__DIR__, "..", "DataFormats", "DigiClusterCount.jl"))
include(joinpath(@__DIR__, "..", "DataFormats", "TrackCount.jl"))
include(joinpath(@__DIR__, "..", "DataFormats", "VertexCount.jl"))



module edm

    struct Source
        maxEvents::Int
        runForMinutes::Int
        numEvents::Int

        rawToken::EDPutTokenT{FEDRawDataCollection}
        digiClusterToken::EDPutTokenT{DigiClusterCount}
        trackToken::EDPutTokenT{TrackCount}
        vertexToken::EDPutTokenT{VertexCount}

        raw::Vector{FEDRawDataCollection}
        digiclusters::Vector{DigiClusterCount}
        tracks::Vector{TrackCount}
        vertices::Vector{VertexCount}

        validation::Bool
    end
    












end

