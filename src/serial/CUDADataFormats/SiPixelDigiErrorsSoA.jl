module CUDADataFormats_SiPixelDigi_interface_SiPixelDigiErrorsSoA_h

struct SiPixelDigiErrorsSoA
#     std::unique_ptr<PixelErrorCompact[]> data_d;
#   std::unique_ptr<cms::cuda::SimpleVector<PixelErrorCompact>> error_d;
#   PixelFormatterErrors formatterErrors_h;
    _data_d::ptr(Vector{PixelErrorCompact})
    _error_d::ptr(Vector{PixelErrorCompact})
    _formatterErrors_h:: PixelFormatterErrors
    
    function SiPixerDigiErrorsSoA(maxFedWords::size_t, errors::PixelFormatterErrors)
         data_d = Vector{PixelErrorCompact}(undef, maxFedWords)
         fill!(data_d, PixelErrorCompact()) # Zero-initialize
         
         error_d = Vector{PixelErrorCompact}(undef, maxFedWords)
         fill!(error_d, PixelErrorCompact())
         
         # set pointers
         data_d_ptr = Base.unsafe_convert(Ptr{Vector{PixelErrorCompact}}, Ref(data_d))
         error_d_ptr = Base.unsafe_convert(Ptr{Vector{PixelErrorCompact}}, Ref(error_d))

         @assert isempty(data_d)
         @assert length(data_d) == maxFedWords
 
         new(data_d_ptr, error_d_ptr, errors)
    end
end

#copy constructor already deleted because struct is immutable

function formatterErrors(self::SiPixelDigiErrorsSoA):: PixelFormatterErrors
    return self._formatterErrors_h
end

# cms::cuda::SimpleVector<PixelErrorCompact>* error() { return error_d.get(); }
# cms::cuda::SimpleVector<PixelErrorCompact> const* error() const { return error_d.get(); }
# cms::cuda::SimpleVector<PixelErrorCompact> const* c_error() const { return error_d.get(); }

function error(self::SiPixelDigiErrorsSoA):: ptr(Vector{PixelErrorCompact})
    return self._error_d
end


end