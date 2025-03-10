# using Revise
include("src/Patatrack.jl")
using .Patatrack
using Profile, BenchmarkTools, ProfileView
const num_of_threads::Int = 1
const num_of_streams::Int = 0
const warm_up_events::Int = 0 # Number of events to process before starting the benchmark (default 0).
const max_events::Int = -1 # Number of events to process
const run_for_minutes::Int = -1 # Continue processing the set of 1000 events until this many minutes have passed
const validation::Bool = true #  Run (rudimentary) validation at the end.
const histogram::Bool = false # prduce a histogram at the end
const empty::Bool = false # Ignore all producers (used for testing only)

function run(num_of_streams::Int)

ed_modules::Vector{String} = String[]
es_modules::Vector{String} = String[]

if(!empty)
    ed_modules = ["SiPixelRawToClusterCUDA","BeamSpotToPOD", "SiPixelRecHitCUDA", "CAHitNtupletCUDA", "PixelVertexProducerCUDA"]
    es_modules = ["SiPixelFedCablingMapGPUWrapperESProducer","SiPixelGainCalibrationForHLTGPUESProducer","PixelCPEFastESProducer","BeamSpotESProducer"]
end
if(validation)
    push!(ed_modules,"CountValidator")
end

if(histogram)
    push!(ed_modules,"HistoValidator")
end
                                                                                                                                           #Not Currently Used
##############################################################################################################################################################
es::EventSetup = EventSetup()
dataDir::String = (@__DIR__) * "/data/"

# EP = EventProcessor(ed_modules,es_modules,dataDir)

ev = EventProcessor(num_of_streams,ed_modules,es_modules,dataDir,validation);
# println("Warming up")
# @time warm_up(ev)
# println("Warmup done")
println("running")
@time run_processor(ev)

end



# number_of_streams = parse(Int, ARGS[1]) # First argument as number of events
# print(number_of_streams)

const number_of_streams = 1
run(number_of_streams)
println("Number of threads: ", Threads.nthreads())


