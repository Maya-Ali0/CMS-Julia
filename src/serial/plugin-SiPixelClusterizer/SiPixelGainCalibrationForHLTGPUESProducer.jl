using .CalibTrackerSiPixelESProducersInterfaceSiPixelGainCalibrationForHLTGPU
using .condFormatsSiPixelObjectsSiPixelGainForHLTonGPU

struct SiPixelGainCalibrationForHLTGPUESProducer <: ESProducer
    data::String  # Use String to represent the path

    function SiPixelGainCalibrationForHLTGPUESProducer(datadir::String)
        new(datadir)
    end
end


function produce(producer::SiPixelGainCalibrationForHLTGPUESProducer, eventSetup::EventSetup)
    gain_file = joinpath(producer.data, "gain.bin")
    
    #read gain.bin
    open(gain_file, "r") do io

        gain = Vector{UInt8}(undef,sizeof(read_SiPixelGainForHLTonGPU)) 
        read!(io, gain)

        nbytes = read(io, UInt32)
        gain_data = Vector{UInt8}(undef, nbytes)
        read!(io, gain_data)

        put!(eventSetup,SiPixelGainCalibrationForHLTGPU(gain,gain_data))
    end
end

