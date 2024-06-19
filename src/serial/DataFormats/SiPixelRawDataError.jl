module DataFormats_SiPixelRawDataError_h

    struct SiPixelRawDataError
        _errorWord32_::UInt32
        _errorWord64_::UInt64
        _errorType_::Int
        _fedId_::Int
        _errorMessage_::String
        
        function SiPixelRawDataError(errorWord32::UInt32, errorType::Int, fedId::Int)
            _errorWord32_ = errorWord32
            _errorWord64_ = 0
            _errorType_ = errorType
            _fedId_ = fedId
            _errorMessage_ = setMessage(_errorType_)
            
            new(_errorWord32_, _errorWord64_, _errorType_, _fedId_, _errorMessage_)
        end
        
        function SiPixelRawDataError(errorWord64::UInt64, errorType::Int, fedId::Int)
            _errorWord32_ = 0
            _errorWord64_ = errorWord64
            _errorType_ = errorType
            _fedId_ = fedId
            _errorMessage_ = setMessage(_errorType_)
            
            new(_errorWord32_, _errorWord64_, _errorType_, _fedId_, _errorMessage_)
        end
    end

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

    function setWord32(self::SiPixelRawDataError, errorWord32::UInt32)
        self._errorWord32_ = errorWord32
    end

    function setWord64(self::SiPixelRawDataError, errorWord64::UInt64)
        self._errorWord64_ = errorWord64
    end

    function setType(self::SiPixelRawDataError, errorType::Int)
        self._errorType_ = errorType
        self._errorMessage_ = setMessage(errorType)
    end

    function setFedId(self::SiPixelRawDataError, fedId::Int)
        self._fedId_ = fedId
    end

    function getMessage(self::SiPixelRawDataError)
        return self._errorMessage_
    end

    @inline function getWord32(self::SiPixelRawDataError)::UInt32
        return self._errorWord32_
    end

    @inline function getWord64(self::SiPixelRawDataError)::UInt64
        return self._errorWord64_
    end

    @inline function getType(self::SiPixelRawDataError)::Int
        return self._errorType_
    end

    @inline function getFedId(self::SiPixelRawDataError)::Int
        return self._fedId_
    end

    import Base: isless

    isless(one::SiPixelRawDataError, other::SiPixelRawDataError) = one.getFedId() < other.getFedId()

end # module
