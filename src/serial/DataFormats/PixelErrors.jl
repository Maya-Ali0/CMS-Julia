include("SiPixelRawDataError.jl")
using .Main.DataFormats_SiPixelRawDataError_h

module DataFormats_SiPixelDigi_interface_PixelErrors_h

    """
    Definition of PixelErrorCompact struct representing compact pixel error information.

    Fields:
      - rawId::UInt32: Raw ID associated with the error.
      - word::UInt32: Word representing error details.
      - errorType::UInt8: Type of error.
      - fedId::UInt8: FED ID associated with the error.
    """
    struct PixelErrorCompact
        rawId::UInt32
        word::UInt32
        errorType::UInt8
        fedId::UInt8
    end

    """
    PixelFormatterErrors is a dictionary storing pixel formatter errors.

    Key Type: UInt32
    Value Type: Vector{Main.DataFormats_SiPixelRawDataError_h.SiPixelRawDataError}

    """
    PixelFormatterErrors = Dict{UInt32, Vector{(Main.DataFormats_SiPixelRawDataError_h).SiPixelRawDataError}}

end # module
