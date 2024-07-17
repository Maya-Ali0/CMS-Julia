module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel


module gpuCalibPixel

using ...condFormatsSiPixelObjectsSiPixelGainForHLTonGPU: SiPixelGainForHLTonGPU, get_ped_and_gain

using ...gpuConfig

using ...CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using StaticArrays: MVector

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

function calib_digis(is_run_2::Bool, id, x, y, adc, ped::SiPixelGainForHLTonGPU, num_elements::Integer, module_start, n_clusters_in_module, clus_module_start)
    first = 0
    
    # zero for next kernels
    if first == 0
        clus_module_start[1] = 0
        module_start[1] = 0
    end

    for i in 1:MAX_NUM_MODULES
        n_clusters_in_module[i] = 0
    end

    for i in (first + 1):num_elements
        if inv_id == id[i]
            continue
        end

        conversion_factor = (is_run_2) ? (id[i] < 96 ? v_calto_electron_gain_L1 : v_calto_electron_gain) : 1.0
        offset = (is_run_2) ? (id[i] < 96 ? v_calto_electron_offset_L1 : v_calto_electron_offset) : 0.0

        is_dead_column_is_noisy_column = MVector(false, false)

        row = x[i]
        col = y[i]
        ret = get_ped_and_gain(ped, id[i], col, row, is_dead_column_is_noisy_column)
        pedestal = ret[1]
        gain = ret[2]
        open("pedAndFed.txt","a") do file
            write(file,string(pedestal)," ",string(gain),'\n')
        end
        # float pedestal = 0, float gain = 1
        if is_dead_column_is_noisy_column[1] || is_dead_column_is_noisy_column[2]
            id[i] = inv_id
            adc[i] = 0
            println("bad pixel at $i in $(id[i])")
        else
            vcal = (adc[i] - pedestal) * gain
            adc[i] = max(100, floor(Int, vcal * conversion_factor + offset))
        end
    end
end

end # module gpuCalibPixel

using .gpuCalibPixel
export calib_digis

end # module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel