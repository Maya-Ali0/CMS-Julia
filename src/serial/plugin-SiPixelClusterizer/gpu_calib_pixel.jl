module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel

include("../CondFormats/si_pixel_gain_for_hlt_on_gpu.jl")
using .condFormatsSiPixelObjectsSiPixelGainForHLTonGPU: siPixelGainForHLTonGPU, get_ped_and_gain

include("../CUDACore/cuda_assert.jl")
using .gpuConfig

include("gpu_clustering_constants.jl")
using .recoLocalTrackerSiPixelClusterizePluginsGPUClusteringConstants

using Pkg
Pkg.add("StaticArrays")
using StaticArrays

module gpuCalibPixel

const InvId::UInt16 = 9999 # must be > MaxNumModules

# valid for run 2
const VCaltoElectronGain::Float32 = 47          # L2-4: 47 +- 4.7
const VCaltoElectronGain_L1::Float32 = 50       # L1:   49.6 +- 2.6
const VCaltoElectronOffset::Float32 = -60       # L2-4: -60 +- 130
const VCaltoElectronOffset_L1::Float32 = -670   # L1: -670 +- 200

function calib_digis(is_run_2::Bool, id::Vector{UInt16}, x::UInt16, y::UInt16, adc::Vector{UInt16}, ped::siPixelGainForHLTonGPU, num_elements::Int, module_start::Vector{UInt32}, n_clusters_in_module::Vector{UInt32}, clus_module_start::Vector{UInt32})
    first::Int = 0
    
    # zero for next kernels
    if first == 0
        clus_module_start[0] = 0
        module_start[0] = 0
    end

    for i in first:num_elements
        n_clusters_in_module[i] = 0
    end

    for i in first:num_elements
        if InvId == id[i]
            continue
        end

        conversion_factor::Float32 = (is_run_2) ? (id[i] < 96 ? VCaltoElectronGain_L1 : VCaltoElectronGain) : 1.0f0
        offset::Float32 = (is_run_2) ? (id[i] < 96 ? VCaltoElectronOffset_L1 : VCaltoElectronOffset) : 0.0f0

        is_dead_column::Bool = false
        is_noisy_column::Bool = false

        row::UInt16 = x[i]
        col::UInt16 = y[i]
        ret::Tuple{Float32, Float32} = get_ped_and_gain(ped, id[i], col, row, MVector(is_dead_column, is_noisy_column))
        pedestal::Float32 = ret[1]
        gain::Float32 = ret[2]

        # float pedestal = 0, float gain = 1
        if is_dead_column || is_noisy_column
            id[i] = InvId
            adc[i] = 0
            println("bad pixel at $i in $(id[i])")
        else
            vcal::Float32 = (adc[i] - pedestal) * gain
            adc[i] = max(100, floor(vcal * conversion_factor + offset))
        end
    end
end

end # module gpuCalibPixel

end # module recoLocalTrackerSiPixelClusterizerPluginsGPUCalibPixel