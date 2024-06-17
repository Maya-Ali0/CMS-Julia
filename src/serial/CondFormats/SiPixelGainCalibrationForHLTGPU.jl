module CalibTracker_SiPixelESProducers_interface_SiPixelGainCalibrationForHLTGPU_h

mutable struct SiPixelGainForHLTonGPU
end

struct SiPixelGainForHLTonGPU_DecodingStructure
end

mutable struct SiPixelGainCalibrationForHLTGPU
    _gainForHLTonHost::SiPixelGainForHLTonGPU
    _gainData::Vector{UInt8}

    function SiPixelGainCalibrationForHLTGPU(gain::SiPixelGainForHLTonGPU, gainData::Vector{UInt8})
        new(gain, gainData)
    end
end

# Getter function to access gainForHLTonHost field
getCPUProduct(calib::SiPixelGainCalibrationForHLTGPU) = calib.gainForHLTonHost

end # module CalibTracker_SiPixelESProducers_interface_SiPixelGainCalibrationForHLTGPU_h
