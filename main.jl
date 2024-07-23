using Patatrack

# raw_events = readall(open((@__DIR__) * "/data/raw.bin")) # Reads 1000 event


es::EventSetup = EventSetup()
dataDir::String = (@__DIR__) * "/data/"


cabling_map_producer::SiPixelFedCablingMapGPUWrapperESProducer = SiPixelFedCablingMapGPUWrapperESProducer(dataDir)
gain_Calibration_producer::SiPixelGainCalibrationForHLTGPUESProducer = SiPixelGainCalibrationForHLTGPUESProducer(dataDir)
CPE_Producer = PixelCPEFastESProducer(dataDir)

# produce(cabling_map_producer,es);
# produce(gain_Calibration_producer,es);
produce(CPE_Producer,es)

x = gett(es,PixelCPEFast)

open("output.txt","w") do file
for i ∈ 1:1856
    write(file,"isBarrel: ")
    write(file,string(Int(x.m_detParamsGPU[i].isBarrel)))
    write(file,"\n")

    write(file,"isPosZ: ")
    write(file,string(Int(x.m_detParamsGPU[i].isPosZ)))
    write(file,"\n")

    write(file,"layer: ")
    write(file,string(x.m_detParamsGPU[i].layer))
    write(file,"\n")

    write(file,"index: ")
    write(file,string(x.m_detParamsGPU[i].index))
    write(file,"\n")

    write(file,"rawId: ")
    write(file,string(x.m_detParamsGPU[i].rawId))
    write(file,"\n")

    write(file,"shiftX: ")
    write(file,string(x.m_detParamsGPU[i].shiftX))
    write(file,"\n")

    write(file,"shiftY: ")
    write(file,string(x.m_detParamsGPU[i].shiftY))
    write(file,"\n")

    write(file,"chargeWidthX: ")
    write(file,string(x.m_detParamsGPU[i].chargeWidthX))
    write(file,"\n")

    write(file,"chargeWidthY: ")
    write(file,string(x.m_detParamsGPU[i].chargeWidthY))
    write(file,"\n")

    write(file,"x0: ")
    write(file,string(x.m_detParamsGPU[i].x0))
    write(file,"\n")

    write(file,"y0: ")
    write(file,string(x.m_detParamsGPU[i].y0))
    write(file,"\n")

    write(file,"z0: ")
    write(file,string(x.m_detParamsGPU[i].z0))
    write(file,"\n")

    write(file,"sx[1]: ")
    write(file,string(x.m_detParamsGPU[i].sx[1]))
    write(file,"\n")

    write(file,"sx[2]: ")
    write(file,string(x.m_detParamsGPU[i].sx[2]))
    write(file,"\n")

    write(file,"sx[3]: ")
    write(file,string(x.m_detParamsGPU[i].sx[3]))
    write(file,"\n")

    write(file,"sy[1]: ")
    write(file,string(x.m_detParamsGPU[i].sy[1]))
    write(file,"\n")

    write(file,"sy[2]: ")
    write(file,string(x.m_detParamsGPU[i].sy[2]))
    write(file,"\n")

    write(file,"sy[3]: ")
    write(file,string(x.m_detParamsGPU[i].sy[3]))
    write(file,"\n")

    write(file,"frame.px: ")
    write(file,string(x.m_detParamsGPU[i].frame.px))
    write(file,"\n")

    write(file,"frame.py: ")
    write(file,string(x.m_detParamsGPU[i].frame.py))
    write(file,"\n")

    write(file,"frame.pz: ")
    write(file,string(x.m_detParamsGPU[i].frame.pz))
    write(file,"\n")

    write(file,"R11: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R11))
    write(file,"\n")

    write(file,"R12: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R12))
    write(file,"\n")

    write(file,"R13: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R13))
    write(file,"\n")

    write(file,"R21: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R21))
    write(file,"\n")

    write(file,"R22: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R22))
    write(file,"\n")

    write(file,"R23: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R23))
    write(file,"\n")

    write(file,"R31: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R31))
    write(file,"\n")

    write(file,"R32: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R32))
    write(file,"\n")

    write(file,"R33: ")
    write(file,string(x.m_detParamsGPU[i].frame.rot.R33))
    write(file,"\n")
end

write(file,"theThicknessB: ")
write(file,string(x.m_commonParamsGPU.theThicknessB))
write(file,"\n")

write(file,"theThicknessE: ")
write(file,string(x.m_commonParamsGPU.theThicknessE))
write(file,"\n")

write(file,"thePitchX: ")
write(file,string(x.m_commonParamsGPU.thePitchX))
write(file,"\n")

write(file,"thePitchY: ")
write(file,string(x.m_commonParamsGPU.thePitchY))
write(file,"\n")


for i ∈ 1:11
    write(file,"layerStart[$i]: ")
    write(file,string(x.m_layerGeometry.layerStart[i]))
    write(file,"\n")
end

for i ∈ 1:116
    write(file,"layerGeometry[$i]: ")
    write(file,string(x.m_layerGeometry.layer[i]))
    write(file,"\n")
end

for i ∈ 1:148
    write(file,"ladderZ[$i]: ")
    write(file,string(x.m_averageGeometry.ladderZ[i]))
    write(file,"\n")
    write(file,"ladderX[$i]: ")
    write(file,string(x.m_averageGeometry.ladderX[i]))
    write(file,"\n")
    write(file,"ladderY[$i]: ")
    write(file,string(x.m_averageGeometry.ladderY[i]))
    write(file,"\n")
    write(file,"ladderR[$i]: ")
    write(file,string(x.m_averageGeometry.ladderR[i]))
    write(file,"\n")
    write(file,"ladderMinZ[$i]: ")
    write(file,string(x.m_averageGeometry.ladderMinZ[i]))
    write(file,"\n")
    write(file,"ladderMaxZ[$i]: ")
    write(file,string(x.m_averageGeometry.ladderMaxZ[i]))
    write(file,"\n")
end

write(file,"endCapZ[1]: ")
write(file,string(x.m_averageGeometry.endCapZ[1]))
write(file,"\n")

write(file,"endCapZ[2]: ")
write(file,string(x.m_averageGeometry.endCapZ[2]))
write(file,"\n")

end

# struct PixelCPEFast
#   string(  m_detParamsGPU::Vector{DetParams}
#     m_commonParamsGPU::CommonParams
#     m_layerGeometry::LayerGeometry
#     m_averageGeometry::AverageGeometry
#     cpuData_::ParamsOnGPU
# end

# struct AverageGeometry
#     number_of_ladders_in_barrel::UInt32
#     ladderZ::Vector{Float32}
#     ladderX::Vector{Float32}
#     ladderY::Vector{Float32}
#     ladderR::Vector{Float32}
#     ladderMinZ::Vector{Float32}
#     ladderMaxZ::Vector{Float32}
#     endCapZ::NTuple{2, Float32}  # just for pos and neg Layer1
# end





# for event ∈ raw_events
#     rawToCluster = SiPixelRawToClusterCUDA()
#     # produce(rawToCluster,event,es)
# end



# produce(beamSpotProducer,es)







