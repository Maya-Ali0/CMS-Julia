module ErrorChecker_H
include("DataFormats\SiPixelRawDataError.jl")
include("Constants.jl")

using .DataFormats_SiPixelRawDataError_h: SiPixelRawDataError
using .constants


struct ErrorChecker 
    const Word32 = UInt32
    const Word64 =  UInt64
    const DetErrors = vector{SiPixelRawDataError}
    const Errors = Dict{UInt32, DetErrors}()
    _includeErrors::Bool

    function ErrorChecker()
        _includeErrors = false
    end
end

function checkCRC(self::ErrorChecker, errorsInEvent::Bool, fedId::Int, trailer::ptr(Word64), errors::Errors)::Bool
    CRC_BIT::Int 
    CRC_BIT = (Word64 >> CRC_shift) & CRC_mask
    if (CRC_BIT == 0)
        return true
    errorsInEvent = true
    if(_includeErrors)
        error = SiPixelRawDataError(trailer, 39, fedId)
        if haskey(errors, dummyDetId)
            push!(errors[dummyDetId], error)
        else
            return "exception" #will fic later
    end 
    return false
end


end

function checkHeader(self::ErrorChecker, errorsInEvent::Bool, fedId::Int, trailer::ptr(Word64), errors::Errors)::Bool
    header_ptr = reinterpret(Ptr{UInt8}, header)
    fedHeader = createFEDHeader(header_ptr)
    if(!fedHeader.check())
        return false
    end 
    if(fedHeader.sourceID() != fedId)
        println("PixelDataFormatter::interpretRawData, fedHeader.sourceID() != fedId, sourceID = $(fedHeader.sourceID()), fedId = $fedId, errorType = 32")
        errorsInEvent = true
        if(_includeErrors)
            error = SiPixelRawDataError(trailer, 39, fedId)
            if haskey(errors, dummyDetId)
                push!(errors[dummyDetId], error)
            else
                return "exception" #will fic later
        end 
    end
    return fedHeader.moreHeaders()
end 


function createFEDHeader(header::Ptr{UInt8})
    data = Vector{UInt8}()
    ptr = header
    while ptr[]
        push!(data, ptr[])
        ptr += 1
    end
    return FEDHeader(data)
end
function checkTrailer(self::ErrorChecker, errorsInEvent::Bool, fedId::Int, nWords::UInt, trailer::ptr(Word64), errors::Errors)::Bool
    trailer_ptr = reinterpret(Ptr{UInt8}, trailer)
    fedTrailer = createFEDHeader(trailer_ptr)
    if (!fedTrailer.check())
        if(_includeErrors)
            error = SiPixelRawDataError(trailer, 39, fedId)
            if haskey(errors, dummyDetId)
                push!(errors[dummyDetId], error)
            else
                return "exception" #will fix later
            end
        end
        errorsInEvent = true
        println("fedTrailer.check failed, Fed: $fedId , errorType = 33")
        return false
    end
    if (fedTrailer.fragmentLength() != nWords)
        println("fedTrailer.fragmentLength()!= nWords !! Fed: $fedId  errorType = 34")
        errorsInEvent = true
        if (_includeErrors)
            error = SiPixelRawDataError(trailer, 39, fedId)
            if haskey(errors, dummyDetId)
                push!(errors[dummyDetId], error)
            else
                return "exception" #will fix later
            end
        end
        return fedTrailer.moreTrailers();
    end
end
function createFEDTrailer(trailer::Ptr{UInt8})
    data = Vector{UInt8}()
    ptr = trailer
    while ptr[]
        push!(data, ptr[])
        ptr += 1
    end
    return FEDTrailer(data)
end


end
end
end