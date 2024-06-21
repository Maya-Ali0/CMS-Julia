"""
Module for handling the SiPixelFedCablingMapGPU structure in the Pixel GPU reconstruction process.

# Overview
This module defines constants and a structure related to the SiPixelFedCablingMapGPU, which is used in the reconstruction of pixel data on a GPU. The constants represent various 
limits and sizes for the FED (Front-End Driver) system. The structure, SiPixelFedCablingMapGPU, holds arrays that map the FED information necessary for pixel data processing.

# Constants and Structure
The constants define maximum values for the FED system components. The structure includes arrays for different FED-related IDs and flags, as well as the size of the cabling map.
"""
module RecoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU

# Export the SiPixelFedCablingMapGPU structure for use in other modules
export SiPixelFedCablingMapGPU

"""
Module containing constants related to Pixel GPU details.

# Constants
- MAX_FED: Maximum number of FEDs for phase 1; not all are necessarily used.
- MAX_LINK: Maximum number of links/channels for Phase 1.
- MAX_ROC: Maximum number of ROCs.
- MAX_SIZE: Total maximum size calculated as `MAX_FED * MAX_LINK * MAX_ROC`.
- MAX_SIZE_BYTE_BOOL: Maximum size in bytes for boolean arrays.
"""
module PixelGPUDetails
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
end # module PixelGPUDetails

"""
Struct to hold the SiPixel FED Cabling Map for the GPU

    This struct represents the cabling map that connects the detector readout electronics to the 
    corresponding detector modules. It specifies how data signals are routed from the physical detector 
    components (like sensors and readout chips) to the data acquisition system, ensuring that each electronic 
    component is properly linked to its corresponding detector element. This map is crucial for correctly 
    interpreting the data collected by the detector system.

# Fields
- fed: Array to store FED IDs, which is used for identifying the FEDs.
- link: Array to store link IDs, which is used for identifying the links within each FED.
- roc: Array to store ROC IDs, which is used for identifying the ROCs (Read-Out Chips) within each link.
- raw_id: Array to store Raw IDs, which is used for storing the raw detector IDs.
- roc_in_det: Array to store ROC in detector IDs, which is used for mapping the ROC within the detector module.
- module_id: Array to store module IDs, which is used for identifying the detector modules.
- bad_rocs: Array to store bad ROC flags, which is used for flagging ROCs that are not functioning correctly.
- size: Size of the cabling map, which is used for storing the total number of entries in the cabling map.

# Constructor
Initializes the arrays with zeros and sets the size to zero.
"""

# TODO: since this has more information than just cabling map, maybe we should invent a better name?
# TODO: check memory alignment efficiency and necessity as well as the need for a constructor
# TODO: ntuples or vectors?

struct SiPixelFedCablingMapGPU
    fed::Array{UInt32, 1}
    link::Array{UInt32, 1}
    roc::Array{UInt32, 1}
    raw_id::Array{UInt32, 1}
    roc_in_det::Array{UInt32, 1}
    module_id::Array{UInt32, 1}
    bad_rocs::Array{UInt8, 1}
    size::UInt32

    # Constructor to initialize the SiPixelFedCablingMapGPU structure
    function si_pixel_fed_cabling_map_gpu()
        fed = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        link = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        roc = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        raw_id = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        roc_in_det = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        module_id = fill(UInt32(0), PixelGPUDetails.MAX_SIZE)
        bad_rocs = fill(UInt8(0), PixelGPUDetails.MAX_SIZE)
        size = UInt32(0)
        new(fed, link, roc, raw_id, roc_in_det, module_id, bad_rocs, size) # Zero-initialize all fields
    end
end

end # module RecoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU
