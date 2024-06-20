include("../CUDADataFormats/SiPixelClusterSoA.jl")
using .CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA

include("../CUDADataFormats/SiPixelDigisSoA.jl")
using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA

include("../CUDADataFormats/SiPixelDigiErrorsSoA.jl")
using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigiErrorsSoA

include("../CondFormats/SiPixelGainCalibrationForHLTGPU.jl")
using .CalibTracker_SiPixelESProducers_interface_SiPixelGainCalibrationForHLTGPU_h

include("../CondFormats/SiPixelFedCablingMapGPUWrapper.jl")
using .RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPUWrapper_h

include("../CondFormats/SiPixelFedIds.jl")
using .CondFormats_SiPixelFedIds_h

include("../DataFormats/PixelErrors.jl")
using .DataFormats_SiPixelDigi_interface_PixelErrors_h

include("../DataFormats/data_formats.jl")
using .dataFormats

include("../Framework/EventSetup.jl")
using .edm

include("../Framework/Event.jl")
using .Framework_Event_h

include("../Framework/PluginFactory.jl")
using .Framework_PluginFactory_h

include("../Framework/EDProducer.jl")
using .Framework_EDProducer_h

include("ErrorChecker.jl")
using .errorChecker

include("SiPixelRawToClusterGPUKernel.jl")

struct SiPixelRawToClusterCUDA <: edm.EDProducer
    raw_get_token::edm.EDGetTokenT{FedRawDataCollection}
    digi_put_token::edm.EDPutTokenT{SiPixelDigisSoA}
    digi_error_put_token::Union{Nothing, edm.EDPutTokenT{SiPixelDigiErrorsSoA}}
    cluster_put_token::edm.EDPutTokenT{SiPixelClustersSoA}

    gpu_algo::pixelgpudetails.SiPixelRawToClusterGPUKernel
    word_fed_appender::Union{Nothing, Ref{pixelgpudetails.word_fed_appender}}
    errors::PixelFormatterErrors

    is_run2::Bool
    include_errors::Bool
    use_quality::Bool

    function SiPixelRawToClusterCUDA(reg::edm.ProductRegistry)
        raw_get_token = consumes{FedRawDataCollection}(reg)
        digi_put_token = produces{SiPixelDigisSoA}(reg)
        cluster_put_token = produces{SiPixelClustersSoA}(reg)
        is_run2 = true
        include_errors = true
        use_quality = true
        digi_error_put_token = include_errors ? produces{SiPixelDigiErrorsSoA}(reg) : nothing
        word_fed_appender = pixelgpudetails.word_fed_appender()
        new(raw_get_token, digi_put_token, digi_error_put_token, cluster_put_token,
            pixelgpudetails.SiPixelRawToClusterGPUKernel(), word_fed_appender,
            dataFormats.PixelFormatterErrors(), is_run2, include_errors, use_quality)
    end
end


function produce(self:: SiPixelRawToClusterCUDA, iEvent::edm.Event, iSetup::edm.EventSetup)
    hgpu_map = edm.get(iSetup,SiPixelFedCablingMapGPUWrapper)
    if(hasQuality(hgpuMap) != self._use_quality)
        error_message = "use_quality of the module ($_use_quality) differs from SiPixelFedCablingMapGPUWrapper. Please fix your configuration."
        throw(RuntimeError(error_message))
    end
    gpu_map = getCPUProduct(hgpu_map)
    gpu_modules_to_unpack::Vector{UInt8} = getModToUnpAll(hgpu_map)

    hgains = get(iSetup,SiPixelGainCalibrationForHLTGPU)
    gpu_gains = getCPUProduct(hgains)
    fed_ids::Vector{UInt} = fedIds(get(iSetup,SiPixelFedIds)) #fedIds
    buffers::FedRawDataCollection = get(iEvent,self.raw_get_token) #fedData
    clear(self.errors)

    # Data Extraction for Raw to Digi
    word_counter_gpu :: Int = 0 
    fed_counter:: Int = 0 
    errors_in_event:: Bool = false 
    error_check::errorChecker = ErrorChecker()

    for fed_id ∈ fed_ids

       if(fed_id == 40) # Skipping Pilot Blade Data
        continue

        @assert(fed_id >= 1200)
        fed_counter++
        
        # get event data for the following feds
        # Im using the fedId in fedIds to get the rawData of that fedId which is in buffers the FedRawDataCollection
        raw_data::FedRawData = FedData(buffers,fed_id) 
        n_words = size(raw_data)/ sizeof(Int64)
        if(n_words == 0)
            continue
        end
        trailer_byte_start = size(raw_data) - 7
        trailer::Vector{UInt8} = data(rawData)[trailer_byte_start:trailer_byte_start+7] # The last 8 bytes
        if (!checkCRC(error_check,errors_in_event, fed_id, trailer, self.errors))
            continue
        end 
        header_byte_start = 1 
        header::Vector{UInt8} = data(rawData)[header_byte_start:header_byte_start+7]

        moreHeaders = true
        while moreHeaders
            headerStatus =  checkHeader(error_check,errors_in_event, fed_id, header, self.errors)
            moreHeaders = headerStatus
            if moreHeaders
                header_byte_start += 8
                header = data(rawData)[header_byte_start:header_byte_start+7]
            end
        end

        moreTrailer = true
        while (moreTrailer)
            trailerStatus = errorcheck.checkTrailer(errorsInEvent, fedId, nWords, trailer, _errors)
            moreTrailer = trailerStatus
            if moreTrailer
                trailer_byte_start -= 8
                trailer = data(rawData)[trailer_byte_start:trailer_byte_start+7]
            end
        end 
        
        begin_word32_index = header_byte_start + 8
        end_word32_index = trailer_byte_start - 1 
        @assert((end_word32_index - begin_word32_index + 1) % 4 == 0)
        num_word32 = (end_word32_index - begin_word32_index + 1) ÷ sizeof(UInt32)
        @assert (0 == (ew - bw) % 2) # Number of 32 bit words should be a multiple of 2
        intializeWordFed(word_fed_appender,fed_id, word_counter_gpu, begin_word32_index, num_word32)
        wordCounterGPU += num_word32
    end
    makeClusters(gpu_algo,is_run2,
                        gpuMap, 
                        gpuModulesToUnpack, 
                        gpu_gains, 
                        self._word_fed_appender, 
                        self._errors, 
                        word_counter_gpu, 
                        fed_counter, 
                        self._use_quality, 
                        self.include_errors, 
                        false)
    tmp = getResults(self.gpu_algo)
    emplace(iEvent,self.digi_put_token, tmp.first)
    emplace(iEvent,self.cluster_put_token, tmp.second)
    if(self.include_errors)    
        emplace(iEvent,self._digi_error_put_token, self.gpu_algo.getErrors())
    end
end

end  # module SiPixelRawToClusterCUDA
