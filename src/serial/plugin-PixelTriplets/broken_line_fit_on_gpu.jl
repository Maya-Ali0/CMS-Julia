module BrokenLineFitOnGPU

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..PixelGPU_h: ParamsOnGPU, detParams
using ..RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h
using ..RecoPixelVertexing_PixelTrackFitting_plugins_HelixFitOnGPU_h: HelixFitOnGPU, get_tuples_d

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView
using ..Tracks: TrackSOA
using ..histogram: OneToManyAssoc

#Type aliases
const hindex_type = UInt16
const tindex_type = UInt16
const HitsOnGPU = TrackingRecHit2DSOAView
const Tuples = OneToManyAssoc{hindex_type,32 * 1024,32 * 1024 * 5}
const OutputSoA = TrackSOA
const maxTuples = 24 * 1024
const TupleMultiplicity = OneToManyAssoc{tindex_type,8,maxTuples}


function kernelBLFastFit(N::Int,
    foundNtuplets::Tuples,
    tupleMultiplicity::Vector{Int},
    hhp::HitsOnGPU,
    phits::Matrix{Float64},
    phits_ge::Matrix{Float32},
    pfast_fit::Vector{Float64},
    nHits::UInt32,
    offset::UInt32)

    hitsInFit = N
    @assert(hitsInFit <= nHits)
    @assert hhp !== nothing
    @assert !isempty(pfast_fit)
    @assert !isempty(foundNtuplets)
    @assert !isempty(tupleMultiplicity)

    local_start = 1

    for local_idx in local_start:min(maxTuples, length(tupleMultiplicity) - offset)
        tuple_idx = local_idx + offset
        if tuple_idx >= length(tupleMultiplicity)
            break
        end
        tkid = tupleMultiplicity[tuple_idx]
        @assert tkid < length(foundNtuplets)
        @assert length(foundNtuplets[tkid]) == nHits

        # Directly slice and reshape for hits
        hits = reshape(phits[:, local_idx:local_idx+3*N-1], 3, N)

        # Directly slice for the fast fit vector
        fast_fit = phits[local_idx:local_idx+3]

        # Directly slice and reshape for hits_ge
        hits_ge = reshape(phits_ge[:, local_idx:local_idx+6*N-1], 6, N)

        for i in 1:hitsInFit
            hit = foundNtuplets[tkid][i]
            ge = zeros(Float32, 6)

            det_index = hhp.detectorIndex(hit)
            det_params = detParams(hhp.cpeParams(), det_index)
            det_params.frame.toGlobal(hhp.xerrLocal(hit), 0.0f0, hhp.yerrLocal(hit), ge)

            hits[:, i] .= [xGlobal(hhp, hit), yGlobal(hhp, hit), zGlobal(hhp, hit)]
            hits_ge[:, i] .= ge[1:6]
        end

        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Fast_fit(hits, fast_fit)

        @assert !isnan(fast_fit[1])
        @assert !isnan(fast_fit[2])
        @assert !isnan(fast_fit[3])
        @assert !isnan(fast_fit[4])
    end
end

function kernelBLFit(N::Int,
    tupleMultiplicity::Vector{Int},
    B::Float64,
    results::OutputSoA,
    phits::Matrix{Float64},
    phits_ge::Matrix{Float32},
    pfast_fit::Vector{Float64},
    nHits::UInt32,
    offset::UInt32)

    @assert N <= nHits
    @assert results !== nothing
    @assert !isempty(pfast_fit)

    local_start = 1

    for local_idx in local_start:min(maxTuples, length(tupleMultiplicity) - offset)
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
    println(tuples_d)
    @assert !isnothing(tuples_d)

    hitsGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 3 * 4)
    hits_geGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 6 * 4)
    fast_fit_resultsGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 4)

    for offset in 0:maxNumberOfConcurrentFits:maxNumberOfTuples
        kernelBLFastFit(3, tuples_d, tupleMultiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, hitsInFit, offset)
        kernelBLFit(3, tupleMultiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, hitsInFit, offset)

        kernelBLFastFit(4, tuples_d, tupleMultiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 4, offset)
        kernelBLFit(4, tupleMultiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 4, offset)

        if fit5as4
            kernelBLFastFit(4, tuples_d, tupleMultiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 5, offset)
            kernelBLFit(4, tupleMultiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 5, offset)
        else
            kernelBLFastFit(5, tuples_d, tupleMultiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 5, offset)
            kernelBLFit(5, tupleMultiplicity_d, bField_, outputSoa_d, hitsGPU, hits_geGPU, fast_fit_resultsGPU, 5, offset)
        end
    end
end

end