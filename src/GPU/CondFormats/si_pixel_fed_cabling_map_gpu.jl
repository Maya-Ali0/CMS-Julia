"""
Module for handling the siPixelFedCablingMapGPU structure in the Pixel GPU reconstruction process.

# Overview
This module defines constants and a structure related to the SiPixelFedCablingMapGPU, which is used in the reconstruction of pixel data on a GPU. The constants represent various 
limits and sizes for the FED (Front-End Driver) system. The structure, SiPixelFedCablingMapGPU, holds arrays that map the FED information necessary for pixel data processing.

# Constants and Structure
The constants define maximum values for the FED system components. The structure includes arrays for different FED-related IDs and flags, as well as the size of the cabling map.
"""
module recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU

# Export the siPixelFedCablingMapGPU structure for use in other modules
export SiPixelFedCablingMapGPU
export MAX_LINK , MAX_ROC
"""
Module containing constants related to Pixel GPU details.

# Constants
- MAX_FED: Maximum number of FEDs for phase 1; not all are necessarily used.
- MAX_LINK: Maximum number of links/channels for Phase 1.
- MAX_ROC: Maximum number of ROCs.
- MAX_SIZE: Total maximum size calculated as `MAX_FED * MAX_LINK * MAX_ROC`.
- MAX_SIZE_BYTE_BOOL: Maximum size in bytes for boolean arrays.
"""
module pixelGPUDetails
    export MAX_SIZE , MAX_FED , MAX_ROC , MAX_SIZE, MAX_SIZE_BYTE_BOOL, MAX_LINK
    # Maximum number of FEDs for phase 1; not all are necessarily used
    const MAX_FED::UInt32 = 150
    # Maximum number of links/channels for Phase 1
    const MAX_LINK::UInt32 = 48
    # Maximum number of ROCs
    const MAX_ROC::UInt32 = 8
    # Total maximum size calculated as MAX_FED * MAX_LINK * MAX_ROC
    const MAX_SIZE::UInt32 = MAX_FED * MAX_LINK * MAX_ROC
    # Maximum size in bytes for boolean arrays
    const MAX_SIZE_BYTE_BOOL::UInt32 = MAX_SIZE * sizeof(UInt8)
end # module pixelGPUDetails


using .pixelGPUDetails

"""
Struct to hold the siPixel FED Cabling Map for the GPU

    This struct represents the cabling map that connects the detector readout electronics to the 
    corresponding detector modules. It specifies how data signals are routed from the physical detector 
    components (like sensors and readout chips) to the data acquisition system, ensuring that each electronic 
    component is properly linked to its corresponding detector element. This map is crucial for correctly 
    interpreting the data collected by the detector system.

# Fields
- fed: Vector to store FED IDs, which is used for identifying the FEDs.
- link: Vector to store link IDs, which is used for identifying the links within each FED.
- roc: Vector to store ROC IDs, which is used for identifying the ROCs (Read-Out Chips) within each link.
- raw_id: Vector to store Raw IDs, which is used for storing the raw detector IDs.
- roc_in_det: Vector to store ROC in detector IDs, which is used for mapping the ROC within the detector module.
- module_id: Vector to store module IDs, which is used for identifying the detector modules.
- bad_rocs: Vector to store bad ROC flags, which is used for flagging ROCs that are not functioning correctly.
- size: Size of the cabling map, which is used for storing the total number of entries in the cabling map.

# Constructor
Initializes the Vectors with zeros and sets the size to zero.
"""


# TODO: since this has more information than just cabling map, maybe we should invent a better name?
# TODO: check memory alignment efficiency and necessity as well as the need for a constructor
# TODO: ntuples or vectors?

# Parametric struct with two type parameters:
struct SiPixelFedCablingMapGPU{V<:AbstractVector{UInt32}, W<:AbstractVector{UInt8}}
    fed::V
    link::V
    roc::V
    raw_id::V
    roc_in_det::V
    module_id::V
    bad_rocs::W
    size::UInt32

    # CPU-friendly constructor: note we simply call new(...) with no type parameters.
    

    # Alternative constructor if arrays are already provided.
    # function SiPixelFedCablingMapGPU(fed, link, roc, raw_id, roc_in_det, module_id, bad_rocs, size)
        # new(fed, link, roc, raw_id, roc_in_det, module_id, bad_rocs, size)
    # end
end
function SiPixelFedCablingMapGPU{V,W}() where {V<:AbstractVector{UInt32}, W<:AbstractVector{UInt8}}
    return SiPixelFedCablingMapGPU(
        V(undef, MAX_SIZE),
        V(undef, MAX_SIZE),
        V(undef, MAX_SIZE),
        V(undef, MAX_SIZE),
        V(undef, MAX_SIZE),
        V(undef, MAX_SIZE),
        W(undef, MAX_SIZE),
        UInt32(0)
    )
end
Adapt.@adapt_structure SiPixelFedCablingMapGPU

end # module recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU