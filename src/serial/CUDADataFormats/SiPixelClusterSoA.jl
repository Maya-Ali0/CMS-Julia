module  CUDADataFormats_SiPixelCluster_interface_SiPixelClustersSoA_h

struct SiPixelClustersSoA
   
    _moduleStart_d::pointer(Vector{UInt32})        # module id of each module
    _clusInModule_d::pointer(Vector{UInt32})    # number of clusters found in each module
    _moduleId_d::pointer(Vector{UInt32})        # index of the first pixel of each module
    _clusModuleStart_d::pointer(Vector{UInt32}) # index of the first cluster of each module
    
    _view_d::pointer(DeviceConstView)           # "me" pointer
    _nClusters_h::UInt32

    SiPixelClustersSoA(maxClusters::size_t)
        moduleStart_d = Vector{UInt32}(undef, maxClusters + 1)
        clusInModule_d = Vector{UInt32}(undef, maxClusters) 
        moduleId_d = Vector{UInt32}(undef, maxClusters)
        clusModuleStart_d = Vector{UInt32}(undef, maxClusters + 1)

        view = DeviceConstView(
            pointer(moduleStart_d),
            pointer(clusInModule_d),
            pointer(moduleId_d),
            pointer(clusModuleStart_d),
        )

        new(moduleStart_d, clusInModule_d, moduleId_d, clusModuleStart_d, view, maxClusters)     
end

struct DeviceConstView
    const _moduleStart::pointer(UInt32)
    const _clusInModule::pointer(UInt32)
    const _moduleId::pointer(UInt32)
    const _clusModuleStart::pointer(UInt32)
end

@inline function moduleStart(view::DeviceConstView, i::Int)::UInt32
    return unsafe_load(view._moduleStart + i - 1)
end
@inline function clusInModule(view::DeviceConstView, i::Int)::UInt32
    return unsafe_load(view._clusInModule + i - 1)
end
@inline function moduleId(view::DeviceConstView, i::Int)::UInt32
    return unsafe_load(view._moduleId + i - 1)
end
@inline function clusModuleStart(view::DeviceConstView, i::Int)::UInt32
    return unsafe_load(view._clusModuleStart + i - 1)
end

function view(self::SiPixelDigisSoA)::Ptr{DeviceConstView}
    return pointer(self._view_d)
end

function moduleStart(self::SiPixelClustersSoA):: pointer(UInt32)
    return self._moduleStart_d
end

function clusInModule(self::SiPixelClustersSoA):: pointer(UInt32)
    return self._clusInModule_d
end
function moduleId(self::SiPixelClustersSoA):: pointer(UInt32)
    return self._moduleId_d
end
function clusModuleStart(self::SiPixelClustersSoA):: pointer(UInt32)
    return self.clusModuleStart_d
end

function setNClusters(self::SiPixelClustersSoA, nClusters::UInte32)
    self.nClusters = _nClusters_h
end

function nClusters(self::SiPixelClustersSoA)
    return self._nClusters_h
end
end