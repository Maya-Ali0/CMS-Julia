    using CUDA
    const MAX_NUM_MODULES::UInt32 = 2000
    function f(x)
        z = pointer(x)
        zz = CUDA.atomic_add!(z,1)
        @cuprintln(zz)
        return
    end
    x= CuArray([1,2,3,4,5])
    @cuda threads = 256 f(x)