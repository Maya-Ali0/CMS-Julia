module Tracks
export TrackSOA
using ..histogram:OneToManyAssoc
using ..eigenSOA:ScalarSOA
const hindex_type = UInt16


"""
ChatGPT:

Bad: Tracks that are unreliable or cannot be used for analysis due to poor fit or other issues.

Duplicate (dup): Tracks that are duplicates of each other, typically identified as multiple reconstructions of the same physical track due to overlapping hits or detector noise.

Loose: Tracks that pass basic quality criteria but may not meet stricter requirements. These tracks are generally used for preliminary analyses.

Strict: Tracks that meet a stringent set of quality criteria, indicating high confidence in their accuracy. These are used in detailed analyses and precision measurements.

Tight: Tracks that are very stringent in terms of quality criteria, typically used in scenarios where very high precision is required.

High Purity: Tracks that are identified with a high degree of certainty to be true tracks, often verified through additional checks and validation processes.
"""
@enum Quality begin
    bad = 0
    dup = 1
    loose = 2
    strict = 3
    tight = 4
    highPurity = 5
end


struct TrackSOAT{S,many}
    # const HitContainer = OneToManyAssoc{hindex_type,S,5*S}
    m_quality::ScalarSOA{UInt8,S}
    chi2::ScalarSOA{Float32,S}
    eta::ScalarSOA{Float32,S}
    pt::ScalarSOA{Float32,S}
    hit_indices::OneToManyAssoc{hindex_type,S,many}
    det_indices::OneToManyAssoc{hindex_type,S,many}
    m_nTracks::UInt32
    function TrackSOAT{S,many}() where {S,many}
        new(ScalarSOA{UInt8,S}(),ScalarSOA{Float32,S}(),ScalarSOA{Float32,S}(),ScalarSOA{Float32,S}(),OneToManyAssoc{hindex_type,S,many}(),OneToManyAssoc{hindex_type,S,many}())
    end
end
const MAX_NUMBER = 32 * 1024
const TrackSOA = TrackSOAT{MAX_NUMBER,5*MAX_NUMBER}

end