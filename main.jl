using Patatrack
using BenchmarkTools, ProfileView
num_of_threads::Int = 1
num_of_streams::Int = 0
warm_up_events::Int = 0 # Number of events to process before starting the benchmark (default 0).
max_events::Int = -1 # Number of events to process
run_for_minutes::Int = -1 # Continue processing the set of 1000 events until this many minutes have passed
validation::Bool = false #  Run (rudimentary) validation at the end.
histogram::Bool = false # prduce a histogram at the end
empty::Bool = false # Ignore all producers (used for testing only)

ed_modules::Vector{String} = String[]
es_modules::Vector{String} = String[]

if(!empty)
    ed_modules = ["SiPixelRawToClusterCUDA"]#,"BeamSpotToCUDA", "SiPixelRecHitCUDA", "CAHitNtupletCUDA", "PixelVertexProducerCUDA"]
    es_modules = ["SiPixelFedCablingMapGPUWrapperESProducer","SiPixelGainCalibrationForHLTGPUESProducer"]#,"PixelCPEFastESProducer","BeamSpotESProducer"]
end
                                                                                                                                           #Not Currently Used
##############################################################################################################################################################
raw_events = readall(open((@__DIR__) * "/data/raw.bin")) # Reads 1000 event  
es::EventSetup = EventSetup()
dataDir::String = (@__DIR__) * "/data/"


cabling_map_producer::SiPixelFedCablingMapGPUWrapperESProducer = SiPixelFedCablingMapGPUWrapperESProducer(dataDir)
gain_Calibration_producer::SiPixelGainCalibrationForHLTGPUESProducer = SiPixelGainCalibrationForHLTGPUESProducer(dataDir)
CPE_Producer = PixelCPEFastESProducer(dataDir)
beam_Producer = BeamSpotESProducer(dataDir)

produce(cabling_map_producer,es)
produce(gain_Calibration_producer,es);
produce(CPE_Producer,es);
produce(beam_Producer,es)

function run()
for collection ∈ raw_events
    reg = ProductRegistry()
    raw_token = produces(reg,FedRawDataCollection)
    rawToCluster = SiPixelRawToClusterCUDA(reg)
    event::Event = Event(reg)
    emplace(event,raw_token,collection)
    produce(rawToCluster,event,es)

    bs =  BeamSpotToPOD(reg)
    produce(bs,event,es)

    recHit = SiPixelRecHitCUDA(reg)
    produce(recHit,event,es)

end
end

@time run()




