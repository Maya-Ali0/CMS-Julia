include("../DataFormats/PixelErrors.jl")
using .DataFormats_SiPixelDigi_interface_PixelErrors_h

module CUDADataFormats_SiPixelDigi_interface_SiPixelDigiErrorsSoA_h

    # This module defines the data structure for storing SiPixel digi error data in a 
    # format suitable for CUDA operations. It includes structures and functions 
    # to manage and access the error data.

    # Struct to hold the error data in a CUDA-compatible structure.
    struct SiPixelDigiErrorsSoA
        error_d = Ref(Vector{DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelErrorCompact}(undef))         # Pointer to the error data
        data_d = Vector{DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelErrorCompact}(undef)               # Pointer to the array of size maxFedWords    
        _formatterErrors_h::DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelFormatterErrors                # Pixel formatter errors 
        
        # Constructor for SiPixelDigiErrorsSoA
        # Inputs:
        #   maxFedWords::size_t - Maximum number of FED words
        #   errors::PixelFormatterErrors - Pixel formatter errors
        # Outputs:
        #   A new instance of SiPixelDigiErrorsSoA with allocated data arrays and initialized pointers
        function SiPixelDigiErrorsSoA(maxFedWords::size_t, errors::PixelFormatterErrors)
            # Allocate memory for the data arrays.
            data_d = Vector{DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelErrorCompact}(undef, maxFedWords)
            fill!(data_d, PixelErrorCompact())  # Zero-initialize

            error_d = Vector{DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelErrorCompact}(undef, maxFedWords)
            fill!(error_d, PixelErrorCompact())

            # Set pointers
            data_d_ptr = Base.unsafe_convert(Ptr{Vector{PixelErrorCompact}}, Ref(data_d))
            error_d_ptr = Base.unsafe_convert(Ptr{Vector{PixelErrorCompact}}, Ref(error_d))

            @assert isempty(data_d)
            @assert length(data_d) == maxFedWords

            # Return a new instance of SiPixelDigiErrorsSoA
            return new(data_d_ptr, error_d_ptr, errors)
        end
    end

    # Function to get the pixel formatter errors from a SiPixelDigiErrorsSoA instance.
    # Inputs:
    #   self::SiPixelDigiErrorsSoA - The instance of SiPixelDigiErrorsSoA
    # Outputs:
    #   PixelFormatterErrors - The pixel formatter errors
    function formatterErrors(self::SiPixelDigiErrorsSoA)::DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelFormatterErrors
        return self._formatterErrors_h
    end

    # Function to get the error data pointer from a SiPixelDigiErrorsSoA instance.
    # Inputs:
    #   self::SiPixelDigiErrorsSoA - The instance of SiPixelDigiErrorsSoA
    # Outputs:
    #   ptr(Vector{PixelErrorCompact}) - The pointer to the error data
    function error(self::SiPixelDigiErrorsSoA)::Vector{DataFormats_SiPixelDigi_interface_PixelErrors_h.PixelErrorCompact}
        return self._error_d
    end

end
