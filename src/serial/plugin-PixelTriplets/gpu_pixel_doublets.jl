module gpuPixelDoublets
    using StaticArrays
    using ..caConstants
    using ..gpuCACELL
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    using ..histogram
    export n_pairs
    export get_doublets_from_histo
    n_pairs = 13 + 2 + 4 
    const layer_pairs = SArray{Tuple{2*n_pairs}}(
        0, 1, 0, 4, 0, 7,              # BPIX1 (3)
        1, 2, 1, 4, 1, 7,              # BPIX2 (5)
        4, 5, 7, 8,                    # FPIX1 (8)
        2, 3, 2, 4, 2, 7, 5, 6, 8, 9,  # BPIX3 & FPIX2 (13)
        0, 2, 1, 3,                    # Jumping Barrel (15)
        0, 5, 0, 8,                    # Jumping Forward (BPIX1,FPIX2)
        4, 6, 7, 9                     # Jumping Forward (19)
    )
    const phi0p05::Int16 = 522 #round(521.52189...) = phi2short(0.05);
    const phi0p06::Int16 = 626 #round(625.82270...) = phi2short(0.06);
    const phi0p07::Int16 = 730 #round(730.12648...) = phi2short(0.07);
    const phi_cuts = SArray{Tuple{n_pairs}}(
        phi0p05,
        phi0p07,
        phi0p07,
        phi0p05,
        phi0p06,
        phi0p06,
        phi0p05,
        phi0p05,
        phi0p06,
        phi0p06,
        phi0p06,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05
    )

    const minz = SArray{Tuple{n_pairs}}(-20., 0., -30., -22., 10., -30., -70., -70., -22., 15., -30, -70., -70., -20., -22., 0, -30., -70., -70.)
    const maxz = SArray{Tuple{n_pairs}}(20., 30., 0., 22., 30., -10., 70., 70., 22., 30., -15., 70., 70., 20., 22., 30., 0., 70., 70.)
    const maxr = SArray{Tuple{n_pairs}}(20., 9., 9., 20., 7., 7., 5., 5., 20., 6., 6., 5., 5., 20., 20., 9., 9., 9., 9.)
    function init_doublets(is_outer_hit_of_cell::Vector{OuterHitOfCell},n_hits::Integer,cell_neighbors::CellNeighborsVector,
                           cell_tracks::CellTracksVector)
        @assert(!empty(is_outer_hit_of_cell))
        first = 1
        for i ∈ first:n_hits
            reset(is_outer_hit_of_cell[i])
        end
        i = extend(cell_neighbors)
        @assert(i == 1)
        reset(cell_neighbors[1])
        i = extend(cell_tracks)
        @assert(i == 1)
        reset(cell_tracks[1])
    end
    function get_doublets_from_histo(cells::Vector{GPUCACell},n_cells::Integer,cell_neighbors::CellNeighborsVector,cell_tracks::CellTracksVector,
                                     hhp::TrackingRecHit2DSOAView,is_outer_hit_of_cell::Vector{OuterHitOfCell},n_actual_pairs::Integer,
                                     ideal_cond::Bool,do_cluster_cut::Bool,do_z0_cut::Bool,do_pt_cut::Bool,max_num_of_doublets::Integer)
    end

    function doublets_from_histo(layer_pairs::Vector{UInt8},n_pairs::Integer,cells::Vector{GPUCACell},n_cells::Integer,cell_neighbors::CellNeighborsVector,
                                 cell_tracks::CellTracksVector,hh::TrackingRecHit2DSOAView,is_outer_hit_of_cell::Vector{OuterHitOfCell},phi_cuts::Vector{Int16},
                                 min_z::Vector{Float32},max_z::Vector{Float32},max_r::Vector{Float32},ideal_cond::Bool,do_cluster_cut::Bool,do_z0_cut::Bool,
                                 do_pt_cut::Bool,max_num_of_doublets::Integer)
        ###
        min_y_size_B1 = 36
        min_y_size_B2 = 28
        max_dy_size_12 = 28
        max_dy_size = 20
        max_dy_pred = 20
        dz_dr_fact = 8 * 0.0285 / 0.015 # from dz/dr to "DY"
        ### used when do_cluster_cut is set to true

        is_outer_ladder = ideal_cond
        hist = phi_binner(hh)
        offsets = hits_layer_start(hh)
        @assert(!empty(offsets))

        layer_size = let offsets = offsets 
            li -> offsets[li+1] - offsets[li]
        end

        n_pairs_max = MAX_NUM_OF_LAYER_PAIRS
        @assert(n_pairs <= n_pairs_max)

        inner_layer_cumulative_size = MArray{Tuple{n_pairs_max},UInt32}(undef)
        n_tot = 0
        inner_layer_cumulative_size[1] = layer_size(layer_pairs[1])
        
        for i ∈ 2:n_pairs
            inner_layer_cumulative_size[i] = inner_layer_cumulative_size[i-1] + layer_size(layerPairs[2*i-1]+1)
        end
        n_tot = inner_layer_cumulative_size[n_pairs]
        
        idy = 0
        first = 0 
        stride = 1
        pair_layer_id = 1 
        #FIXME j may need to start from 1 for indexing 
        for j ∈ idy:n_tot-1
            while(j >= inner_layer_cumulative_size[pair_layer_id])
                pair_layer_id+=1
            end
            @assert(pair_layer_id <= n_pairs)
            @assert(j < inner_layer_cumulative_size[pair_layer_id])
            @assert(pair_layer_id == 1 || j >= inner_layer_cumulative_size[pair_layer_id-1])

            inner = layer_pairs[2*pair_layer_id-1]
            outer = layer_pairs[2*pair_layer_id]

            @assert(outer > inner)
            hoff = hist_off(Hist,outer)
            i = (1 == pair_layer_id) ? j : j - inner_layer_cumulative_size[pair_layer_id-1] # previous layer
            i += offsets[inner+1] # +1 because indexed from 1 in julia
            @assert(i >= offsets[inner + 1]) # +1 because of indexing in julia
            @assert(i < offsets[inner + 2])
            mi = detector_index(hh,i)
            if(mi > 2000)
                continue 
            end
            mez = z_global(hh,i)
            if (mez < minz[pair_layer_id] || mez > maxz[pair_layer_id])
                continue;
            end
            
            me_s = -1

            if do_cluster_cut
                if inner == 0 
                    @assert(mi < 96)
                end
                is_outer_ladder = ideal_cond ? true : ((mi ÷ 8 ) % 2) == 0

                #Always test me_s > 0 
                me_s = (inner > 0 || is_outer_ladder) ? cluster_size_y(i) : -1
                
                if (inner == 0 && outer > 3) && (me_s > 0 && me_s < min_y_size_B1)# B1 and F1
                    continue
                end

                if (inner == 1 && outer > 3) && (me_s > 0 && me_s < min_y_size_B2)# B2 and F1
                    continue
                end
            end

            me_p = i_phi(hh,i)
            me_r = r_global(hh,i)
            
            z0_cut = 12. # cm
            hard_pt_cut = 0.5 # GeV
            min_radius = hard_pt_cut * 87.78 # cm ( 1 GeV track has 1 GeV/c / (e * 3.8 T) ~ 87 cm radius in a 3.8 T field)
            min_radius_2T4 = 4. * min_radius * min_radius

            pt_cut = let r2t4 = min_radius_2T4 , ri = me_r, hh = hh
                (j,idphi) -> begin
                    ro = r_global(hh,j)
                    dϕ = idphi * ((2*π)/(1<<16))
                    return dϕ^2 * (r2t4 - ri*ro) > (ro - ri)^2
                end
            end

            z0_cut_off = let ri = me_r , zi = me_z, max_r = max_r, z0_cut = z0_cut, hh = hh, pair_layer_id = pair_layer_id
                (j) -> begin
                zo = z_global(hh,j)
                ro = r_global(hh,j)
                dr = ro - ri
                return dr > max_r[pair_layer_id] || dr < 0 || abs(zi*ro - ri*zo) > z0_cut * dr
                end
            end
            
            z_size_cut = let hh = hh , outer = outer, inner = inner, max_dy_size_12 = max_dy_size_12, max_dy_size = max_dy_size, me_s = me_s, zi = me_z, ri = me_r, dz_dr_fact = dz_dr_fact, max_dy_pred = max_dy_pred
                (j) -> begin
                    only_barrel = outer < 4
                    so = cluster_size_y(hh,j)
                    dy = (inner == 0 ) ? max_dy_size_12 : max_dy_size
                    zo = z_global(hh,j)
                    ro = r_global(hh,j)
                    return only_barrel ? (me_s > 0 && so > 0 && abs(so - me_s) > dy) : (inner < 4 ) && (me_s > 0 ) && abs(me_s - Int(abs((zi - zo)/(ri - ro))*dz_dr_fact + 0.5)) > max_dy_pred
                end
            end
            i_phi_cut = phi_cuts[pair_layer_id]

            kl = bin(hh,Int16(me_p-i_phi_cut))
            kh = bin(hh,Int16(me_p+i_phi_cut))
            current_bin = kl
            while(current_bin != kh)
                p = begin_h(hh,current_bin+h_off)
                e = end_h(hh,current_bin+h_off)
                p += first
                for p ∈ p:e-1
                    oi = val(p)
                    @assert(oi >= offsets[outer+1])
                    @assert(oi < offsets[outer+2])
                    mo = detector_index(hh,oi)
                    if (mo > 2000)
                        continue
                    end
                    if (do_z0_cut && z0_cut_off(oi))
                        continue
                    end
                    
                    mo_p = i_phi(hh,oi)
                    i_dphi = abs(mo_p - me_p)

                    if i_dphi > i_phi_cut
                        continue
                    end

                    if do_cluster_cut && z_size_cut(oi)
                        continue
                    end

                    if do_pt_cut && pt_cut(oi,i_dphi)
                        continue
                    end

                    n_cells+=1
                    if(n_cells > max_num_of_doublets)
                        n_cells -=1
                        break
                    end
                    init(cells[n_cells],cell_neighbors,cell_tracks,hh,pair_layer_id,n_cells,i,oi)
                    push!(is_outer_hit_of_cell[oi],n_cells)
                end
                end



        end

    end
end