module ErrorChecker_H
    # Including necessary modules and files
    include("../DataFormats/SiPixelRawDataError.jl")
    include("Constants.jl")
    include("../DataFormats/fed_trailer.jl")
    include("../DataFormats/fed_header.jl")
    using .DataFormats_SiPixelRawDataError_h: SiPixelRawDataError
    using .constants

    # Type aliases for convenience
    const Word32 = UInt32
    const Word64 =  UInt64
    const DetErrors = Vector{SiPixelRawDataError}
    const Errors = Dict{UInt32, DetErrors}

    """
    ErrorChecker struct

    Represents an error checker object for validating FED data integrity.

    Fields:
    - _includeErrors::Bool: Flag indicating whether to include errors in analysis.

    Constructor:
    - ErrorChecker(): Constructs an ErrorChecker object with _includeErrors set to false.
    """

    struct ErrorChecker 
        _includeErrors::Bool
        function ErrorChecker()
            _includeErrors = false
        end
    end

    """
    check_crc function

    Checks CRC validity in a FED trailer.

    Arguments:
    - self::ErrorChecker: The ErrorChecker object.
    - errors_in_event::Bool: Indicates if errors are present in the event.
    - fed_id::Int: FED identifier.
    - trailer::Vector{UInt8}: Trailer data.
    - errors::Errors: Dictionary to store errors.

    Returns:
    - Bool: True if CRC is valid, false otherwise.
    """
    function check_crc(self::ErrorChecker, errors_in_event::Bool, fed_id::Int, trailer::Vector{UInt8}, errors::Errors)::Bool
        the_trailer = fedTrailer::FedTrailer(trailer)
        crc_bit::bool = fedTrailer::crc_modified(the_trailer)
        error_word::UInt64 = reinterpret(UInt64,trailer[1:8])
        if (crc_bit == false)
            return true
        end
        errors_in_event = true
        if(self._includeErrors)
            error = SiPixelRawDataError(error_word, 39, fed_id)
            push!(errors[dummyDetId], error)
        end 
        return false
    end

    """
    check_header function

    Checks header validity in a FED header.

    Arguments:
    - self::ErrorChecker: The ErrorChecker object.
    - errors_in_event::Bool: Indicates if errors are present in the event.
    - fed_id::Int: FED identifier.
    - header::Vector{UInt8}: Header data.
    - errors::Errors: Dictionary to store errors.

    Returns:
    - Bool: True if more headers follow, false otherwise.
    """
    function check_header(self::ErrorChecker, errors_in_event::Bool, fed_id::Int, header::Vector{UInt8}, errors::Errors)::Bool
        the_header = fedHeader::FedHeader(header)
        error_word::UInt64 = reinterpret(UInt64,header[1:8])
        if(!fedHeader::check(theHeader))
            return false
        end 
        source_id::UInt16 = fedHeader::source_id(theHeader)
        if( source_id != fed_id)
            println("PixelDataFormatter::interpretRawData, fedHeader.sourceID() != fedId, sourceID = ",sourceID, " fedId = ",fedId, "errorType = ",32)
            errorsInEvent = true
            if(self._includeErrors)
                error = SiPixelRawDataError(error_word, 39, fedId)
                push!(errors[dummyDetId], error)
            end 
        end
        return fedHeader::more_headers(the_header)
    end 

    """
    check_trailer function

    Checks trailer validity in a FED trailer.

    Arguments:
    - self::ErrorChecker: The ErrorChecker object.
    - errors_in_event::Bool: Indicates if errors are present in the event.
    - fed_id::Int: FED identifier.
    - num_words::UInt: Number of words.
    - trailer::Vector{UInt8}: Trailer data.
    - errors::Errors: Dictionary to store errors.

    Returns:
    - Bool: True if more trailers follow, false otherwise.
    """
    function check_trailer(self::ErrorChecker, errors_in_event::Bool, fed_id::Int, num_words::UInt, trailer::Vector{UInt8}, errors::Errors)::Bool
        the_trailer = fedTrailer::FedTrailer(trailer)
        error_word::UInt64 = reinterpret(UInt64,header[1:8])
        if (!fedTrailer::check(the_trailer))
            if(self._includeErrors)
                error = SiPixelRawDataError(trailer, 39, fed_id)
                push!(errors[dummyDetId], error)
            end
            errors_in_event = true
            println("fedTrailer.check failed, Fed:",fedId," errorType = ",33)
            return false
        end
        if (fedTrailer::fragment_length(the_trailer) != nWords)
            println("fedTrailer.fragmentLength()!= nWords !! Fed: ",fedId, " errorType = ",34)
            errors_in_event = true
            if (_includeErrors)
                error = SiPixelRawDataError(error_word, 39, fedId)
                push!(errors[dummyDetId], error)
            end
            return fedTrailer::more_trailers(the_trailer)
        end
    end
end