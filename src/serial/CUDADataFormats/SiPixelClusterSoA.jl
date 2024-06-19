module CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA

    """
    Struct to represent a constant view of the device data.
    """
    struct DeviceConstView
        moduleStart::Vector{UInt32}       # Pointer to module start data
        clusInModule::Vector{UInt32}      # Pointer to clusters in module data
        moduleId::Vector{UInt32}          # Pointer to module ID data
        clusModuleStart::Vector{UInt32}   # Pointer to clusters module start data
    end

    """
    Function to get the start of a module from the view.
    Inputs:
    - view::DeviceConstView: The device view containing the data pointers.
    - i::Int: Index of the module.
    Outputs:
    - UInt32: The start index of the specified module.
    """
    @inline function moduleStart(view::DeviceConstView, i::Int)::UInt32
        return view.moduleStart[i]
    end

    """
    Function to get the number of clusters in a module from the view.
    Inputs:
    - view::DeviceConstView: The device view containing the data pointers.
    - i::Int: Index of the module.
    Outputs:
    - UInt32: The number of clusters in the specified module.
    """
    @inline function clusInModule(view::DeviceConstView, i::Int)::UInt32
        return view.clusInModule[i]
    end

    """
    Function to get the module id from the view.
    Inputs:
    - view::DeviceConstView: The device view containing the data pointers.
    - i::Int: Index of the module.
    Outputs:
    - UInt32: The module ID of the specified module.
    """
    @inline function moduleId(view::DeviceConstView, i::Int)::UInt32
        return view.moduleId[i]
    end

    """
    Function to get the start of a cluster module from the view.
    Inputs:
    - view::DeviceConstView: The device view containing the data pointers.
    - i::Int: Index of the cluster module.
    Outputs:
    - UInt32: The start index of the specified cluster module.
    """
    @inline function clusModuleStart(view::DeviceConstView, i::Int)::UInt32
        return view.clusModuleStart[i]
    end

    """
    Struct to hold the cluster data in a CUDA-compatible structure.
    """
    struct SiPixelClustersSoA
        moduleStart_d::Vector{UInt32}       # Pointer to the module start data
        clusInModule_d::Vector{UInt32}      # Pointer to the number of clusters in each module
        moduleId_d::Vector{UInt32}          # Pointer to the module ID data
        clusModuleStart_d::Vector{UInt32}   # Pointer to the start index of clusters in each module
        
        view_d::DeviceConstView             # Device view containing the data pointers
        nClusters_h::UInt32                 # Number of clusters (stored on host)
    end

    """
    Constructor for SiPixelClustersSoA.
    Inputs:
    - maxClusters::Int: Maximum number of clusters.
    Outputs:
    - SiPixelClustersSoA: A new instance with allocated data arrays and initialized device view.
    """
    function SiPixelClustersSoA(maxClusters::Int)
        # Allocate memory for the data arrays.
        moduleStart_d = zeros(UInt32, maxClusters + 1)
        clusInModule_d = zeros(UInt32, maxClusters)
        moduleId_d = zeros(UInt32, maxClusters)
        clusModuleStart_d = zeros(UInt32, maxClusters + 1)

        view_d = DeviceConstView(moduleStart_d, clusInModule_d, moduleId_d, clusModuleStart_d)
    
        return SiPixelClustersSoA(moduleStart_d, clusInModule_d, moduleId_d, clusModuleStart_d, view_d, 0)
    end

    """
    Function to get the device view pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - DeviceConstView: The pointer to the device view.
    """
    function view(self::SiPixelClustersSoA)::DeviceConstView
        return self.view_d  
    end

    """
    Function to get the module start pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the module start data.
    """
    function moduleStart(self::SiPixelClustersSoA)::Vector{UInt32}
        return self.moduleStart_d
    end

    """
    Function to get the clusters in module pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the clusters in module data.
    """
    function clusInModule(self::SiPixelClustersSoA)::Vector{UInt32}
        return self.clusInModule_d
    end

    """
    Function to get the module id pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the module id data.
    """
    function moduleId(self::SiPixelClustersSoA)::Vector{UInt32}
        return self.moduleId_d
    end

    """
    Function to get the clusters module start pointer from a SiPixelClustersSoA instance.
    Inputs:
    - self::SiPixelClustersSoA: The instance of SiPixelClustersSoA.
    Outputs:
    - pointer(UInt32): The pointer to the clusters module start data.
    """
    function clusModuleStart(self::SiPixelClustersSoA)::Vector{UInt32}
        return self.clusModuleStart_d
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

end # module
