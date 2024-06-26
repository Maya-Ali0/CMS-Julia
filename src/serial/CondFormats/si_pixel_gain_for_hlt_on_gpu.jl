module CondFormatsSiPixelObjectsSiPixelGainForHLTonGPU

include("../CUDACore/cuda_assert.jl")
using .GPUConfig

struct SiPixelGainForHLTonGPUDecodingStructure
    gain::UInt8
    ped::UInt8
end

# copy of SiPixelGainCalibrationForHL
mutable struct SiPixelGainForHLTonGPU
    const DecodingStructure = SiPixelGainForHLTonGPUDecodingStructure
    const Range = Tuple{UInt32, UInt32}

    v_pedestals::DecodingStructure
    range_and_cols::Tuple{Range, Int32}
    _min_ped::Float32
    _max_ped::Float32
    _min_gain::Float32
    _max_gain::Float32
    ped_precision::Float32
    gain_precision::Float32
    _number_of_rows__averaged_over::UInt32 # this is 80!!!!
    _n_bins_to_use_for_encoding::UInt32
    _dead_flag::UInt32
    _noisy_flag::UInt32


    @inline function get_ped_and_gain(module_ind::UInt32, col::Int32, row::Int32, is_dead_column::Bool, is_noisy_column::Bool)::Tuple{Float32, Float32}
        range = first(range_and_cols[module_ind])
        nCols = second(range_and_cols[module_ind])

        # determine what averaged data block we are in (there should be 1 or 2 of these depending on if plaquette is 1 by X or 2 by X
        lengthOfColumnData::UInt32 = (second(range) - first(range)) / nCols
        lengthOfAveragedDataInEachColumn::UInt32 = 2 # we always only have two values per column averaged block
        numberOfDataBlocksToSkip::UInt32 = row / _number_of_rows__averaged_over
        
    end
end

end # module CondFormatsSiPixelObjectsSiPixelGainForHLTonGPU