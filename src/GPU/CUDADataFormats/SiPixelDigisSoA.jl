module CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
export n_modules, SiPixelDigisSoA, digiView, n_digis, DeviceConstView, module_ind, clus, xx, yy, adc
  # Structure to hold SiPixel digis data  
  mutable struct SiPixelDigisSoA{U <: AbstractVector{Int32},V <: AbstractVector{UInt16},W <: AbstractVector{UInt32}}
      pdigi_d::W      # Digis data
      raw_id_arr_d::W   # Raw ID array
      xx_d::V         # Local X-coordinates of each pixel
      yy_d::V         # Local Y-coordinates of each pixel
      adc_d::V        # ADC values of each pixel
      module_ind_d::V  # Module IDs of each pixel
      clus_d::U      # Cluster IDs of each pixel
      n_modules_h::UInt32           # Number of modules
      n_digis_h::UInt32             # Number of digis
  end
  """
  Constructor for SiPixelDigisSoA
  Inputs:and how to use Adapt.jl to pass custom structs to CUDA kernels (that might not even be right). I’ve tried reading the CUDA.jl documentation and implementing a trivial example (below) but it errors as the passed struct isn’t a bitstype.
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
      clus_d = Vector{Int32}(undef, maxFedWords)
      pdigi_d = Vector{UInt32}(undef, maxFedWords)
      raw_id_arr_d = Vector{UInt32}(undef, maxFedWords)
      # Return a new instance of SiPixelDigisSoA with initialized values
      return SiPixelDigisSoA(pdigi_d, raw_id_arr_d, xx_d, yy_d, adc_d, module_ind_d, clus_d, UInt32(0), UInt32(0))
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
  function set_n_modules_digis(self::SiPixelDigisSoA, n_modules::Integer, n_digis::Integer)
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
  function xx(self::SiPixelDigisSoA)
      return self.xx_d
  end

  """
  Get the Y-coordinates vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt16}: The vector of Y-coordinates
  """
  function yy(self::SiPixelDigisSoA)
      return self.yy_d
  end

  """
  Get the ADC values vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt16}: The vector of ADC values
  """
  function adc(self::SiPixelDigisSoA)
      return self.adc_d
  end

  """
  Get the module IDs vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt16}: The vector of module IDs
  """
  function module_ind(self::SiPixelDigisSoA)
      return self.module_ind_d
  end

  """
  Get the cluster IDs vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt32}: The vector of cluster IDs
  """
  function clus(self::SiPixelDigisSoA)
      return self.clus_d
  end

  """
  Get the digis data vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt32}: The vector of digis data
  """
  function pdigi(self::SiPixelDigisSoA)
      return self.pdigi_d
  end

  """
  Get the raw ID array vector
  Inputs:
    - self::SiPixelDigisSoA: The SiPixelDigisSoA instance
  Outputs:
    - Vector{UInt32}: The vector of raw ID array
  """
  function raw_id_arr(self::SiPixelDigisSoA)
      return self.raw_id_arr_d
  end
  using Adapt
  Adapt.@adapt_structure SiPixelDigisSoA
end
