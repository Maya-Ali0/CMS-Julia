module DataFormats
    export FEDRawData, FEDRawDataCollection
    """
    FEDNumbering 
    """
    const MINSiPixeluTCAFEDID = 1200
    const MAXSiPixeluTCAFEDID = 1349
    const MAXFEDID = 4096
    function inrange(fedID::Int)
        if fedID >= MINSiPixeluTCAFEDID && fedID <= MAXSiPixeluTCAFEDID
            return true 
        end
        return false 
    end
    mutable struct FEDRawData
        data::Vector{UInt8} 
        """
        Constructor specifying the size to be preallocated, in bytes.
        It is required that the size is a multiple of the size of a word (8 bytes).
        """
        function FEDRawData(newsize::Int)
            if newsize % 8 != 0
                throw(ArgumentError("FEDRawData: newsize $newsize is not a multiple of 8 bytes."))
            end
            new(Vector{UInt8}(undef, newsize))
        end
        """
        Copy constructor.
        """
        function FEDRawData(in::FEDRawData)
            new(copy(in.data))
        end
    end
    """
    Return the data buffer
    """
    function data(self::FEDRawData)::Vector{UInt8}
        return self.data
    end
    """
    Length of the data buffer in bytes.
    """
    function size(self::FEDRawData)::Int
        return length(self.data)
    end
    """
    Resize to the specified size in bytes. It is required that the size is a multiple of the size of a FED word (8 bytes).
    """
    function resize(self::FEDRawData, newsize::Int)
        if newsize % 8 != 0
            throw(ArgumentError("FEDRawData::resize: newsize $newsize is not a multiple of 8 bytes."))
        end
        resize!(self.data, newsize)
    end
    mutable struct FEDRawDataCollection
        data::Vector{FEDRawData}  # Vector of FEDRawData
        """
        Copy constructor.
        """
        function FEDRawDataCollection(in::FEDRawDataCollection)
            new(copy(in.data))
        end
    end

    """
    Swap function for FEDRawDataCollection.
    """
    function swap(a::FEDRawDataCollection, b::FEDRawDataCollection)
        a.data, b.data = b.data, a.data
    end
    """ 
    function for getting FEDRawData
    """
    function FEDData(fedid :: Int)
        return data[fedid]
    end

    
    mutable struct SiPixelRawDataError
        errorWord32::UInt32
        errorWord64::UInt64
        errorType::Int
        fedId::Int
        errorMessage::String
        """
        Constructor for 32-bit error word
        """
        
        function SiPixelRawDataError(errorWord32::UInt32, errorType::Int, fedId::Int)
            new(errorWord32, UInt64(0), errorType, fedId, "")
        end
        """
        Constructor with 64-bit error word and type included (header or trailer word)
        """
        
        function SiPixelRawDataError(errorWord64::UInt64, errorType::Int, fedId::Int)
            new(UInt32(0), errorWord64, errorType, fedId, "")
        end
    end
    function setType!(error::SiPixelRawDataError, errorType::Int)
        error.errorType = errorType
        setMessage!(error)
    end
    function setFedId!(error::SiPixelRawDataError, fedId::Int)
        error.fedId = fedId
    end
    function setMessage!(error::SiPixelRawDataError)
        error.errorMessage = errorTypeMessage(error.errorType)
    end
    function errorTypeMessage(errorType::Int)::String
        return Dict(
            25 => "Error: Disabled FED channel (ROC=25)",
            26 => "Error: Gap word",
            27 => "Error: Dummy word",
            28 => "Error: FIFO nearly full",
            29 => "Error: Timeout",
            30 => "Error: Trailer",
            31 => "Error: Event number mismatch",
            32 => "Error: Invalid or missing header",
            33 => "Error: Invalid or missing trailer",
            34 => "Error: Size mismatch",
            35 => "Error: Invalid channel",
            36 => "Error: Invalid ROC number",
            37 => "Error: Invalid dcol/pixel address",
        )[errorType, "Error: Unknown error type"]
    end

    struct PixelErrorCompact
        rawId::UInt32
        word::UInt32
        errorType::UInt8
        fedId::UInt8
    end
    """
        PixelFormatterErrors
    
    A dictionary mapping ints to lists of SiPixelRawDataError objects.
    """
    const PixelFormatterErrors = Dict{UInt32, Vector{SiPixelRawDataError}}()
end # module DataFormats