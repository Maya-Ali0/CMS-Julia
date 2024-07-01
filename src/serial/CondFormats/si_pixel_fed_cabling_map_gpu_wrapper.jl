module recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper

include("si_pixel_fed_cabling_map_gpu.jl")
using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU

"""
Module for wrapping the siPixelFedCablingMapGPU structure with additional metadata.

# Overview
This module defines a wrapper struct, siPixelFedCablingMapGPUWrapper, to encapsulate the siPixelFedCablingMapGPU structure. It provides additional functionality and metadata related to the cabling map used in the GPU-based pixel reconstruction process.

# Struct
The siPixelFedCablingMapGPUWrapper struct includes:
- _cabling_map_host::siPixelFedCablingMapGPU: The underlying cabling map representing the detector readout electronics connections.
- _mod_to_unp_default::Vector{UInt8}: Default mapping of modules to unpackers. Unpackers are responsible for processing data from the modules. Each entry in the vector corresponds to a module ID, and the value at each index indicates which unpacker is assigned to that module.
- _has_quality::Bool: Flag indicating whether quality information is available. If this flag is true, it means that the cabling map contains additional metadata that can be used to assess the quality of the data.

# Constructor
- siPixelFedCablingMapGPUWrapper(cabling_map::siPixelFedCablingMapGPU, mod_to_unp::Vector{UInt8}): Initializes a new wrapper instance with the provided cabling map and module-to-unpacker mapping.

# Functions
- has_quality(wrapper::siPixelFedCablingMapGPUWrapper)::Bool: Checks if the wrapper has quality information available.
- get_cpu_product(wrapper::siPixelFedCablingMapGPUWrapper)::siPixelFedCablingMapGPU: Retrieves the cabling map from the wrapper.
- get_mod_to_unp_all(wrapper::siPixelFedCablingMapGPUWrapper)::Vector{UInt8}: Retrieves the default module-to-unpacker mapping from the wrapper.

"""
mutable struct siPixelFedCablingMapGPUWrapper
    _cabling_map_host::siPixelFedCablingMapGPU
    _mod_to_unp_default::Vector{UInt8}
    _has_quality::Bool

    function siPixelFedCablingMapGPUWrapper(cabling_map::siPixelFedCablingMapGPU, mod_to_unp::Vector{UInt8})
        new(cabling_map, mod_to_unp, false)
    end
end

has_quality(wrapper::siPixelFedCablingMapGPUWrapper)::Bool = wrapper._has_quality

get_cpu_product(wrapper::siPixelFedCablingMapGPUWrapper)::siPixelFedCablingMapGPU = wrapper._cabling_map_host

get_mod_to_unp_all(wrapper::siPixelFedCablingMapGPUWrapper)::Vector{UInt8} = wrapper._mod_to_unp_default

end # module recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPUWrapper
