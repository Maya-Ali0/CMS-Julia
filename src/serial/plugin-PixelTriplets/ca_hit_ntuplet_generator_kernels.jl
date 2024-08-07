module cAHitNtupletGenerator
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    using Main::kernel_fill_hit_indices
    struct Counters
        n_events::UInt64
        n_hits::UInt64
        n_cells::UInt64
        n_tuples::UInt64
        n_fit_tracks::UInt64
        n_good_tracks::UInt64
        n_used_hits::UInt64
        n_dup_hits::UInt64
        n_killed_cells::UInt64
        n_empty_cells::UInt64
        n_zero_track_cells::UInt64
    end
    const HitsView = TrackingRecHit2DSOAView
    const HitsOnGPU = TrackingRecHit2DSOAView

    struct region
        max_tip::Float32 # cm
        min_pt::Float32 # Gev
        max_zip::Float32 # cm
    end
    struct quality_cuts
        # chi2 cut = chi2Scale * (chi2Coeff[0] + pT/GeV * (chi2Coeff[1] + pT/GeV * (chi2Coeff[2] + pT/GeV * chi2Coeff[3])))
        chi2_coeff::MArray{Tuple{4},Float32}
        chi2_max_pt::Float32
        chi2_scale::Float32
        triplet::region
        quadruplet::region
    end

    struct params
        on_gpu::Bool
        min_hits_per_ntuplet::UInt32
        max_num_of_doublets::UInt32
        use_riemann_fit::Bool
        fit_5_as_4::Bool
        include_jumping_forward_doublets::Bool
        early_fish_bone::Bool
        late_fish_bone::Bool
        ideal_conditions::Bool
        do_stats::Bool
        do_cluster_cut::Bool
        do_z0_cut::Bool
        do_pt_cut::Bool
        pt_min::Float32
        ca_theta_cut_barrel::Float32
        ca_theta_cut_forward::Float32
        hard_curv_cut::Float32
        dca_cut_inner_triplet::Float32
        dca_cut_outer_triplet::Float32
        cuts::quality_cuts
        function params(on_gpu::Bool, min_hits_per_ntuplet::Integer, max_num_of_doublets::Integer, use_riemann_fit::Bool,
               fit_5_as_4::Bool, include_jumping_forward_doublets::Bool, early_fish_bone::Bool, late_fish_bone::Bool,
               ideal_conditions::Bool, do_stats::Bool, do_cluster_cut::Bool, do_z0_cut::Bool, do_pt_cut::Bool,
               pt_min::AbstractFloat, ca_theta_cut_barrel::AbstractFloat, ca_theta_cut_forward::AbstractFloat, hard_curv_cut::AbstractFloat,
               dca_cut_inner_triplet::AbstractFloat, dca_cut_outer_triplet::AbstractFloat, cuts::quality_cuts)
               new(on_gpu, min_hits_per_ntuplet, max_num_of_doublets, use_riemann_fit,
               fit_5_as_4, include_jumping_forward_doublets, early_fish_bone, late_fish_bone,
               ideal_conditions, do_stats, do_cluster_cut, do_z0_cut, do_pt_cut,
               pt_min, ca_theta_cut_barrel, ca_theta_cut_forward, hard_curv_cut,
               dca_cut_inner_triplet, dca_cut_outer_triplet, cuts)
        end
    end

    cuts = quality_cuts(MArray{Tuple{4},Float32}((0.68177776, 0.74609577, -0.08035491, 0.00315399)),# polynomial coefficients for the pT-dependent chi2 cut
                        10.,                                                                        # max pT used to determine the chi2 cut
                        30.,                                                                        # chi2 scale factor: 30 for Broken line Fit, 45 for Riemann Fit
                        region(0.3, # |Tip| < 0.3 cm                                                # Regional cuts for Triplets
                               0.5, # pT > 0.5 GeV
                               12.0), # |Zip| < 12.0 cm
                        region(0.5, # |Tip| < 0.5 cm                                                # Reginal cuts for quadruplets    
                               0.3, # pT > 0.3 GeV
                               12.0)) # |Zip| < 12.0 cm
    
    
    struct ca_hit_ntuplet_generator_kernels
        cell_storage::Vector{UInt8}
        
    end
    function fill_hit_det_indices(hv::TrackingRecHit2DSOAView, tracks_d::TkSoA)
        kernel_fill_hit_indices(tracks_d.hit_indices, hv, tracks_d.det_indices)
    end
end