include("CUDADataFormats/SiPixelClusterSoA.jl")
using .CUDADataFormats_SiPixelCluster_interface_SiPixelClustersSoA_h

include("CUDADataFormats/SiPixelDigisSoA.jl")
using .CUDADataFormats_SiPixelDigi_interface_SiPixelDigisSoA_h

include("CUDADataFormats/SiPixelDigiErrorsSoA.jl")
using .CUDADataFormats_SiPixelDigi_interface_SiPixelDigiErrorsSoA_h

include("CondFormats/SiPixelGainCalibrationForHLTGPU.jl")
using .CalibTracker_SiPixelESProducers_interface_SiPixelGainCalibrationForHLTGPU_h

include("CondFormats/SiPixelFedCablingMapGPUWrapper.jl")
using .RecoLocalTracker_SiPixelClusterizer_SiPixelFedCablingMapGPUWrapper_h

include("CondFormats/SiPixelFedIds.jl")
using .CondFormats_SiPixelFedIds_h

include("DataFormats/PixelErrors.jl")
using .DataFormats_SiPixelDigi_interface_PixelErrors_h

include("DataFormats/FEDNumbering.jl")
using .DataFormats_FEDNumbering_h

include("DataFormats/FEDRawData.jl")
using .DataFormats_FEDRawData_h

include("DataFormats/FEDRawDataCollection.jl")
using .DataFormats_FEDRawDataCollection_h

include("Framework/EventSetup.jl")
using .Framework_EventSetup_h

include("Framework/Event.jl")
using .Framework_Event_h

include("Framework/PluginFactory.jl")
using .Framework_PluginFactory_h

include("Framework/EDProducer.jl")
using .Framework_EDProducer_h

include("ErrorChecker.jl")
using .ErrorChecker_H

include("SiPixelRawToClusterGPUKernel.jl")
using .SiPixelRawToClusterGPUKernel_h

module SiPixelRawToClusterCUDA

# Define the necessary modules and types
module edm
    abstract type EDProducer end

    struct EDGetTokenT{T}
        data::T
    end

    struct EDPutTokenT{T}
        data::T
    end

    struct ProductRegistry
        function consumes{T}()::EDGetTokenT{T}
            return EDGetTokenT{T}(nothing)
        end
        function produces{T}()::EDPutTokenT{T}
            return EDPutTokenT{T}(nothing)
        end
    end
end

module pixelgpudetails
    struct SiPixelRawToClusterGPUKernel end

    struct WordFedAppender end
end

struct PixelFormatterErrors end

struct FedRawDataCollection end
struct SiPixelDigisSoA end
struct SiPixelDigiErrorsSoA end
struct SiPixelClustersSoA end

struct SiPixelRawToClusterCUDA <: edm.EDProducer
    _rawGetToken::edm.EDGetTokenT{FedRawDataCollection}
    _digiPutToken::edm.EDPutTokenT{SiPixelDigisSoA}
    _digiErrorPutToken::Union{Nothing, edm.EDPutTokenT{SiPixelDigiErrorsSoA}}
    _clusterPutToken::edm.EDPutTokenT{SiPixelClustersSoA}

    _gpuAlgo::pixelgpudetails.SiPixelRawToClusterGPUKernel
    _wordFedAppender::Union{Nothing, Ref{pixelgpudetails.WordFedAppender}}
    _errors::PixelFormatterErrors

    _isRun2::Bool
    _includeErrors::Bool
    _useQuality::Bool

    function SiPixelRawToClusterCUDA(reg::edm.ProductRegistry)
        _rawGetToken = reg.consumes{FedRawDataCollection}()
        _digiPutToken = reg.produces{SiPixelDigisSoA}()
        _clusterPutToken = reg.produces{SiPixelClustersSoA}()
        _isRun2 = true
        _includeErrors = true
        _useQuality = true
        _digiErrorPutToken = _includeErrors ? reg.produces{SiPixelDigiErrorsSoA}() : nothing
        _wordFedAppender = Ref(pixelgpudetails.WordFedAppender())
        new(_rawGetToken, _digiPutToken, _digiErrorPutToken, _clusterPutToken,
            pixelgpudetails.SiPixelRawToClusterGPUKernel(), _wordFedAppender,
            PixelFormatterErrors(), _isRun2, _includeErrors, _useQuality)
    end
end


function produce(self:: SiPixelRawToClusterCUDA, iEvent::edm.Event, iSetup::edm.EventSetup)
    hgpuMap = iSetup.get{SiPixelFedCablingMapGPUWrapper}()
    if(hgpuMap.hasQuality() != self._useQuality)
        error_message = "UseQuality of the module ($_useQuality) differs from SiPixelFedCablingMapGPUWrapper. Please fix your configuration."
        throw(RuntimeError(error_message))
    end
    hgains = hgpuMap.getCPUProduct()
    gpuModulesToUnpack::ptr(Char)
    gpuModulesToUnpack = hgpuMap.getModToUnpAll()

    hgains = iSetup.get{SiPixelGainCalibrationForHLTGPU}()
    gpuGains = hgain.getCPUProduct()
    fedIds = iSetup.get(self._rawGetToken)
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
        self._wordFedAppender -> intializeWordFed(fedId, wordCounterGPU, bw, (ew - bw))
        wordCounterGPU += ew - bw
    end
    _gpuAlgo.makeClusters(_isRun2,
                        gpuMap, 
                        gpuModulesToUnpack, 
                        gpuGains, 
                        ptr(self._wordFedAppender), 
                        move(self._errors), 
                        wordCounterGPU, 
                        fedCounter, 
                        self._useQuality, 
                        self._includeErrors, 
                        false)
    tmp = self._gpuAlgo.getResults()
    iEvent.emplace(self._digiPutToken, move(tmp.first))
    iEvent.emplace(self._clusterPutToken, move(tmp.second))
    if(self._includeErrors)    
        iEvent.emplace(self._digiErrorPutToken, self._gpuAlgo.getErrors())
    end
end

end 


end # module SiPixelRawToClusterCUDA
