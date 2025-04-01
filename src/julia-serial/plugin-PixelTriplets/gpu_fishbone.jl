using ..caConstants:MAX_CELLS_PER_HIT
using ..gpuCACELL
function fish_bone(hits,cells,n_cells,is_outer_hit_of_cell,n_hits,check_track)
    max_cells_per_hit = MAX_CELLS_PER_HIT
    δx =  Vector{Float32}(undef,max_cells_per_hit)
    δy =  Vector{Float32}(undef,max_cells_per_hit)
    δz =  Vector{Float32}(undef,max_cells_per_hit)
    norms =  Vector{Float32}(undef,max_cells_per_hit)
    inner_detector_index =  Vector{UInt16}(undef,max_cells_per_hit)
    cell_indices_vector =  Vector{UInt32}(undef,max_cells_per_hit)

    for idy ∈ 1:n_hits
        cells_vector = is_outer_hit_of_cell[idy]
        num_of_outer_doublets = length(cells_vector)
        if num_of_outer_doublets < 2
            continue
        end
        first_cell = cells[cells_vector[1]]
        xo = get_outer_x(first_cell,hits)
        yo = get_outer_y(first_cell,hits)
        zo = get_outer_z(first_cell,hits)
        curr = 0

        for ic ∈ 1:num_of_outer_doublets
            ith_cell = cells[cells_vector[ic]]
            if ith_cell.the_used == 0
                continue 
            end
            if check_track && empty(ith_cell.the_tracks)
                continue
            end
            curr+=1
            cell_indices_vector[curr] = cells_vector[ic]
            inner_detector_index[curr] = get_inner_det_index(ith_cell,hits)
            δx[curr] = get_inner_x(ith_cell,hits) - xo
            δy[curr] = get_inner_y(ith_cell,hits) - yo
            δz[curr] = get_inner_z(ith_cell,hits) - zo
            norms[curr] = δx[curr]^2 + δy[curr]^2 + δz[curr]^2
        end
        if curr < 2 
            continue
        end
        for ic ∈ 1:curr-1
            ci = cells[cell_indices_vector[ic]]
            for jc ∈ ic+1:curr
                cj = cells[cell_indices_vector[jc]]
                cos12 = δx[ic] * δx[jc] + δy[ic] * δy[jc] + δz[ic] * δz[jc]
                if inner_detector_index[ic] != inner_detector_index[jc] && cos12*cos12 >= 0.99999f0*norms[ic]*norms[jc]
                    ## Kill the farthest (prefer consecutive layers)
                    if norms[ic] > norms[jc]
                        ci.the_doublet_id = -1
                        break
                    else
                        cj.the_doublet_id = -1 
                    end
                end
            end
        end
    end
    
    
    
end