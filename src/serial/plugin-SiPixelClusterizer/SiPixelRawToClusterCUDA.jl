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

include("../DataFormats/FEDNumbering.jl")
using .DataFormats_FEDNumbering_h

include("../DataFormats/FEDRawData.jl")
using .DataFormats_FEDRawData_h

include("../DataFormats/FEDRawDataCollection.jl")
using .DataFormats_FEDRawDataCollection_h

include("../Framework/EventSetup.jl")
using .Framework_EventSetup_h

include("../Framework/Event.jl")
using .Framework_Event_h

include("../Framework/PluginFactory.jl")
using .Framework_PluginFactory_h

include("../Framework/EDProducer.jl")
using .Framework_EDProducer_h

include("ErrorChecker.jl")
using .ErrorChecker_H

include("SiPixelRawToClusterGPUKernel.jl")
using .SiPixelRawToClusterGPUKernel_h

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
        raw_get_token = reg.consumes{FedRawDataCollection}()
        digi_put_token = reg.produces{SiPixelDigisSoA}()
        cluster_put_token = reg.produces{SiPixelClustersSoA}()
        is_run2 = true
        include_errors = true
        use_quality = true
        digi_error_put_token = _include_errors ? reg.produces{SiPixelDigiErrorsSoA}() : nothing
        word_fed_appender = Ref(pixelgpudetails.word_fed_appender())
        new(raw_get_token, digi_put_token, digi_error_put_token, cluster_put_token,
            pixelgpudetails.SiPixelRawToClusterGPUKernel(), word_fed_appender,
            PixelFormatterErrors(), is_run2, include_errors, use_quality)
    end
end


function produce(self:: SiPixelRawToClusterCUDA, iEvent::edm.Event, iSetup::edm.EventSetup)
    hgpuMap = iSetup.get{SiPixelFedCablingMapGPUWrapper}()
    if(hgpuMap.hasQuality() != self._use_quality)
        error_message = "use_quality of the module ($_use_quality) differs from SiPixelFedCablingMapGPUWrapper. Please fix your configuration."
        throw(RuntimeError(error_message))
    end
    hgains = hgpuMap.getCPUProduct()
    gpuModulesToUnpack::ptr(Char)
    gpuModulesToUnpack = hgpuMap.getModToUnpAll()

    hgains = iSetup.get{SiPixelGainCalibrationForHLTGPU}()
    gpuGains = hgain.getCPUProduct()
    fedIds = iSetup.get(self.raw_get_token)
    self._errors.clear()

    wordCounterGPU :: Int
    fedCounter:: Int
    errorsInEvent:: Bool

    wordCounterGPU = 0
    fedCounter = 0
    errorsInEvent = false

    errorcheck::ErrorChecker
    for fedId in fedIds
       if(fedId == 40)
        continue

        @assert(fedId >= 1200)
        fedCounter++
        
        rawData:: FEDRawData 
        rawData = buffers.FEDData(fedId)

        nWords = rawData.size()/ sizeof(Int64)
        if(nWords == 0)
            continue
        end

        trailer = rawData.data() + (nWords - 1)
        if (! errorcheck.checkCRC(errorsInEvent, fedId, trailer, self._errors))
            continue
        end 

        header = rawData.data()
        header = header - 1

        moreHeaders = true
        while (moreHeaders){
            header++
            headerStatus =  errorcheck.checkHeader(errorsInEvent, fedId, header, self._errors)
            moreHeaders = headerStatus
        }
        end

        moreTrailer = true
        trailer++
        
        while (moreTrailer)
            trailer = trailer - 1
            trailerStatus = errorcheck.checkTrailer(errorsInEvent, fedId, nWords, trailer, _errors)
            moreTrailer = trailerStatus
        end 
        
        bw = header + 1
        ew = trailer

        @assert (0 == (ew - bw)% 2)
        self._word_fed_appender -> intializeWordFed(fedId, wordCounterGPU, bw, (ew - bw))
        wordCounterGPU += ew - bw
    end
    _gpuAlgo.makeClusters(is_run2,
                        gpuMap, 
                        gpuModulesToUnpack, 
                        gpuGains, 
                        ptr(self._word_fed_appender), 
                        move(self._errors), 
                        wordCounterGPU, 
                        fedCounter, 
                        self._use_quality, 
                        self.include_errors, 
                        false)
    tmp = self._gpuAlgo.getResults()
    iEvent.emplace(self.digi_put_token, move(tmp.first))
    iEvent.emplace(self.cluster_put_token, move(tmp.second))
    if(self.include_errors)    
        iEvent.emplace(self._digi_error_put_token, self._gpuAlgo.getErrors())
    end
end

end  # module SiPixelRawToClusterCUDA
