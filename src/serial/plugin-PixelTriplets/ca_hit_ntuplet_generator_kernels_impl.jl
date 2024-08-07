function maxNumber() 
    return 32 * 1024
end
  
S = maxNumber()
  
HitContainer = HisToContainer{UInt32, S, 5 * S, sizeof(UInt32), 8 , UInt16, 1}
  
function kernel_fill_hit_indices(tuples::HitContainer, hhp::TrackingRecHit2DSOAView, hitDetIndices::HitContainer)
      first = 1
      ntot = tot_bins(tuples)
      size = size(tuples)
      for idx in first:ntot
          hitDetIndices.off[idx] = tuples.off[idx]
      end
      hh = hhp
      nhits = n_hits(hh)
      
      for idx in first:size
          @assert bins(tuples, idx) < nhits
          hitDetIndices.bins[idx] = detector_index(hh, tuples.bins[idx])
      end
end
  