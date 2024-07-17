struct PixelCPEFastESProducer <: ESProducer
    data::String  # Use String to represent the path

    function PixelCPEFastESProducer(datadir::String)
        new(datadir)
    end
end

function readCpeFast(io::IOStream,es::EventSetup)

    x = read(io,Float32)
    y = read(io,Float32)
    z = read(io,Float32)
    sigmaZ = read(io,Float32)
    beamWidthX = read(io,Float32)
    beamWidthY = read(io,Float32)
    dxdz = read(io,Float32)
    dydz = read(io,Float32)
    emittanceX = read(io,Float32)
    emittanceY = read(io,Float32)
    betaStar = read(io,Float32)

    beam = BeamSpotPOD(x,y,z,sigmaZ,beamWidthX,beamWidthY,dxdz,dydz,emittanceX,emittanceY,betaStar)

    put!(es,beam)
end


function produce(producer::PixelCPEFastESProducer, eventSetup::EventSetup)
    cpe_file = joinpath(producer.data, "beamspot.bin")
    
    #read beamspot.bin
    open(cpe_file, "r") do io
        readBeam(io,eventSetup)        
    end
end

