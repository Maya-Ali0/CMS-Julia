
"""
    readall(io::IOStream)

Read data of one fed from a stream of data in the patatrack raw data format.

See also [readall](@ref).
"""
function readfed(io::IOStream)
    fedid = read(io, Int32)
    fedsize = read(io, Int32)
    feddata = read(io, fedsize)
    return FedRawData(fedid, feddata)
end

"""
    readevent(io::IOStream)

Read one event from a stream of data in the patatrack raw data format.

See also [readall](@ref).
"""
function readevent(io::IOStream)
    nfeds = read(io, Int32)
    collectionRaw = [ readfed(io) for i in 1:nfeds]
    collection::FedRawDataCollection = FedRawDataCollection(collectionRaw)
    return collection
end

"""
    readall(io::IOStream)

Read all events from a stream of data in the patatrack raw data format.
"""
function readall(io::IOStream)
    events::Vector{FedRawDataCollection} = Vector{FedRawDataCollection}()
    while !eof(io)
        push!(events, readevent(io))
    end
    return events
end