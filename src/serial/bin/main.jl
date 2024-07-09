include("../DataFormats/data_formats.jl")
using .dataFormats

include("ReadRaw.jl")
include("../Framework/EandES.jl")


raw_events = readall(open((@__DIR__) * "/../../../data/raw.bin")) # Reads 1000 events

es::EventSetup = EventSetup()

for event ∈ raw_events
    
end

