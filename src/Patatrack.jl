module Patatrack
import Base.length
using Printf
using StaticArrays:MArray
export FED_SLINK_END_MARKER, FED_SLINK_ERROR_WIDTH, FED_TCTRLID_EXTRACT,
FED_EVSZ_EXTRACT, FED_CRCS_EXTRACT, FED_STAT_EXTRACT, FED_TTSI_EXTRACT,
FED_MORE_TRAILERS_EXTRACT, FED_CRC_MODIFIED_EXTRACT, FED_SLINK_ERROR_EXTRACT,
FED_WRONG_FEDID_EXTRACT

export FedRawDataCollection, FedRawData

export SiPixelFedCablingMapGPU
export MAX_SIZE , MAX_FED , MAX_ROC , MAX_SIZE, MAX_SIZE_BYTE_BOOL

export CRC_bits, LINK_bits, ROC_bits, DCOL_bits, PXID_bits, ADC_bits, OMIT_ERR_bits
export CRC_shift, ADC_shift, PXID_shift, DCOL_shift, ROC_shift, LINK_shift, OMIT_ERR_shift
export dummyDetId, CRC_mask, ERROR_mask, LINK_mask, ROC_mask, OMIT_ERR_mask

export LAYER_START_BIT, LADDER_START_BIT, MODULE_START_BIT, PANEL_START_BIT,
            DISK_START_BIT, BLADE_START_BIT, LAYER_MASK, LADDER_MASK,
            MODULE_MASK, PANEL_MASK, DISK_MASK, BLADE_MASK, LINK_BITS, ROC_BITS,
            DCOL_BITS, PXID_BITS, ADC_BITS, LINK_BITS_L1, ROC_BITS_L1,
            COL_BITS_L1, ROW_BITS_L1, OMIT_ERR_BITS, MAX_ROC_INDEX,
            NUM_ROWS_IN_ROC, NUM_COL_IN_ROC, MAX_WORD, ADC_SHIFT, PXID_SHIFT,
            DCOL_SHIFT, ROC_SHIFT, LINK_SHIFT, ROW_SHIFT, COL_SHIFT,
            OMIT_ERR_SHIFT, LINK_MASK, ROC_MASK, COL_MASK, ROW_MASK, DCOL_MASK,
            PXID_MASK, ADC_MASK, ERROR_MASK, OMIT_ERR_MASK, MAX_FED, MAX_LINK,
            MAX_FED_WORDS
export readall, readevent, readfed
export EventSetup
export SiPixelFedCablingMapGPUWrapperESProducer
export SiPixelGainCalibrationForHLTGPUESProducer
export produce
export SiPixelGainForHLTonGPU
export MAX_SIZE
export RANGE_COUNT
export RangeAndCols, DecodingStructure
export SiPixelRawToClusterCUDA
export MAX_NUM_MODULES
export PixelErrorCompact, PixelFormatterErrors
export has_quality, SiPixelFedCablingMapGPUWrapper
export get_cpu_product
export get_mod_to_unp_all
export fed_ids
export ErrorChecker
export make_clusters
export get_results
export FedData
export data
export check_crc
export FedHeader
export FedTrailer
export check
export check_trailer
export fragment_length, more_trailers
export initialize_word_fed
export calib_digis
export count_modules,find_clus
export HisToContainer
export MAX_NUM_CLUSTERS
export AverageGeometry
export ProductRegistry
export Event, EDPutTokenT, produces, emplace, begin_module_construction

export number_of_ladders_in_barrel

export local_x
export local_y
export is_big_pix_y
export is_big_pix_x

export  last_row_in_module
export  last_col_in_module

export x_offset
export y_offset

export BeamSpotPOD
export SOAFrame
export ParamsOnGPU
export position_corr

export errorFromDB

export PixelCPEFastESProducer
export BeamSpotESProducer
export BeamSpotToPOD
export SiPixelRecHitCUDA

export x_global
export y_global
export z_global

export set_x_global
export set_y_global
export set_z_global

export toGlobal_special

export CAHitNtuplet

#include("serial/bin/EventProcessor.jl")
#include("serial/bin/source.jl")
include("serial/CUDACore/vec_array.jl")
include("serial/CUDACore/simple_vector.jl")
include("serial/CondFormats/si_pixel_fed_cabling_map_gpu.jl")
include("serial/CondFormats/si_pixel_fed_cabling_map_gpu_wrapper.jl")
include("serial/CondFormats/si_pixel_fed_ids.jl")
include("serial/CUDACore/cuda_assert.jl")
include("serial/CondFormats/si_pixel_gain_for_hlt_on_gpu.jl")
include("serial/CondFormats/si_pixel_gain_calibration_for_hlt_gpu.jl")
include("serial/CUDACore/cudaCompat.jl")
include("serial/CUDACore/cudastdAlgorithm.jl")
include("serial/CUDACore/prefix_scan.jl")
include("serial/CUDACore/hist_to_container.jl")
include("serial/CUDADataFormats/gpu_clustering_constants.jl")
include("serial/CUDADataFormats/SiPixelClusterSoA.jl")
include("serial/DataFormats/SiPixelRawDataError.jl")
include("serial/DataFormats/PixelErrors.jl")
include("serial/CUDADataFormats/SiPixelDigiErrorsSoA.jl")
include("serial/CUDADataFormats/SiPixelDigisSoA.jl")
include("serial/DataFormats/data_formats.jl")
include("serial/DataFormats/fed_header.jl")
include("serial/DataFormats/fed_trailer.jl")
include("serial/Framework/EDTokens.jl")
include("serial/Framework/ProductRegistry.jl")
include("serial/Framework/EandES.jl")
include("serial/Framework/ESProducer.jl")
include("serial/Framework/EDProducer.jl")
include("serial/Geometry/phase1PixelTopology.jl")
include("serial/plugin-SiPixelClusterizer/adc_threshold.jl")
include("serial/plugin-SiPixelClusterizer/Constants.jl")
include("serial/plugin-SiPixelClusterizer/ErrorChecker.jl")
include("serial/plugin-SiPixelClusterizer/gpu_calib_pixel.jl")
include("serial/plugin-SiPixelClusterizer/gpu_cluster_charge_cut.jl")
include("serial/plugin-SiPixelClusterizer/gpu_clustering.jl")
include("serial/plugin-SiPixelClusterizer/SiPixelFedCablingMapGPUWrapperESProducer.jl")
include("serial/plugin-SiPixelClusterizer/SiPixelGainCalibrationForHLTGPUESProducer.jl")
include("serial/plugin-SiPixelClusterizer/SiPixelRawToClusterGPUKernel.jl")
include("serial/plugin-SiPixelClusterizer/SiPixelRawToClusterCUDA.jl")
# include("serial/plugin-SiPixelClusterizer/testClustering.jl")
include("serial/bin/ReadRAW.jl")
include("serial/DataFormats/BeamSpotPOD.jl")
include("serial/plugin-BeamSpotProducer/BeamSpotToPOD.jl")
include("serial/plugin-BeamSpotProducer/BeamSpotESProducer.jl")

# include("serial/CUDADataFormats/HeterogeneousSoA.jl")
include("serial/DataFormats/SOARotation.jl")


include("serial/CondFormats/pixelCPEforGPU.jl")

include("serial/CUDADataFormats/TrackingRecHit2DSOAView.jl")
include("serial/CUDADataFormats/TrackingRecHit2DHeterogeneous.jl")
include("serial/DataFormats/approx_atan2.jl")

include("serial/plugin-SiPixelRecHits/gpuPixelRecHits.jl")

include("serial/CondFormats/PixelCPEFast.jl")

include("serial/plugin-SiPixelRecHits/PixelCPEFastESProducer.jl")

include("serial/plugin-SiPixelRecHits/PixelRecHits.jl")
include("serial/plugin-SiPixelRecHits/SiPixelRecHitCUDA.jl")
include("serial/plugin-PixelTriplets/ca_constants.jl")
include("serial/plugin-PixelTriplets/fit_result.jl")
include("serial/plugin-PixelTriplets/gpu_ca_cell.jl")
include("serial/plugin-PixelTriplets/gpu_pixel_doublets.jl")
include("serial/plugin-PixelTriplets/ca_hit_ntuplet_generator_kernels.jl")
include("serial/plugin-PixelTriplets/ca_hit_ntuplet_generator.jl")
include("serial/plugin-PixelTriplets/ca_hit_ntuplet.jl")
#include("serial/plugin-PixelTriplets/helix_fit_on_gpu.jl")
end