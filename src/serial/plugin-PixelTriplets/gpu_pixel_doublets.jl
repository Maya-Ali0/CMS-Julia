module gpuPixelDoublets
    using StaticArrays
    using ..caConstants
    using ..gpuCACELL
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
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
    function init_doublets(is_outer_hit_of_cell::Vector{OuterHitOfCell},n_hits::Integer,cell_neighbors::CellNeighborsVector,cell_neighbors_container::CellNeighbors,
                           cell_tracks::CellTracksVector,cell_tracks_container::CellTracks)
        @assert(!empty(is_outer_hit_of_cell))
        first = 1
        for i ∈ first:n_hits
            reset(is_outer_hit_of_cell[i])
        end
        construct(cell_neighbors,MAX_NUM_OF_ACTIVE_DOUBLETS,cell_neighbors_container)
        construct(cell_tracks,MAX_NUM_OF_ACTIVE_DOUBLETS,cell_tracks_container)
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
end