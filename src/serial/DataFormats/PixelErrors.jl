

module DataFormatsSiPixelDigiInterfacePixelErrors
  include("SiPixelRawDataError.jl")
  using .DataFormatsSiPixelRawDataError: SiPixelRawDataError 
  """
  Definition of PixelErrorCompact struct representing compact pixel error information.

  Fields:
    - rawId::UInt32: Raw ID associated with the error.
    - word::UInt32: Word representing error details.
    - errorType::UInt8: Type of error.
    - fedId::UInt8: FED ID associated with the error.
  """
  struct PixelErrorCompact
      raw_id::UInt32
      word::UInt32
      erro_type::UInt8
      fed_id::UInt8
  end

  """
  PixelFormatterErrors is a dictionary storing pixel formatter errors.

  Key Type: UInt32
  Value Type: Vector{Main.DataFormats_SiPixelRawDataError_h.SiPixelRawDataError}

  """
  PixelFormatterErrors = Dict{UInt32, Vector{SiPixelRawDataError}}

end # module
