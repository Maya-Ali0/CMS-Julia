using ..CUDACore.hist_to_container
using ..gpuCACELL: GPUCACell, get_inner_hit_id, get_inner_r, get_inner_z, get_outer_r, get_outer_z, get_inner_det_index, are_aligned, dca_cut, add_outer_neighbor
using ..ca_constants: OuterHitOfCell, CellNeighborsVector
using Main:data
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView

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

function kernel_connect(apc1::AtomicPairCounter, apc2::AtomicPairCounter, hhp::TrackingRecHit2DSOAView, cells::GPUCACell, n_cells::UInt32, cell_neighbors::CellNeighborsVector, is_outer_hit_of_cell::OuterHitOfCell, hard_curv_cut::Float32, pt_min::Float32, ca_theta_cut_barrel::Float32, ca_theta_cut_forward::Float32, dca_cut_inner_triplet::Float32, dca_cut_outer_triplet::Float32)
    first_cell_index = 1
    first = 1

    apc1 = 0
    apc2 = 0

    for idx in first_cell_index:n_cells
        cell_index = idx
        this_cell = cells[cell_index]

        inner_hit_id = get_inner_hit_id(this_cell)
        number_of_possible_neighbors = size(is_outer_hit_of_cell[inner_hit_id])
        vi = data(is_outer_hit_of_cell[inner_hit_id])

        last_bpix1_det_index::UInt32 = 96
        last_barrel_det_index::UInt32 = 1184

        ri = get_inner_r(this_cell, hhp)
        zi = get_inner_z(this_cell, hhp)

        ro = get_outer_r(this_cell, hhp)
        zo = get_outer_z(this_cell, hhp)

        is_barrel = get_inner_det_index(this_cell, hhp) < last_barrel_det_index

        for j in first:number_of_possible_neighbors
            other_cell_index = vi[j]
            other_cell = cells[other_cell_index]

            r1 = get_inner_r(other_cell, hhp)
            z1 = get_inner_z(other_cell, hhp)

            aligned = are_aligned(r1, z1, ri, zi, ro, zo, pt_min, is_barrel ? ca_theta_cut_barrel : ca_theta_cut_forward)
            cut = dca_cut(this_cell, other_cell, hhp, get_inner_det_index(other_cell, hhp) < last_bpix1_det_index ? dca_cut_inner_triplet : dca_cut_outer_triplet, hard_curv_cut)
            if aligned && cut
                add_outer_neighbor(other_cell, cell_index, cell_neighbors)
                this_cell.the_used |= 1
                other_cell.the_used |= 1
            end
        end
    end
end