include("../DataFormats/PixelErrors.jl")
using .Main.DataFormatsSiPixelDigiInterfacePixelErrors

module CUDADataFormats_SiPixelDigi_interface_SiPixelDigiErrorsSoA

    """
    This module defines the data structure for storing SiPixel digi error data in a 
    format suitable for CUDA operations. It includes structures and functions 
    to manage and access the error data.
    """
    struct SiPixelDigiErrorsSoA
        error_d::Vector{Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelErrorCompact}    # Pointer to the error data
        data_d::Vector{Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelErrorCompact}     # Pointer to the array of size maxFedWords    
        formatterErrors_h::Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelFormatterErrors         # Pixel formatter errors 
        
        """
        Constructor for SiPixelDigiErrorsSoA
        Inputs:
          - maxFedWords::size_t: Maximum number of FED words
          - errors::PixelFormatterErrors: Pixel formatter errors
        Outputs:
          - A new instance of SiPixelDigiErrorsSoA with allocated data arrays and initialized pointers
        """
        function SiPixelDigiErrorsSoA(maxFedWords::UInt64, errors::Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelFormatterErrors)
            # Allocate memory for the data arrays.
            data_d = Vector{Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelErrorCompact}(undef, maxFedWords)
            fill!(data_d, PixelErrorCompact())  # Zero-initialize

            error_d = Vector{Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelErrorCompact}(undef, maxFedWords)
            fill!(error_d, PixelErrorCompact())

            @assert isempty(data_d)
            @assert length(data_d) == maxFedWords

            # Return a new instance of SiPixelDigiErrorsSoA
            new(data_d, error_d, errors)
        end
    end

    """
    Function to get the pixel formatter errors from a SiPixelDigiErrorsSoA instance.
    Inputs:
      - self::SiPixelDigiErrorsSoA: The instance of SiPixelDigiErrorsSoA
    Outputs:
      - PixelFormatterErrors: The pixel formatter errors
    """
    function formatter_errors(self::SiPixelDigiErrorsSoA)::Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelFormatterErrors
        return self.formatterErrors_h
    end

    """
    Function to get the error data pointer from a SiPixelDigiErrorsSoA instance.
    Inputs:
      - self::SiPixelDigiErrorsSoA: The instance of SiPixelDigiErrorsSoA
    Outputs:
      - ptr(Vector{PixelErrorCompact}): The pointer to the error data
    """
    function error(self::SiPixelDigiErrorsSoA)::Vector{Main.DataFormatsSiPixelDigiInterfacePixelErrors.PixelErrorCompact}
        return self.error_d
    end

end
