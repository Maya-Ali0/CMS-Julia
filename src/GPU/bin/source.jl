include("../Framework/ProductRegistry.jl")

include("../DataFormats/data_formats.jl")
include("../Framework/EandES.jl")
include("../Framework/EDTokens.jl")

using .dataFormats

include("ReadRaw.jl")


struct Source
    max_events::Int
    run_for_minutes::Int
    num_events::Int
    rawToken_::EDPutTokenT{FedRawDataCollection}
    raw_::Vector{FedRawDataCollection}
    
    validation_::Bool

    #constructor
    function Source(maxEvents::Int, runForMinutes::Int, reg::ProductRegistry, validation::Bool) 
        maxEvents_ = maxEvents
        runForMinutes_ = runForMinutes
        rawToken_= produces(reg,FedRawDataCollection)
        validation_= validation

        raw_ = readall(open((@__DIR__) * "/../../../data/raw.bin"))

        return new(maxEvents, runForMinutes, 30, rawToken_, raw_, validation)
    end

end

function produce(src::Source,reg::ProductRegistry)
    
end