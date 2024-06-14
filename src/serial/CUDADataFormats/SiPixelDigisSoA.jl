module CUDADataFormats_SiPixelDigi_interface_SiPixelDigisSoA_h

struct SiPixelDigisSoA
    
    _pdigi_d::pointer(Vector{UInt32})
    _rawIdArr_d::pointer(Vector{UInt32})
    _xx_d::pointer(vector{UInt16})           # local coordinates of each pixel
    _yy_d::pointer(vector{UInt16})           # 
    _adc_d::pointer(vector{UInt16})          # ADC of each pixel
    _moduleInd_d::pointer(vector{UInt16})    # module id of each pixel
    _clus_d::pointer(vector{UInt32})         # cluster id of each pixel
    _view_d::pointer(DeviceConstView)        # "me" pointer
    _nModules_h::UInt32 = 0
    _nDigis_h::UInt32 = 0

    SiPixelDigisSoA(maxFedWords::Int)
        xx_d = Vector{UInt16}(undef, maxFedWords) #Unintialized array of type Vector{UInt16} of size maxFedWords
        yy_d = Vector{UInt16}(undef, maxFedWords)
        adc_d = Vector{UInt16}(undef, maxFedWords)
        moduleInd_d = Vector{UInt16}(undef, maxFedWords)
        clus_d = Vector{Int32}(undef, maxFedWords)
        pdigi_d = Vector{UInt32}(undef, maxFedWords)
        rawIdArr_d = Vector{UInt32}(undef, maxFedWords)

        view = DeviceConstView(
            pointer(xx_d),
            pointer(yy_d),
            pointer(adc_d),
            pointer(moduleInd_d),
            pointer(clus_d)
        )
        new(xx_d, yy_d, adc_d, moduleInd_d, clus_d, pdigi_d, rawIdArr_d, view, 0, 0)
     

    #move constructor
end

struct DeviceConstView
    const _xx::pointer(UInt16)
    const _yy::pointer(UInt16)
    const _adc::pointer(UInt16)
    const _moduleInd::pointer(UInt16)
    const _clus::pointer(UInt32)
end


@inline function xx(view::DeviceConstView, i::Int)::UInt16
    return unsafe_load(view._xx + i - 1)    # when working with pointers and raw memory in Julia, memory is zero-indexed.
end
@inline function yy(view::DeviceConstView, i::Int)::UInt16
    return unsafe_load(view._yy + i - 1)
end
@inline function adc(view::DeviceConstView, i::Int)::UInt16
    return unsafe_load(view._adc + i - 1)
end
@inline function moduleInd(view::DeviceConstView, i::Int)::UInt16
    return unsafe_load(view._moduleInd + i - 1)
end
@inline function clus(view::DeviceConstView, i::Int)::UInt32
    return unsafe_load(view._clus + i - 1)
end

function view(self::SiPixelDigisSoA)::Ptr{DeviceConstView}
    return pointer(self._view_d)
end


function setNModulesDigis(self::SiPixelDigisSoA, nModules::UInt32, nDigis::UInt32)
    self._nModules_h = nModules;
    self._nDigis_h = nDigis;
end

function nModules(self::SiPixelDigisSoA)::UInt32
    return self._nModules_h
end

function nDigis(self::SiPixelDigisSoA)::UInt32
    return self._nDigis_h
end

function xx(self::SiPixelDigisSoA)::ptr(UInt16)
    return self._xx_d
end

function yy(self::SiPixelDigisSoA)::ptr(UInt16)
    return self._yy_d
end
function xx(self::SiPixelDigisSoA)::ptr(UInt16)
    return self._adc_d
end
function moduleInd(self::SiPixelDigisSoA)::ptr(UInt16)
    return self._moduleInd_d
end
function clus(self::SiPixelDigisSoA)::ptr(UInt32)
    return self._clus_d
end
function pdigi(self::SiPixelDigisSoA)::ptr(UInt32)
    return self._pdigi_d
end
function rawIdArr(self::SiPixelDigisSoA)::ptr(UInt32)
    return self._rawIdArr_d
end

end