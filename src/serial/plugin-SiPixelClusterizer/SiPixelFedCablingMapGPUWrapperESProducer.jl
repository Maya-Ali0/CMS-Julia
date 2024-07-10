using .condFormatsSiPixelFedIds:SiPixelFedIds

using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU:SiPixelFedCablingMapGPU

using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper:SiPixelFedCablingMapGPUWrapper

using .condFormatsSiPixelFedIds

struct SiPixelFedCablingMapGPUWrapperESProducer <: ESProducer
    data::String  # Use String to represent the path

    function SiPixelFedCablingMapGPUWrapperESProducer(datadir::String)
        new(datadir)
    end
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
        obj = Vector{UInt8}(undef,sizeof(SiPixelFedCablingMapGPU)) 
        read!(io, obj)

        mod_to_unp_def_size = read(io, UInt32)
        mod_to_unp_default = Vector{UInt8}(undef, mod_to_unp_def_size)
        read!(io, mod_to_unp_default)

        objj::SiPixelFedCablingMapGPU = SiPixelFedCablingMapGPU()
        put!(eventSetup,SiPixelFedCablingMapGPUWrapper(objj,mod_to_unp_default))
    end
    
    
end




