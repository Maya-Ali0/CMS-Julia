module CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA

    # Structure to hold a constant view of device data
    struct DeviceConstView
        xx::Vector{UInt16}         # X-coordinates of pixels
        yy::Vector{UInt16}         # Y-coordinates of pixels
        adc::Vector{UInt16}        # ADC values of pixels
        module_ind::Vector{UInt16}  # Module indices of pixels
        clus::Vector{UInt32}       # Cluster indices of pixels
    end

    # Structure to hold SiPixel digis data
    struct SiPixelDigisSoA
        pdigi_d::Vector{UInt32}      # Digis data
        raw_id_arr_d::Vector{UInt32}   # Raw ID array
        xx_d::Vector{UInt16}         # Local X-coordinates of each pixel
        yy_d::Vector{UInt16}         # Local Y-coordinates of each pixel
        adc_d::Vector{UInt16}        # ADC values of each pixel
        module_ind_d::Vector{UInt16}  # Module IDs of each pixel
        clus_d::Vector{UInt32}       # Cluster IDs of each pixel
        view_d::DeviceConstView      # "Me" pointer, a constant view of the device data
        n_modules_h::UInt32           # Number of modules
        n_digis_h::UInt32             # Number of digis

        """
        Constructor for SiPixelDigisSoA
        Inputs:
          - maxFedWords::Int: Maximum number of FED words
        Outputs:
          - A new instance of SiPixelDigisSoA with allocated data arrays and initialized pointers
        """
        function SiPixelDigisSoA(maxFedWords::Int)
            # Uninitialized arrays of the specified size
            xx_d = Vector{UInt16}(undef, maxFedWords)
            yy_d = Vector{UInt16}(undef, maxFedWords)
            adc_d = Vector{UInt16}(undef, maxFedWords)
            module_ind_d = Vector{UInt16}(undef, maxFedWords)
            clus_d = Vector{UInt32}(undef, maxFedWords)
            pdigi_d = Vector{UInt32}(undef, maxFedWords)
            raw_id_arr_d = Vector{UInt32}(undef, maxFedWords)

            # Create a DeviceConstView with the above arrays
            view_d = DeviceConstView(xx_d, yy_d, adc_d, module_ind_d, clus_d)
            # Return a new instance of SiPixelDigisSoA with initialized values
            new(pdigi_d, raw_id_arr_d, xx_d, yy_d, adc_d, module_ind_d, clus_d, view_d, 0, 0)
        end
    end

    # Inline functions to access elements from DeviceConstView

    """
    Access X-coordinate at index i from DeviceConstView
    Inputs:
      - view::DeviceConstView: The DeviceConstView instance
      - i::Int: The index to access
    Outputs:
      - UInt16: The X-coordinate at the specified index
    """
    @inline function xx(view::DeviceConstView, i::Int)::UInt16
        return unsafe_load(view.xx + i - 1)  # Memory is zero-indexed
    end

    """
    Access Y-coordinate at index i from DeviceConstView
    Inputs:
      - view::DeviceConstView: The DeviceConstView instance
      - i::Int: The index to access
    Outputs:
      - UInt16: The Y-coordinate at the specified index
    """
    @inline function yy(view::DeviceConstView, i::Int)::UInt16
        return unsafe_load(view.yy + i - 1)  # Memory is zero-indexed
    end

    """
    Access ADC value at index i from DeviceConstView
    Inputs:
      - view::DeviceConstView: The DeviceConstView instance
      - i::Int: The index to access
    Outputs:
      - UInt16: The ADC value at the specified index
    """
    @inline function adc(view::DeviceConstView, i::Int)::UInt16
        return unsafe_load(view.adc + i - 1)  # Memory is zero-indexed
    end

    """
    Access module ID at index i from DeviceConstView
    Inputs:
      - view::DeviceConstView: The DeviceConstView instance
      - i::Int: The index to access
    Outputs:
      - UInt16: The module ID at the specified index
    """
    @inline function module_ind(view::DeviceConstView, i::Int)::UInt16
        return unsafe_load(view.module_ind + i - 1)  # Memory is zero-indexed
    end

    """
    Access cluster ID at index i from DeviceConstView
    Inputs:
      - view::DeviceConstView: The DeviceConstView instance
      - i::Int: The index to access
    Outputs:
      - UInt32: The cluster ID at the specified index
    """
    @inline function clus(view::DeviceConstView, i::Int)::UInt32
        return unsafe_load(view.clus + i - 1)  # Memory is zero-indexed
    end

    """
    Get the DeviceConstView from SiPixelDigisSoA
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - DeviceConstView: The constant view of the device data
    """
    function view(self::SiPixelDigisSoA)::DeviceConstView
        return self.view_d
    end

    """
    Set the number of modules and digis
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
      - nModules::UInt32: Number of modules
      - nDigis::UInt32: Number of digis
    Outputs:
      - None (modifies the instance in-place)
    """
    function set_n_modules_digis(self::SiPixelDigisSoA, n_modules::UInt32, n_digis::UInt32)
        self.n_modules_h = n_modules
        self.n_digis_h = n_digis
    end

    """
    Get the number of modules
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - UInt32: The number of modules
    """
    function n_modules(self::SiPixelDigisSoA)::UInt32
        return self.n_modules_h
    end

    """
    Get the number of digis
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - UInt32: The number of digis
    """
    function n_digis(self::SiPixelDigisSoA)::UInt32
        return self.n_digis_h
    end

    # Functions to get the vectors from SiPixelDigisSoA

    """
    Get the X-coordinates vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt16}: The vector of X-coordinates
    """
    function xx(self::SiPixelDigisSoA)::Vector{UInt16}
        return self.xx_d
    end

    """
    Get the Y-coordinates vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt16}: The vector of Y-coordinates
    """
    function yy(self::SiPixelDigisSoA)::Vector{UInt16}
        return self.yy_d
    end

    """
    Get the ADC values vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt16}: The vector of ADC values
    """
    function adc(self::SiPixelDigisSoA)::Vector{UInt16}
        return self.adc_d
    end

    """
    Get the module IDs vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt16}: The vector of module IDs
    """
    function module_ind(self::SiPixelDigisSoA)::Vector{UInt16}
        return self.module_ind_d
    end

    """
    Get the cluster IDs vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt32}: The vector of cluster IDs
    """
    function clus(self::SiPixelDigisSoA)::Vector{UInt32}
        return self.clus_d
    end

    """
    Get the digis data vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt32}: The vector of digis data
    """
    function pdigi(self::SiPixelDigisSoA)::Vector{UInt32}
        return self.pdigi_d
    end

    """
    Get the raw ID array vector
    Inputs:
      - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
    Outputs:
      - Vector{UInt32}: The vector of raw ID array
    """
    function raw_id_arr(self::SiPixelDigisSoA)::Vector{UInt32}
        return self.raw_id_arr_d
    end
    
end
