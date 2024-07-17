using Patatrack

raw_events = readall(open((@__DIR__) * "/data/raw.bin")) # Reads 1000 event


es::EventSetup = EventSetup()
dataDir::String = (@__DIR__) * "/data/"


cabling_map_producer::SiPixelFedCablingMapGPUWrapperESProducer = SiPixelFedCablingMapGPUWrapperESProducer(dataDir)
gain_Calibration_producer::SiPixelGainCalibrationForHLTGPUESProducer = SiPixelGainCalibrationForHLTGPUESProducer(dataDir)

produce(cabling_map_producer,es)
produce(gain_Calibration_producer,es);


for event ∈ raw_events
    rawToCluster = SiPixelRawToClusterCUDA()
    # produce(rawToCluster,event,es)
end



# produce(beamSpotProducer,es)


