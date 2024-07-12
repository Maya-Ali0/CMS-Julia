using .CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA:SiPixelClustersSoA

using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA:SiPixelDigisSoA

using .cudaDataFormatsSiPixelDigiInterfaceSiPixelDigiErrorsSoA:SiPixelDigiErrorsSoA

using .CalibTrackerSiPixelESProducersInterfaceSiPixelGainCalibrationForHLTGPU

using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper

using .condFormatsSiPixelFedIds

using .dataFormats:FedRawData,FedRawDataCollection

using .errorChecker

using .pixelGPUDetails: SiPixelRawToClusterGPUKernel, WordFedAppender

using .DataFormatsSiPixelDigiInterfacePixelErrors: PixelErrorCompact, PixelFormatterErrors

import .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper.get_cpu_product

mutable struct SiPixelRawToClusterCUDA
    gpu_algo::SiPixelRawToClusterGPUKernel
    word_fed_appender::WordFedAppender
    errors::PixelFormatterErrors
    is_run2::Bool
    include_errors::Bool
    use_quality::Bool
    function SiPixelRawToClusterCUDA()
        is_run2 = true
        include_errors = true
        use_quality = true
        word_fed_appender = WordFedAppender()
        errors = PixelFormatterErrors()
        new(
            SiPixelRawToClusterGPUKernel(),
            word_fed_appender, errors, is_run2, include_errors, use_quality)
    end
end


function produce(self:: SiPixelRawToClusterCUDA,event::FedRawDataCollection, iSetup::EventSetup)
    hgpu_map = get(iSetup,SiPixelFedCablingMapGPUWrapper)   
    # if(has_quality(hgpu_map) != self.use_quality)
    #     error_message = "use_quality of the module ($self.use_quality) differs from SiPixelFedCablingMapGPUWrapper. Please fix your configuration."
    #     error(error_message)
    # end
    gpu_map = get_cpu_product(hgpu_map)
    gpu_modules_to_unpack::Vector{UInt8} = get_mod_to_unp_all(hgpu_map)

    hgains = get(iSetup,SiPixelGainCalibrationForHLTGPU)
    gpu_gains = CalibTrackerSiPixelESProducersInterfaceSiPixelGainCalibrationForHLTGPU.get_cpu_product(hgains)
    fed_ids::Vector{UInt} = fedIds(iSetup[SiPixelFedIds]) #fedIds
    buffers::FedRawDataCollection = event #fedData
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
        intializeWordFed(word_fed_appender,fed_id, word_counter_gpu, num_word32)
        wordCounterGPU += num_word32
    end
    makeClusters(gpu_algo,is_run2,
                        gpuMap, 
                        gpuModulesToUnpack, 
                        gpu_gains, 
                        self._word_fed_appender, 
                        self._errors, 
                        word_counter_gpu, # number of 32 bit words
                        fed_counter, # number of feds
                        self._use_quality, 
                        self.include_errors, 
                        false) #make clusters

    tmp = getResults(self.gpu_algo) # return pair of digis and clusters
end

end  # module SiPixelRawToClusterCUDA
