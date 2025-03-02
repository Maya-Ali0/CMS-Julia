module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel


module gpuCalibPixel

using ...condFormatsSiPixelObjectsSiPixelGainForHLTonGPU: SiPixelGainForHLTonGPU, get_ped_and_gain

# using ...gpuConfig

using ...CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using StaticArrays: MVector
using ...Printf
using CUDA
export calib_digis

# using Pkg
# Pkg.add("StaticArrays")
# using StaticArrays

const inv_id = 9999 # must be > MaxNumModules

# valid for run 2
const v_calto_electron_gain::Float32 = 47          # L2-4: 47 +- 4.7
const v_calto_electron_gain_L1::Float32 = 50       # L1:   49.6 +- 2.6
const v_calto_electron_offset::Float32 = -60       # L2-4: -60 +- 130
const v_calto_electron_offset_L1::Float32 = -670   # L1: -670 +- 200

function calib_digis(is_run_2::Bool, id::T, x::T, y::T, adc::T, ped::SiPixelGainForHLTonGPU, num_elements::Integer, module_start::U, n_clusters_in_module::U, clus_module_start::U) where {T <: AbstractVector{UInt16},U <: AbstractVector{UInt32}}
    first = blockDim().x*(blockIdx().x -1) + threadIdx().x
    stride = blockDim().x*gridDim().x
    # zero for next kernels
    if first == 1
        clus_module_start[1] = 0
        module_start[1] = 0
    end
   
    # for i ∈ 1:stride:MAX_NUM_MODULES
    #     # n_clusters_in_module[i] = 0
    # end
    @cuprintln(MAX_NUM_MODULES)
    @cuprintln(MAX_NUM_MODULES)
    @cuprintln(MAX_NUM_MODULES)
    # @cuprintln(first)
    return
    # for i in first:stride:num_elements
    #     if inv_id == id[i]
    #         continue
    #     end

    #     conversion_factor = (is_run_2) ? (id[i] < 96 ? v_calto_electron_gain_L1 : v_calto_electron_gain) : 1.0
    #     offset = (is_run_2) ? (id[i] < 96 ? v_calto_electron_offset_L1 : v_calto_electron_offset) : 0.0

    #     is_dead_column_is_noisy_column = MVector(false, false)

    #     row = x[i]
    #     col = y[i]
    #     ret = get_ped_and_gain(ped, id[i], col, row, is_dead_column_is_noisy_column)
    #     pedestal = ret[1]
    #     gain = ret[2]
        
    #     if is_dead_column_is_noisy_column[1] || is_dead_column_is_noisy_column[2]
    #         id[i] = inv_id
    #         adc[i] = 0
    #         @cuprintln("bad pixel at $i in $(id[i])")
    #     else
    #         vcal = adc[i] * gain - pedestal * gain
    #         adc[i] = max(100, Int32(trunc(vcal * conversion_factor + offset)))

    #         # open("testttt.txt","a") do file
    #         #     write(file, "$(adc[i])\n")
    #         # end
            
    #     end
    # end
end

end # module gpuCalibPixel

using .gpuCalibPixel
export calib_digis

end # module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel