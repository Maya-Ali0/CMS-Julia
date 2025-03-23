using StaticArrays
using Test
struct VecArray{T,maxSize}
    m_data::MArray{Tuple{maxSize},T}
    m_size::Base.RefValue{Int}
    VecArray{T,maxSize}() where {T,maxSize} = new(MArray{Tuple{maxSize},T}(undef),Ref(0))
end

function push!(v::VecArray{T, maxSize}, x::T) where {T,maxSize}
    @boundscheck (v.m_size[] < StaticArrays.Size(v.m_data)[1]) || error("VecArray is full")
    v.m_size[] += 1
    v.m_data[v.m_size[]] = x
end

const MAX_CELLS_PER_HIT = 2 
const OuterHitOfCell = VecArray{UInt32,MAX_CELLS_PER_HIT}
struct CAHitNTupletGeneratorKernels
    device_is_outer_hit_of_cell::Vector{OuterHitOfCell}
end

CAHitNTupletGeneratorKernels(s) = CAHitNTupletGeneratorKernels(fill(OuterHitOfCell(), s))
a = CAHitNTupletGeneratorKernels(15)
push!(a.device_is_outer_hit_of_cell[1], UInt32(1))
push!(a.device_is_outer_hit_of_cell[2], UInt32(2))
print(a)
# @allocations c = CAHitNTupletGeneratorKernels(150_00) 
# # -> 5 allocations

# # use @timev instead of @allocations to get more information:
# b = CAHitNTupletGeneratorKernels(150_00);
# @allocations push!(c.device_is_outer_hit_of_cell[1], UInt32(1))

# @testset "Tests" begin
#     push!(a.device_is_outer_hit_of_cell[1], UInt32(1))
#     # check the modification of a:
#     @test a.device_is_outer_hit_of_cell[1].m_size[] == 1 && a.device_is_outer_hit_of_cell[1].m_data[1] == 1
#     # check that b was not modified together with a:
#     @test b.device_is_outer_hit_of_cell[1].m_size[] == 0
# end
using StaticArrays
using CUDA
function testing_shared_memory()
    ws = @cuStaticSharedMem(UInt32,1024)
    # y = CUVector{UInt32}(undef,10)
    # x = zeros(Int32,5)
    # @cuprint(typeof(v))
    # @cuprint(ws[threadIdx().x])
    x = HistoContainer()
    @cuprint(x.bins[1])
    return
end

@cuda threads = 5 testing_shared_memory()


struct HistoContainer{U <: AbstractArray{UInt32},V <: AbstractArray{UInt32}}
    off::U # goes from bin 1 to bin N_BINS*N_HISTS + 1 
    bins::V # holds indices to the values placed within a certain bin that are of type I. Indices for bins range from 1 to SIZE
    psws::Int32 # prefix scan working place
end