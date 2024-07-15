using .condFormatsSiPixelFedIds:SiPixelFedIds

using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU:SiPixelFedCablingMapGPU
using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU.pixelGPUDetails

using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper:SiPixelFedCablingMapGPUWrapper

using .condFormatsSiPixelFedIds

struct SiPixelFedCablingMapGPUWrapperESProducer <: ESProducer
    data::String  # Use String to represent the path

    function SiPixelFedCablingMapGPUWrapperESProducer(datadir::String)
        new(datadir)
    end
end


function readCablingMap(io::IOStream,es::EventSetup)
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
    # print(Base.size(data))
    # print(offset)
    offset += 128

    mod_to_unp_def_size = reinterpret(UInt32, data[offset:offset + size_UInt32 - 1])[1]
    offset += 4
    mod_to_unp_default = Vector{UInt8}(undef, mod_to_unp_def_size)
    jump3 = mod_to_unp_def_size

    mod_to_unp_default.= reinterpret(UInt8, data[offset:offset + jump3 - 1])
    open("testingCablingMap.txt","w") do file
        for i ∈ 1:MAX_SIZE
            write(file, string(cablingMap.roc_in_det[i]),'\n')
        end
    end


    put!(es,SiPixelFedCablingMapGPUWrapper(cablingMap,mod_to_unp_default))
end


function produce(producer::SiPixelFedCablingMapGPUWrapperESProducer, eventSetup::EventSetup)
    fed_ids_file = joinpath(producer.data, "fedIds.bin")
    # Read fedIds.bin
    open(fed_ids_file, "r") do io
        nfeds = read(io, UInt32)
        fed_ids = Vector{UInt32}(undef, nfeds)
        read!(io, fed_ids)
        put!(eventSetup,SiPixelFedIds(fed_ids))
    end
    

    # Read cablingMap.bin
    cabling_map_file = joinpath(producer.data, "cablingMap.bin")
    
    open(cabling_map_file, "r") do io
        readCablingMap(io,eventSetup)
    end

end





