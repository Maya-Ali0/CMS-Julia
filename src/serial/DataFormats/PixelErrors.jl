include("SiPixelRawDataError.jl")
using .Main.DataFormats_SiPixelRawDataError_h

module DataFormats_SiPixelDigi_interface_PixelErrors_h

    struct PixelErrorCompact
        rawId::UInt32
        word::UInt32
        errorType::UInt8
        fedId::UInt8
    end

    PixelFormatterErrors = Dict{UInt32, Vector{Main.DataFormats_SiPixelRawDataError_h.SiPixelRawDataError}}

end # module
