module condFormatsSiPixelObjectsSiPixelGainForHLTonGPU

include("../CUDACore/cuda_assert.jl")
using .gpuConfig

using Pkg
Pkg.add("StaticArrays")
using StaticArrays

struct siPixelGainForHLTonGPUDecodingStructure
    gain::UInt8
    ped::UInt8
end

const DecodingStructure = siPixelGainForHLTonGPUDecodingStructure
const Range = Tuple{UInt32, UInt32}

# copy of siPixelGainCalibrationForHL
mutable struct siPixelGainForHLTonGPU
    v_pedestals::DecodingStructure
    range_and_cols::MVector{2000, Tuple{Range, UInt16}}
    _min_ped::Float32
    _max_ped::Float32
    _min_gain::Float32
    _max_gain::Float32
    ped_precision::Float32
    gain_precision::Float32
    _number_of_rows_averaged_over::UInt32 # this is 80!!!!
    _n_bins_to_use_for_encoding::UInt32
    _dead_flag::UInt32
    _noisy_flag::UInt32
end

# be careful of the type of unsigned ints, should it be UInt32 or UInt16, and check with consistencies in si_pixel_gain_for_hlt_on_gpu

@inline function get_ped_and_gain(structure::siPixelGainForHLTonGPU, module_ind::UInt16, col::UInt16, row::UInt16, is_dead_column_is_noisy_column::MVector{2, Bool})::Tuple{Float32, Float32}
    range::Range = structure.range_and_cols[module_ind][1]
    nCols = structure.range_and_cols[module_ind][2]

    # determine what averaged data block we are in (there should be 1 or 2 of these depending on if plaquette is 1 by X or 2 by X
    lengthOfColumnData::UInt16 = (range[2] - range[1]) / nCols
    lengthOfAveragedDataInEachColumn::UInt16 = 2 # we always only have two values per column averaged block
    numberOfDataBlocksToSkip::UInt16 = row / structure._number_of_rows_averaged_over
    offset = range[1] + col + lengthOfColumnData + lengthOfAveragedDataInEachColumn*numberOfDataBlocksToSkip

    @assert offset < range[2]
    @assert offset < 3088384
    @assert offset % 2 == 0

    const lp::DecodingStructure = structure.v_pedestals
    s = lp[offset / 2]

    is_dead_column_is_noisy_column[1] = (s.ped & 0xFF) == structure._dead_flag
    is_dead_column_is_noisy_column[2] = (s.ped & 0xFF) == structure._noisy_flag

    return tuple{decode_ped(structure, s.ped & 0xFF), decode_gain(structure, s.gain & 0xFF)}
end

decode_gain(structure::siPixelGainForHLTonGPU, gain::UInt32)::Float32 = gain * structure.gain_precision + structure._min_gain
decode_ped(structure::siPixelGainForHLTonGPU, ped::UInt32)::Float32 = ped * structure.ped_precision + structure._min_ped

end # module condFormatsSiPixelObjectsSiPixelGainForHLTonGPU