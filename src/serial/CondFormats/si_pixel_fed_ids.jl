module CondFormatsSiPixelFedIds

"""
Struct to hold SiPixel FED IDs

This struct stores a list of FED (Front-End Driver) IDs that are used in the pixel detector system. FED IDs uniquely identify each FED unit, which is responsible for reading out data from the detector.

# Fields
- _fed_ids::Vector{UInt}: A vector storing the list of FED IDs.

# Constructor
Initializes the SiPixelFedIds structure with a given list of FED IDs.
"""
mutable struct SiPixelFedIds
    _fed_ids::Vector{UInt}

    function si_pixel_fed_ids(fed_ids::Vector{UInt})
        new(fed_ids)
    end
end

"""
Retrieves the list of FED IDs from the SiPixelFedIds structure.
"""
fed_ids(ids::SiPixelFedIds)::Vector{UInt} = ids._fed_ids

end # module CondFormatsSiPixelFedIds
