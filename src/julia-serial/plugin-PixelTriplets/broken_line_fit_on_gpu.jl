module BrokenLineFitOnGPU

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..PixelGPU_h: ParamsOnGPU, detParams
using ..RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h
using ..RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h
using ..RecoPixelVertexing_PixelTrackFitting_plugins_HelixFitOnGPU_h: HelixFitOnGPU, get_tuples_d

using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView, detector_index, cpe_params, xerr_local, yerr_local, x_global, y_global, z_global
using ..Tracks: TrackSOA
using ..histogram: OneToManyAssoc, size, begin_h, n_bins
using ..caConstants: TupleMultiplicity
using ..SOA_h: toGlobal, SOAFrame
using ..CUDADataFormatsTrackTrajectoryStateSOA_H: copyFromCircle!

# Type aliases
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
    offset::UInt32,
    log_file)

    hitsInFit = N
    @assert hitsInFit <= nHits
    @assert hhp !== nothing
    @assert !isnothing(foundNtuplets)
    @assert !isnothing(tupleMultiplicity)

    local_start = 1
    maxNumberOfConcurrentFits = 24 * 1024

    ge_tmp = Vector{Float32}(undef, 6)

    for local_idx in local_start:maxNumberOfConcurrentFits
        tuple_idx = local_idx + offset

        if tuple_idx >= size(tupleMultiplicity, nHits) + 1
            break
        end

        tkid = tupleMultiplicity.bins[tupleMultiplicity.off[nHits]+tuple_idx]

        start_idx = (local_idx - 1) * (3 * N) + 1
        end_idx = start_idx + (3 * N) - 1
        hits   = @views reshape(view(phits, start_idx:end_idx),3,N)

        fstart = (local_idx-1)*4 + 1
        find = fstart + 4 - 1
        fast_fit = @views view(pfast_fit, fstart:find)

        start_idx_ge = (local_idx - 1) * (6 * N) + 1
        end_idx_ge = start_idx_ge + (6 * N) - 1
        hits_ge = @views reshape(view(phits_ge,  start_idx_ge:end_idx_ge),  6, N)

        start_idx = foundNtuplets.off[tkid]
        end_idx = foundNtuplets.off[tkid+1] - 1
        hitId = @views foundNtuplets.bins[start_idx:end_idx]

        for i in 1:hitsInFit
            hit = hitId[i]
            det_index = detector_index(hhp, hit)
            det_params = detParams(cpe_params(hhp), UInt32(det_index + 1))
            frame = det_params.frame
            toGlobal(frame, Float32(xerr_local(hhp, UInt32(hit))), 0.0f0, yerr_local(hhp, UInt32(hit)), ge_tmp)

            hits[1, i] = x_global(hhp, hit)
            hits[2, i] = y_global(hhp, hit)
            hits[3, i] = z_global(hhp, hit)

            @inbounds for j in 1:6
                hits_ge[j, i] = ge_tmp[j]
            end
        end

        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Fast_fit(hits, fast_fit)
        
        #@assert !isnan(fast_fit[1])
        #@assert !isnan(fast_fit[2])
        #@assert !isnan(fast_fit[3])
        #@assert !isnan(fast_fit[4])
    end
    return Nothing   # Return the full array of fast fits
end
function kernelBLFit(N::Int,
    tupleMultiplicity::TupleMultiplicity,
    B::Float64,
    results::OutputSoA,
    phits::Vector{Float64},
    phits_ge::Vector{Float32},
    fast_fit_results::Vector{Float64},
    nHits::UInt32,
    offset::UInt32,
    log_file)

    @assert N <= nHits
    @assert results !== nothing
    @assert !isempty(fast_fit_results)

    maxNumberOfConcurrentFits = 24 * 1024
    local_start = 1

    circle_fit_results = Float64[]
    line_fit_results = Float64[]
    pt_results = Float64[]
    eta_results = Float64[]
    chi2_results = Float64[]

    for local_idx in local_start:maxNumberOfConcurrentFits
        tuple_idx = local_idx + offset
        if tuple_idx >= size(tupleMultiplicity, nHits) + 1
            break
        end

        tkid = tupleMultiplicity.bins[tupleMultiplicity.off[nHits]+tuple_idx]
        # println(log_file, "kernelBLFit INPUT (N=", N, ", tkid=", tkid, ", B=", B, ") - fast_fit:", fast_fit_results[(local_idx-1)*4+1:(local_idx-1)*4+4])

        start_idx = (local_idx - 1) * (3 * N) + 1
        end_idx = start_idx + (3 * N) - 1
        hits = reshape(phits[start_idx:end_idx], 3, N)

        fast_fit = fast_fit_results[(local_idx-1)*4+1:(local_idx-1)*4+4]

        start_idx_ge = (local_idx - 1) * (6 * N) + 1
        end_idx_ge = start_idx_ge + (6 * N) - 1
        hits_ge = reshape(phits_ge[start_idx_ge:end_idx_ge], 6, N)

        data = RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.PreparedBrokenLineData(
            1,
            zeros(Float64, 2, N),
            zeros(Float64, N),
            zeros(Float64, N),
            zeros(Float64, N),
            zeros(Float64, N)
        )

        circle = RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h.circle_fit()
        line = RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h.line_fit()

        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.prepare_broken_line_data(hits, fast_fit, B, data)
        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Line_fit(hits_ge, fast_fit, B, data, line)
        RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h.BL_Circle_fit(hits, hits_ge, fast_fit, B, data, circle)

        copyFromCircle!(results.stateAtBS, circle.par, circle.cov, line.par, line.cov, 1.0f0 / B, tkid)
        results.pt[tkid] = B / abs(circle.par[3])
        results.eta[tkid] = asinh(line.par[1])
        results.chi2[tkid] = (line.chi2 + circle.chi2) / (2 * N - 5)

        append!(circle_fit_results, circle.par)
        append!(line_fit_results, line.par)
        append!(pt_results, results.pt[tkid])
        append!(eta_results, results.eta[tkid])
        append!(chi2_results, results.chi2[tkid])

        # println(log_file, "Track tkid=", tkid, " Circle Fit:", circle.par)
        # println(log_file, "Track tkid=", tkid, " Line Fit:", line.par)
        # println(log_file, "Track tkid=", tkid, " pt:", results.pt[tkid])
        # println(log_file, "Track tkid=", tkid, " eta:", results.eta[tkid])
        # println(log_file, "Track tkid=", tkid, " chi2:", results.chi2[tkid])
        # println(log_file, "Track tkid=", tkid, " circle.chi2:", circle.chi2)
        # println(log_file, "Track tkid=", tkid, " line.chi2:", line.chi2)
        # flush(log_file)
    end

    return circle_fit_results, line_fit_results, pt_results, eta_results, chi2_results
end


function launchBrokenLineKernelsOnCPU(fitter::HelixFitOnGPU, hv::HitsOnGPU, hitsInFit::UInt32, maxNumberOfTuples::UInt32)
    tuples_d = get_tuples_d(fitter)
    @assert !isnothing(tuples_d)
    maxNumberOfConcurrentFits = 24 * 1024
    hitsGPU = Vector{Float64}(undef, maxNumberOfConcurrentFits * 3 * 4)
    hits_geGPU = Vector{Float32}(undef, maxNumberOfConcurrentFits * 6 * 4)
    fast_fit = Vector{Float64}(undef, maxNumberOfConcurrentFits * 4)
    offset = 0

    kernelBLFastFit(3, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit, UInt32(3), UInt32(offset), nothing)

    #kernelBLFit(
    #    3, fitter.tuple_multiplicity_d, Float64(fitter.b_field), fitter.output_soa_d,
    #    hitsGPU, hits_geGPU, fast_fit, UInt32(3), UInt32(offset), nothing
    #)

    #fast_fit_resultsGPU, hits_results, hits_ge_results = kernelBLFastFit(4, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit, UInt32(4), UInt32(offset), nothing)

    #circle_fit_results, line_fit_results, pt_results, eta_results, chi2_results = kernelBLFit(
    #    4, fitter.tuple_multiplicity_d, Float64(fitter.b_field), fitter.output_soa_d,
    #    hits_results, hits_ge_results, fast_fit_resultsGPU, UInt32(4), UInt32(offset), nothing
    #)


    #if (fitter.fit5as4)
    #    fast_fit_resultsGPU, hits_results, hits_ge_results = kernelBLFastFit(4, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit, UInt32(5), UInt32(offset), nothing)

    #    circle_fit_results, line_fit_results, pt_results, eta_results, chi2_results = kernelBLFit(
    #        4, fitter.tuple_multiplicity_d, Float64(fitter.b_field), fitter.output_soa_d,
    #        hits_results, hits_ge_results, fast_fit_resultsGPU, UInt32(5), UInt32(offset), nothing
    #    )
    #else
    #    fast_fit_resultsGPU, hits_results, hits_ge_results = kernelBLFastFit(5, tuples_d, fitter.tuple_multiplicity_d, hv, hitsGPU, hits_geGPU, fast_fit, UInt32(5), UInt32(offset), log_file)

    #    circle_fit_results, line_fit_results, pt_results, eta_results, chi2_results = kernelBLFit(
    #        5, fitter.tuple_multiplicity_d, Float64(fitter.b_field), fitter.output_soa_d,
    #        hits_results, hits_ge_results, fast_fit_resultsGPU, UInt32(5), UInt32(offset), log_file
    #    )
    #end
end

end
