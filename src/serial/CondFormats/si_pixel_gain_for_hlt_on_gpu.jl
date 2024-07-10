module condFormatsSiPixelObjectsSiPixelGainForHLTonGPU

using ..gpuConfig

using StaticArrays

export SiPixelGainForHLTonGPU

struct SiPixelGainForHLTonGPUDecodingStructure
    gain::UInt8
    ped::UInt8
end

const DecodingStructure = SiPixelGainForHLTonGPUDecodingStructure
const Range = Tuple{UInt32, UInt32}

# copy of SiPixelGainCalibrationForHL
mutable struct SiPixelGainForHLTonGPU
    _min_ped::Float32
    _max_ped::Float32
    _min_gain::Float32
    _max_gain::Float32

    _number_of_rows_averaged_over::UInt32 # this is 80!!!!
    _n_bins_to_use_for_encoding::UInt32
    _dead_flag::UInt32
    _noisy_flag::UInt32

    ped_precision::Float32
    gain_precision::Float32

    v_pedestals::DecodingStructure
    range_and_cols::MVector{2000, Tuple{Range, UInt16}}
end

@inline function get_ped_and_gain(structure::SiPixelGainForHLTonGPU, module_ind, col, row, is_dead_column_is_noisy_column::MVector{2, Bool})
    range = structure.range_and_cols[module_ind][1]
    n_cols = structure.range_and_cols[module_ind][2]

    # determine what averaged data block we are in (there should be 1 or 2 of these depending on if plaquette is 1 by X or 2 by X
    length_of_column_data = (range[2] - range[1]) / n_cols
    length_of_averaged_data_in_each_column = 2 # we always only have two values per column averaged block
    number_of_data_blocks_to_skip = row / structure._number_of_rows_averaged_over
    offset = range[1] + col + length_of_column_data + length_of_averaged_data_in_each_column * number_of_data_blocks_to_skip

    @assert (offset < range[2])
    @assert (offset < 3088384)
    @assert ((offset % 2) == 0)

    lp::DecodingStructure = structure.v_pedestals
    s = lp[offset / 2]

    is_dead_column_is_noisy_column[1] = ((s.ped & 0xFF) == structure._dead_flag)
    is_dead_column_is_noisy_column[2] = ((s.ped & 0xFF) == structure._noisy_flag)

    return tuple{decode_ped(structure, s.ped & 0xFF), decode_gain(structure, s.gain & 0xFF)}
end

decode_gain(structure::SiPixelGainForHLTonGPU, gain) = gain * structure.gain_precision + structure._min_gain
decode_ped(structure::SiPixelGainForHLTonGPU, ped) = ped * structure.ped_precision + structure._min_ped

end # module condFormatsSiPixelObjectsSiPixelGainForHLTonGPU
