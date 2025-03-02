using CUDA
const MAX_NUM_MODULES::UInt32 = 2000
function f(x)
    @cuprintln(x)
    @cuprintln(MAX_NUM_MODULES)
    return
end
x = CuArray([1,2,3])
z = CuArray([1,2,3])
@cuda threads = 256 f(3)