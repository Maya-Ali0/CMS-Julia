using .CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using .cAHitNtupletGenerator:Counters, Params, CAHitNTupletGeneratorKernels, build_doublets, launch_kernels
struct CAHitNtupletGeneratorOnGPU
    m_params::Params 
    m_counters::Counters
    function CAHitNtupletGeneratorOnGPU()
        new(
            Params(
                false,             # onGPU
               3,                 # minHitsPerNtuplet,
               458752,            # maxNumberOfDoublets
               false,             # useRiemannFit
               true,              # fit5as4,
               true,              #includeJumpingForwardDoublets
               true,              # earlyFishbone
               false,             # lateFishbone
               true,              # idealConditions
               false,             # fillStatistics
               true,              # doClusterCut
               true,              # doZ0Cut
               true,              # doPtCut
               0.899999976158,    # ptmin
               0.00200000009499,  # CAThetaCutBarrel
               0.00300000002608,  # CAThetaCutForward
               0.0328407224959,   # hardCurvCut
               0.15000000596,     # dcaCutInnerTriplet
               0.25,              # dcaCutOuterTriplet
               cAHitNtupletGenerator.cuts
            )
            ,
            Counters()
        )
    end
end

function make_tuples(self::CAHitNtupletGeneratorOnGPU,hits_d::TrackingRecHit2DHeterogeneous,b_field::AbstractFloat,file)
    # Create PixelTrackHeterogeneous
    # soa = tracks.get()
    kernels = CAHitNTupletGeneratorKernels(self.m_params) # m 
    kernels.counters = self.m_counters
    build_doublets(kernels,hits_d,file)
    # launch_kernels(kernels,hits_d)
end