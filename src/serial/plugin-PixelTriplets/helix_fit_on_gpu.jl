module RecoPixelVertexing_PixelTrackFitting_plugins_HelixFitOnGPU_h
    using ..RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h
    using ..caConstants
    using LinearAlgebra

    module Rfit
        @inline function max_number_of_concurrent_fits()
            return MAX_NUM_TUPLES #from ca_constants
        end
        @inline function stride()
            return max_number_of_concurrent_fits()
        end
        Matrix3xNd{N} = Matrix{Float64}(undef, 3, N)
        Matrix6xNf{N} = Matrix{Float32}(undef, 6, N)
        function Map3xNd{N}(data::AbstractVector{Float64}, N::Int)
            return reshape(view(data, 1:stride():stride()*3*N), 3, N)
        end
        function Map6xNf{N}(data::AbstractVector{Float32}, N::Int)
            return reshape(view(data, 1:stride():stride()*6*N), 6, N)
        end
        function Map4d(data::AbstractVector{Float64})
            return @view data[1:stride():end]
        end
    end

    HitsView = TrackingRecHit2DSOAView
    Tuples = HitContainer
    OutputSoA = TrackSoA
    TupleMultiplicity = TupleMultiplicity

    struct HelixFitOnGPU
        maxNumberOfConcurrentFits_ = max_number_of_concurrent_fits()
        tuples_d::Tuples
        tuple_multiplicity_d::TupleMultiplicity
        output_soa_d::OutputSoA
        b_field::Float64
        fit_5_as_4::Bool

        function HelixFitOnGPU(bf::Float64, fit5as4::Bool)
            new(max_number_of_concurrent_fits(), Tuples(),TupleMultiplicity(), OutputSoA(), bf, fit5as4 )
        end
    end

    function set_b_field(self::HelixFitOnGPU ,bf::Float64)
        self.b_field = bf
    end
    function launch_riemann_kernels(self::HelixFitOnGPU, hv::HitsView, nhits::UInt32, maxNumberOfTuples::UInt32)
    end
    function launch_broken_line_Kernels(self::HelixFitOnGPU, hv::HitsView, nhits::UInt32, maxNumberOfTuples::UInt32)
    end
    function allocateOnGPU(self::HelixFitOnGPU, tuples::Tuples, tupleMultiplicity::TupleMultiplicity, outputSoA::OutputSoA)
        @assert(tuples)
        @assert(tupleMultiplicity)
        @assert(outputSoA)
        new(max_number_of_concurrent_fits(), tuples, tupleMultiplicity, outputSoA, 0, 0)
    end
    function deallocateOnGPU(self::HelixFitOnGPU, )
    end


end