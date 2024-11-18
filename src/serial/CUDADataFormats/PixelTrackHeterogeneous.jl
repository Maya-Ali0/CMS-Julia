module Tracks
export TrackSOA
export n_hits_track
export stride_track
using ..Patatrack:Quality
using ..histogram:OneToManyAssoc,size
using ..eigenSOA:ScalarSOA
const hindex_type = UInt16




struct TrackSOAT{S,many}
    # const HitContainer = OneToManyAssoc{hindex_type,S,5*S}
    m_quality::ScalarSOA{Quality,S}
    chi2::ScalarSOA{Float32,S}
    eta::ScalarSOA{Float32,S}
    pt::ScalarSOA{Float32,S}
    hit_indices::OneToManyAssoc{hindex_type,S,many}
    det_indices::OneToManyAssoc{hindex_type,S,many}
    m_nTracks::UInt32
    function TrackSOAT{S,many}() where {S,many}
        new(ScalarSOA{Quality,S}(),ScalarSOA{Float32,S}(),ScalarSOA{Float32,S}(),ScalarSOA{Float32,S}(),OneToManyAssoc{hindex_type,S,many}(),OneToManyAssoc{hindex_type,S,many}())
    end
end

const MAX_NUMBER = 32 * 1024
const TrackSOA = TrackSOAT{MAX_NUMBER,5*MAX_NUMBER}
n_hits_track(self::TrackSOA,i::Integer) = size(self.det_indices,i)
stride_track(::TrackSOAT{S,many}) where {S,many} = S
end