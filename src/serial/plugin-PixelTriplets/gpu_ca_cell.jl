module gpuCACELL
    using ..caConstants
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    include("../CUDACore/vec_array.jl")

    const ptr_as_int = UInt64
    const Hits = TrackingRecHit2DSOAView
    const TmpTuple = VecArray{UInt32,6}
    
end