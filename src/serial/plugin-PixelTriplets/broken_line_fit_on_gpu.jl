module BrokenLineFitOnGPU

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..PixelGPU_h: ParamsOnGPU, detParams
using ..RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h
using ..RecoPixelVertexing_PixelTrackFitting_plugins_HelixFitOnGPU_h: HelixFitOnGPU, get_tuples_d

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView, detector_index, cpe_params, xerr_local, yerr_local, x_global, y_global, z_global
using ..Tracks: TrackSOA
using ..histogram: OneToManyAssoc, size, begin_h, n_bins
using ..caConstants: TupleMultiplicity
using ..SOA_h: toGlobal, SOAFrame

#Type aliases
const hindex_type = UInt16
const tindex_type = UInt16
const HitsOnGPU = TrackingRecHit2DSOAView
const Tuples = OneToManyAssoc{hindex_type,32 * 1024,32 * 1024 * 5}
const OutputSoA = TrackSOA
const maxTuples = 24 * 1024


function kernelBLFastFit(N::Int,
    foundNtuplets::Tuples,
    tupleMultiplicity::TupleMultiplicity,
    hhp::HitsOnGPU,
    phits::Vector{Float64},
    phits_ge::Vector{Float32},
    pfast_fit::Vector{Float64},
    nHits::UInt32,
    offset::UInt32)

    hitsInFit = N
    @assert(hitsInFit <= nHits)
    @assert hhp !== nothing
    @assert !isempty(pfast_fit)
    @assert !isnothing(foundNtuplets)
    @assert !isnothing(tupleMultiplicity)

    local_start = 1
    maxNumberOfConcurrentFits = 24 * 1024
    for local_idx in local_start:maxNumberOfConcurrentFits
        tuple_idx = local_idx + offset

        if tuple_idx >= size(tupleMultiplicity, nHits)
            break
        end

        # tkid = begin_h(tupleMultiplicity, (nHits + tuple_idx - 1))
        tkid = tupleMultiplicity.bins[tupleMultiplicity.off[nHits]+tuple_idx]

        @assert tkid < n_bins(foundNtuplets)

        println("nHits: ", nHits)
        println("nt: ", maxNumberOfConcurrentFits)
        println("tkid:", tkid)
        println("n_bins(foundNtuplets):", n_bins(foundNtuplets))
        println("size(foundNtuplets, tkid): ", size(foundNtuplets, tkid))

        @assert size(foundNtuplets, tkid) == nHits


        # hits = reshape(phits[:, local_idx:local_idx+3*N-1], 3, N)
        start_idx = (local_idx - 1) * (3 * N) + 1
        end_idx = start_idx + (3 * N) - 1

        hits = reshape(phits[start_idx:end_idx], 3, N)

        fast_fit = phits[local_idx:local_idx+3]

        # hits_ge = reshape(phits_ge[:, local_idx:local_idx+6*N-1], 6, N)
        start_idx_ge = (local_idx - 1) * (6 * N) + 1
        end_idx_ge = start_idx_ge + (6 * N) - 1

        hits_ge = reshape(phits_ge[start_idx_ge:end_idx_ge], 6, N)

        # hitId = foundNtuplets.bins[foundNtuplets.off[nHits]]
        start_idx = foundNtuplets.off[tkid] # +1 for 1-based indexing in Julia
        end_idx = foundNtuplets.off[tkid+1]    # Assuming `off` includes an end marker for the last track
        hitId = foundNtuplets.bins[start_idx:end_idx]  # Slice to get all hit IDs for the track

        for i in 1:hitsInFit
            hit = hitId[i] - 1
            println("hitId: ", hit)
            ge = zeros(Float32, 6)

            det_index = detector_index(hhp, hit)
            det_params = detParams(cpe_params(hhp), UInt32(det_index))
            frame = det_params.frame
            toGlobal(frame, Float32(xerr_local(hhp, UInt32(hit))), 0.0f0, yerr_local(hhp, UInt32(hit)), ge)

            hits[:, i] .= [x_global(hhp, UInt32(hit)), y_global(hhp, UInt32(hit)), z_global(hhp, UInt32(hit))]
            hits_ge[:, i] .= ge[1:6]

            println(hits[:, i])
            println(hits_ge[:, i])
        end

        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Fast_fit(hits, fast_fit)

        @assert !isnan(fast_fit[1])
        @assert !isnan(fast_fit[2])
        @assert !isnan(fast_fit[3])
        @assert !isnan(fast_fit[4])
    end
end

function kernelBLFit(N::Int,
    tupleMultiplicity::TupleMultiplicity,
    B::Float64,
    results::OutputSoA,
    phits::Vector{Float64},
    phits_ge::Vector{Float32},
    pfast_fit::Vector{Float64},
    nHits::UInt32,
    offset::UInt32)

    @assert N <= nHits
    @assert results !== nothing
    @assert !isempty(pfast_fit)

    local_start = 1
    maxNumberOfConcurrentFits = 24 * 1024
    for local_idx in local_start:maxNumberOfConcurrentFits
        tuple_idx = local_idx + offset
        if tuple_idx >= length(tupleMultiplicity)
            break
        end

        tkid = tupleMultiplicity[tuple_idx]

        # Explicit slicing instead of @view
        hits = reshape(phits[local_idx:local_idx+3*N-1], 3, N)
        fast_fit = pfast_fit[local_idx:local_idx+3]
        hits_ge = reshape(phits_ge[local_idx:local_idx+6*N-1], 6, N)

        data = Main.RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.PreparedBrokenLineData(
            1,                          # q
            zeros(Float64, 2, N),       # radii, 2xN matrix
            zeros(Float64, N),          # s, Vector of length N
            zeros(Float64, N),          # S, Vector of length N
            zeros(Float64, N),          # Z, Vector of length N
            zeros(Float64, N)           # VarBeta, Vector of length N
        )
        Jacob = zeros(Float64, 3, 3)

        circle = RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h.circle_fit()
        line = RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h.line_fit()

        Main.RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.prepare_broken_line_data(hits, fast_fit_results, B, data)
        Main.RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Line_fit(hits_ge, fast_fit_results, B, data, line)
        Main.RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Circle_fit(hits, hits_ge, fast_fit_results, B, data, circle)

        copyFromCircle!(
            results.stateAtBS,
            circle.par,        # Circle parameters
            circle.cov,        # Circle covariance
            line.par,          # Line parameters
            line.cov,          # Line covariance
            1.0f0 / B,         # Magnetic field scaling factor
            tkid               # Track ID
        )

        results.pt[tkid] = B / abs(circle.par[3])
        results.eta[tkid] = asinh(line.par[1])
        results.chi2[tkid] = (circle.chi2 + line.chi2) / (2 * N - 5)
    end
end


# BrokenLineFitonGPU.cc

function launchBrokenLineKernelsOnCPU(fitter::HelixFitOnGPU, hv::HitsOnGPU, hitsInFit::UInt32, maxNumberOfTuples::UInt32)
    tuples_d = get_tuples_d(fitter)
    @assert !isnothing(tuples_d)
    maxNumberOfConcurrentFits = 24 * 1024
    hitsGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 3 * 4)
    hits_geGPU = Vector{Float32}(undef, maxNumberOfConcurrentFits * 6 * 4)
    fast_fit_resultsGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 4)

    for offset in 1:maxNumberOfConcurrentFits:maxNumberOfTuples
        kernelBLFastFit(3, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(3), UInt32(offset))
        kernelBLFit(3, fitter.tuple_multiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(3), UInt32(offset))

        kernelBLFastFit(4, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(4), UInt32(offset))
        kernelBLFit(4, fitter.tuple_multiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(4), UInt32(offset))

        if fit5as4
            kernelBLFastFit(4, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(5), UInt32(offset))
            kernelBLFit(4, fitter.tuple_multiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(5), UInt32(offset))
        else
            kernelBLFastFit(5, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(5), UInt32(offset))
            kernelBLFit(5, fitter.tuple_multiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, UInt32(5), UInt32(offset))
        end
    end
end

end