using CUDA
function kernel(x)
    potato = @cuStaticSharedMem(Int32,1)
    if threadIdx().x == 1
        potato[1] = 1000
        
        
        pot = CUDA.atomic_min!(pointer(potato,1),Int32(1))
        pot = CUDA.atomic_min!(pointer(potato,1),Int32(1))
        @cuprintln(pot)
        @cuprint(potato[1])
    end
    return
end

@cuda kernel(3)