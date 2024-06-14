module DataFormats_SiPixelDigi_interface_PixelErrors_h

struct PixelErrorCompact
    rawId:: UInt32
    word::UInt32
    errorType::UInt8
    fedId:: UInt8
end 

# using PixelFormatterErrors = std::map<uint32_t, std::vector<SiPixelRawDataError>>;
const PixelFormatterErrors = Dict{UInt32, Vector{SiPixelRawDataError}}

end