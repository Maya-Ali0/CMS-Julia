include("../DataFormats/data_formats.jl")
using .dataFormats

include("ReadRaw.jl")
include("../Framework/EandES.jl")

include("../plugin-SiPixelClusterizer/SiPixelFedCablingMapGPUWrapperESProducer.jl")
include("../plugin-SiPixelClusterizer/SiPixelGainCalibrationForHLTGPUESProducer.jl")

raw_events = readall(open((@__DIR__) * "/../../../data/raw.bin")) # Reads 1000 events

es::EventSetup = EventSetup()

dataDir::String = (@__DIR__) * "/../../../data/raw.bin"

cabling_map_producer::SiPixelFedCablingMapGPUWrapperESProducer = SiPixelFedCablingMapGPUWrapperESProducer(dataDir)
gain_Calibration_producer::SiPixelGainCalibrationForHLTGPUESProducer = SiPixelGainCalibrationForHLTGPUESProducer(dataDir)

produce(cabling_map_producer,es)
produce(gain_Calibration_producer,es)

for event ∈ raw_events

end



