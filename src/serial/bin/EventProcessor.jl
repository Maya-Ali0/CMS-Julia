
include(joinpath(@__DIR__, "..", "Framework", "EventSetup.jl"))



edmodules = Vector{String}()
esmodules = Vector{String}()


edmodules = ["BeamSpotToPOD",
                "SiPixelRawToClusterCUDA", 
                "SiPixelRecHitCUDA", 
                "CAHitNtupletCUDA", 
                "PixelVertexProducerCUDA"]

esmodules = ["BeamSpotESProducer",
                 "SiPixelFedCablingMapGPUWrapperESProducer",
                 "SiPixelGainCalibrationForHLTGPUESProducer",
                 "PixelCPEFastESProducer"]



                 
