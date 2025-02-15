using .dataFormats

mutable struct Source

    raw_events::Vector{FedRawDataCollection}
    numEvents::Atomic{Int}
    rawToken::EDPutTokenT{FedRawDataCollection}

    function Source(reg::ProductRegistry, dataDir::String)
        rawToken = produces(reg,FedRawDataCollection)
        rawFilePath = joinpath(dataDir, "raw.bin")
        raw_events = readall(open(rawFilePath)) # Reads 1000 event 
        
        return new(raw_events,Atomic{Int}(1),rawToken)
    end



end

function produce(src::Source, streamId::Int, reg::ProductRegistry)
    if src.numEvents.value > 1000
        return nothing
    end

    iev = atomic_add!(src.numEvents, 1)
    # println("Taking an Event ", iev)
    # print(src.raw_events)

    
    # if old >= src.maxEvents
    #     src.shouldStop = true
    #     atomic_sub!(src.numEvents, 1)
    #     return nothing
    # end
    ev = Event(streamId, iev, reg)

    emplace(ev,src.rawToken,src.raw_events[iev])


    # if src.validation
    #     ev.reg[src.digiClusterToken] = src.digiclusters[index]
    #     ev.reg[src.trackToken] = src.tracks[index]
    #     ev.reg[src.vertexToken] = src.vertices[index]
    # end

    return ev
end