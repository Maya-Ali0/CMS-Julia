# # TODO: Fix the last test cases
# module CUDADataFormatsCommonHeterogeneousSoA_H

# # Reference types and smart pointers (like Ref and Base.RefValue) equivalent to std::unique_ptr
# struct HeterogeneousSoA{T}
#     std_ref::Base.RefValue{Union{T, Nothing}}
    
#     function HeterogeneousSoA{T}() where T
#         new(Base.RefValue{Union{T, Nothing}}(nothing))
#     end

#     function HeterogeneousSoA{T}(value::T) where T
#         new(Base.RefValue{Union{T, Nothing}}(value))
#     end
# end

# function get(soa::HeterogeneousSoA{T}) where T
#     return soa.std_ref[]
# end

# # Overload getproperty to mimic the -> operator
# function Base.getindex(soa::HeterogeneousSoA{T}) where T
#     return get(soa)
# end

# # Overload getproperty to mimic the -> operator
# function Base.getproperty(soa::HeterogeneousSoA{T}, sym::Symbol) where T
#     if sym === :value
#         return get(soa)
#     else
#         return getfield(soa, sym)
#     end
# end

# function move!(dest::HeterogeneousSoA{T}, src::HeterogeneousSoA{T}) where T
#     dest.std_ref[] = src.std_ref[]
#     src.std_ref[] = nothing
# end
 

# # using .CUDADataFormatsCommonHeterogeneousSoA_H

# # # Example usage
# # soa = CUDADataFormatsCommonHeterogeneousSoA_H.HeterogeneousSoA{Int}(42)
# # println(CUDADataFormatsCommonHeterogeneousSoA_H.get(soa))  # Output: 42

# # soa2 = CUDADataFormatsCommonHeterogeneousSoA_H.HeterogeneousSoA{Int}()
# # println(CUDADataFormatsCommonHeterogeneousSoA_H.get(soa2))  # Output: nothing

# # CUDADataFormatsCommonHeterogeneousSoA_H.move!(soa2, soa)
# # println(CUDADataFormatsCommonHeterogeneousSoA_H.get(soa2))  # Output: 42
# # println(CUDADataFormatsCommonHeterogeneousSoA_H.get(soa))   # Output: nothing 

# struct CPUTraits{Q}
#     unique_ptr::Base.RefValue{Q}

#     function CPUTraits{Q}() where Q
#         new(Base.RefValue{Q}())
#     end

#     function CPUTraits{Q}(value::Q) where Q
#         new(Base.RefValue{Q}(value))
#     end
# end

# function make_unique_of_value(cpu::CPUTraits, ::Type{Q},number ) where Q
#     return Base.RefValue(number)
# end

# function make_unique(cpu::CPUTraits, ::Type{Q}, size::Int) where Q
#     return Base.RefValue([Q(0) for _ in 1:size])
# end

# function make_device_unique(cpu::CPUTraits, ::Type{Q}, size::Int) where Q
#     return Base.RefValue([Q(0) for _ in 1:size])
# end


# function make_host_unique(cpu::CPUTraits, ::Type{Q}) where Q
#     return Ref(Q(0))
# end

# function make_device_unique(cpu::CPUTraits, ::Type{Q}) where Q
#     return Ref(Q(0))
# end

# function make_device_unique(cpu::CPUTraits, ::Type{Q}, size::Int) where Q
#     return Ref([Q(0) for _ in 1:size])
# end


# # # Test case
# # function test_cputraits_functions()
# #     cpu_traits = CPUTraits{Int}()

# #     unique_value = make_unique(cpu_traits, Int)
# #     @assert unique_value[] == 0

# #     unique_array = make_unique(cpu_traits, Int, 5)
# #     @assert unique_array[] == [0, 0, 0, 0, 0]

# #     host_unique_value = make_host_unique(cpu_traits, Int)
# #     @assert host_unique_value[] == 0

# #     device_unique_value = make_device_unique(cpu_traits, Int)
# #     @assert device_unique_value[] == 0

# #     device_unique_array = make_device_unique(cpu_traits, Int, 3)
# #     @assert device_unique_array[] == [0, 0, 0]

# #     println("All tests passed")
# # end

# # test_cputraits_functions()

# struct HeterogeneousSoAImpl{T,Traits}
#     m_ptr::Base.RefValue{T} 

#     function HeterogeneousSoAImpl{T,Traits}(p::Base.RefValue{T}) where {T,Traits}
#         new(p)
#     end

#     function HeterogeneousSoAImpl{T,Traits}() where {T,Traits}
#         new(Base.RefValue{T}())
#     end

#     function HeterogeneousSoAImpl{T,Traits}(stream) where {T,Traits}
#         println(make_unique_of_value(Traits{T}(),T, stream))
#         new(make_unique_of_value(Traits{T}(),T, stream))
#     end

# end

# function get(soa::HeterogeneousSoAImpl{T}) where T
#     return soa.m_ptr[]
# end

# HeterogeneousSoACPU{T} = HeterogeneousSoAImpl{T, CPUTraits}

# function test_heterogeneous_soa_impl()
#     cpu_traits = CPUTraits{Int}()
#     cpu_traits_string = CPUTraits{string}()

#     soa_default = HeterogeneousSoAImpl{Int, CPUTraits}()
#     println(get(soa_default))

#     soa_value = HeterogeneousSoAImpl{Int, CPUTraits}(42)
#     stream = "dummy stream" 
#     soa_stream = HeterogeneousSoAImpl{string, CPUTraits}(stream)
#     soa_cpu_default = HeterogeneousSoACPU{Int}()
# end

# test_heterogeneous_soa_impl()

# end
