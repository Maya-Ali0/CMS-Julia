module DataFormats_SiPixelRawDataError_h

    """
    SiPixelRawDataError struct represents errors in SiPixel raw data processing.

    Fields:
      - errorWord32::UInt32: Error word (32-bit representation).
      - errorWord64::UInt64: Error word (64-bit representation).
      - errorType::Int: Type of error.
      - fedId::Int: FED ID associated with the error.
      - errorMessage::String: Human-readable error message.

    Constructors:
      - SiPixelRawDataError(errorWord32::UInt32, errorType::Int, fedId::Int): Creates an instance with 32-bit error word.
      - SiPixelRawDataError(errorWord64::UInt64, errorType::Int, fedId::Int): Creates an instance with 64-bit error word.

    """
    struct SiPixelRawDataError
        errorWord32::UInt32
        errorWord64::UInt64
        errorType::Int
        fedId::Int
        errorMessage::String
        
        function SiPixelRawDataError(errorWord32::UInt32, errorType::Int, fedId::Int)
            errorWord32 = errorWord32
            errorWord64 = 0
            errorType = errorType
            fedId = fedId
            errorMessage = setMessage(errorType)
            
            new(errorWord32, errorWord64, _errorType_, fedId, errorMessage)
        end
        
        function SiPixelRawDataError(errorWord64::UInt64, errorType::Int, fedId::Int)
            errorWord32 = 0
            errorWord64 = errorWord64
            errorType = errorType
            fedId = fedId
            errorMessage = setMessage(errorType)
            
            new(errorWord32, errorWord64, errorType, _fedId_, errorMessage)
        end
    end

    """
    setMessage(errorType::Int) -> String

    Returns a human-readable error message based on the error type.

    Inputs:
      - errorType::Int: Type of error.

    Output:
      - errorMessage::String: Error message corresponding to the error type.

    """
    function setMessage(errorType::Int)
        if errorType == 25
            return "Error: Disabled FED channel (ROC=25)"
        elseif errorType == 26
            return "Error: Gap word"
        elseif errorType == 27
            return "Error: Dummy word"
        elseif errorType == 28
            return "Error: FIFO nearly full"
        elseif errorType == 29
            return "Error: Timeout"
        elseif errorType == 30
            return "Error: Trailer"
        elseif errorType == 31
            return "Error: Event number mismatch"
        elseif errorType == 32
            return "Error: Invalid or missing header"
        elseif errorType == 33
            return "Error: Invalid or missing trailer"
        elseif errorType == 34
            return "Error: Size mismatch"
        elseif errorType == 35
            return "Error: Invalid channel"
        elseif errorType == 36
            return "Error: Invalid ROC number"
        elseif errorType == 37
            return "Error: Invalid dcol/pixel address"
        else
            return "Error: Unknown error type"
        end
    end

    """
    setWord32(self::SiPixelRawDataError, errorWord32::UInt32) -> nothing

    Sets the 32-bit error word in the SiPixelRawDataError struct.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.
      - errorWord32::UInt32: 32-bit error word to set.

    Output:
      - Nothing.

    """
    @inline setWord32(self::SiPixelRawDataError, errorWord32::UInt32) = self.errorWord32 = errorWord32
    

    """
    setWord64(self::SiPixelRawDataError, errorWord64::UInt64) -> nothing

    Sets the 64-bit error word in the SiPixelRawDataError struct.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.
      - errorWord64::UInt64: 64-bit error word to set.

    Output:
      - Nothing.
    """
    @inline setWord64(self::SiPixelRawDataError, errorWord64::UInt64) = self.errorWord64 = errorWord64

    """
    setType(self::SiPixelRawDataError, errorType::Int) -> nothing

    Sets the error type and updates the error message in the SiPixelRawDataError struct.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.
      - errorType::Int: Error type to set.

    Output:
      - Nothing.
    """
    @inline function setType(self::SiPixelRawDataError, errorType::Int)
        self.errorType = errorType
        self.errorMessage = setMessage(errorType)
    end

    """
    setFedId(self::SiPixelRawDataError, fedId::Int) -> nothing

    Sets the FED ID in the SiPixelRawDataError struct.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.
      - fedId::Int: FED ID to set.

    Output:
      - Nothing.

    """
    @inline setFedId(self::SiPixelRawDataError, fedId::Int) = self.fedId = fedId
    """
    getMessage(self::SiPixelRawDataError) -> String

    Returns the error message associated with the SiPixelRawDataError instance.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.

    Output:
      - errorMessage::String: Error message associated with the instance.

    """
    getMessage(self::SiPixelRawDataError) = return self.errorMessage

    """
    getWord32(self::SiPixelRawDataError) -> UInt32

    Returns the 32-bit error word from the SiPixelRawDataError instance.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.

    Output:
      - errorWord32::UInt32: 32-bit error word.

    """
    @inline function getWord32(self::SiPixelRawDataError)::UInt32
        return self.errorWord32
    end

    """
    getWord64(self::SiPixelRawDataError) -> UInt64

    Returns the 64-bit error word from the SiPixelRawDataError instance.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.

    Output:
      - errorWord64::UInt64: 64-bit error word.

    """
    @inline function getWord64(self::SiPixelRawDataError)::UInt64
        return self.errorWord64
    end

    """
    getType(self::SiPixelRawDataError) -> Int

    Returns the error type from the SiPixelRawDataError instance.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.

    Output:
      - errorType::Int: Error type.

    """
    @inline function getType(self::SiPixelRawDataError)::Int
        return self.errorType
    end

    """
    getFedId(self::SiPixelRawDataError) -> Int

    Returns the FED ID from the SiPixelRawDataError instance.

    Inputs:
      - self::SiPixelRawDataError: Instance of SiPixelRawDataError.

    Output:
      - fedId::Int: FED ID.

    """
    @inline function getFedId(self::SiPixelRawDataError)::Int
        return self.fedId
    end

    """
    Custom comparison function for SiPixelRawDataError instances.

    Inputs:
      - one::SiPixelRawDataError: First instance for comparison.
      - other::SiPixelRawDataError: Second instance for comparison.

    Output:
      - Bool: Returns true if the FED ID of `one` is less than `other`.
    """
    
    import Base: isless

    @inline isless(one::SiPixelRawDataError, other::SiPixelRawDataError) = one.getFedId() < other.getFedId()

end # module
