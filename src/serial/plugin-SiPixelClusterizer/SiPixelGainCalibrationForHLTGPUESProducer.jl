using .CalibTrackerSiPixelESProducersInterfaceSiPixelGainCalibrationForHLTGPU
using .condFormatsSiPixelObjectsSiPixelGainForHLTonGPU

struct SiPixelGainCalibrationForHLTGPUESProducer <: ESProducer
    data::String  # Use String to represent the path

    function SiPixelGainCalibrationForHLTGPUESProducer(datadir::String)
        new(datadir)
    end
end

function readGain(io::IOStream,es::EventSetup)
    data = read(io)

    cablingMap = SiPixelFedCablingMapGPU()
    offset = 1
    size_UInt32 = sizeof(UInt32)
    size_UInt8 = sizeof(UInt8)
    jump = size_UInt32 * recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU.pixelGPUDetails.MAX_SIZE
    jump2 = size_UInt8 * recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU.pixelGPUDetails.MAX_SIZE

    cablingMap.fed .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.link .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.roc .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.raw_id .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.roc_in_det .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.module_id .= reinterpret(UInt32, data[offset:offset + jump - 1])
    offset += jump
    
    cablingMap.bad_rocs .= reinterpret(UInt8, data[offset:offset + jump2 - 1])
    offset += size_UInt8 * jump2

    cablingMap.size = reinterpret(UInt32, data[offset:offset + 32*size_UInt32 - 1])[1]

    nbytes = reinterpret(UInt32, data[offset:offset + size_UInt32 - 1])[1]
    offset += 4
    mod_to_unp_default = Vector{UInt8}(undef, mod_to_unp_def_size)
    jump3 = mod_to_unp_def_size

    mod_to_unp_default.= reinterpret(UInt8, data[offset:offset + jump3 - 1])

    put!(eventSetup,SiPixelGainCalibrationForHLTGPU(gain,gain_data))
end


function produce(producer::SiPixelGainCalibrationForHLTGPUESProducer, eventSetup::EventSetup)
    gain_file = joinpath(producer.data, "gain.bin")
    
    #read gain.bin
    open(gain_file, "r") do io

        buffer = read(io, sizeof(SiPixelGainForHLTonGPU))
        gain = reinterpret(SiPixelGainForHLTonGPU, buffer)[1]
        read!(io, gain)

        nbytes = read(io, UInt32)
        gain_data = Vector{UInt8}(undef, nbytes)
        read!(io, gain_data)

        readGain(io,eventSetup)        
    end
end

