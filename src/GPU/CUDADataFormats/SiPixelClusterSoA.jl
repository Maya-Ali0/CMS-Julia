module CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
export SiPixelClustersSoA, nClusters, clus_module_start, clusterView, DeviceConstView, module_start, setNClusters!, module_id, clus_in_module

    """
    Struct to hold the cluster data in a CUDA-compatible structure.
    """
    mutable struct SiPixelClustersSoA{V <: AbstractVector{UInt32}}
        module_start_d::V       # Pointer to the module start data
        clus_in_module_d::V      # Pointer to the number of clusters in each module
        module_id_d::V          # Pointer to the module ID data
        clus_module_start_d::V   # Pointer to the start index of clusters in each module
        nClusters_h::UInt32                 # Number of clusters (stored on host)
    end

    """
    Constructor for SiPixelClustersSoA.
    Inputs:
    - maxClusters::Int: Maximum number of clusters.
    Outputs:
    - SiPixelClustersSoA: A new instance with allocated data arrays and initialized device view.
    """
    function SiPixelClustersSoA(maxClusters)
        # Allocate memory for the data arrays.
        module_start_d = zeros(UInt32, maxClusters + 1)
        clus_in_module_d = zeros(UInt32, maxClusters)
        module_id_d = zeros(UInt32, maxClusters)
        clus_module_start_d = zeros(UInt32, maxClusters + 1)
        return SiPixelClustersSoA(module_start_d, clus_in_module_d, module_id_d, clus_module_start_d, UInt32(0))
    end

    """
    Function to get the module start pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the module start data.
    """
    function module_start(self::SiPixelClustersSoA)
        return self.module_start_d
    end

    """
    Function to get the clusters in module pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the clusters in module data.
    """
    function clus_in_module(self::SiPixelClustersSoA)
        return self.clus_in_module_d
    end

    """
    Function to get the module id pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the module id data.
    """
    function module_id(self::SiPixelClustersSoA)
        return self.module_id_d
    end

    """
    Function to get the clusters module start pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the clusters module start data.
    """
    function clus_module_start(self::SiPixelClustersSoA)
        return self.clus_module_start_d
    end

    """
    Function to set the number of clusters in a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    - nClusters::UInt32: The number of clusters to set.
    Outputs:
    - None
    """
    function setNClusters!(self::SiPixelClustersSoA, nClusters::UInt32)
        self.nClusters_h = nClusters  # Set the number of clusters.
    end

    """
    Function to get the number of clusters from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - UInt32: The number of clusters.
    """
    function nClusters(self::SiPixelClustersSoA)::UInt32
        return self.nClusters_h 
    end
    using Adapt
    Adapt.@adapt_structure SiPixelClustersSoA

end # module