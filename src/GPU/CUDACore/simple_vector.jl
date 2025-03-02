struct SimpleVector{T, A <: AbstractVector{T},S <: AbstractVector{UInt32}}
    m_size::S
    m_capacity::Int32
    m_data::A
    
end
function SimpleVector{T,A,S}(capacity::Integer) where {T ,A <: AbstractVector{T}, S <: AbstractVector{UInt32}}
    return SimpleVector(S([0]),Int32(capacity),A(undef,capacity))
end

function Base.push!(self::SimpleVector{T,A,S},element::T) where {T,A <: AbstractVector{T},S <: AbstractVector{UInt32}}
    size = pointer(self.m_size)
    CUDA.atomic_add!(size, UInt32(1))
    if(self.m_size[1] <= self.m_capacity)
        self.m_data[self.m_size[1]] = element
        return self.m_size[1]-1
    else
        CUDA.atomic_sub!(size, UInt32(1))
        return -1
    end
end

function extend!(self::SimpleVector{T},size::Integer = 1) where T <: AbstractVector  # check feels wrong
    self.m_size += size
    if(self.m_size <= self.m_capacity)
        return self.m_size - size
    else
        self.m_size -= size
        return -1 
    end
end

function shrink!(self::SimpleVector{T},size::Integer = 1) where T <: AbstractVector 
    previous_size = self.m_size
    if(previous_size >= size)
        self.m_size -= size
        return self.m_size
    else
        return -1
    end
end

Base.empty(self::SimpleVector{T}) where T <: AbstractVector  = self.m_size <= 0
full(self::SimpleVector{T}) where T <: AbstractVector  = self.m_size >= self.m_capacity
Base.getindex(self::SimpleVector{T},i::Integer) where T <: AbstractVector  = self.m_data[i]
reset!(self::SimpleVector{T}) where T <: AbstractVector  = (self.m_size = 0)
Base.length(self::SimpleVector{T,A,S}) where {T,A <: AbstractVector{T},S <: AbstractVector{UInt32}}  = self.m_capacity
capacity(self::SimpleVector{T}) where T <: AbstractVector  = self.m_capacity
data(self::SimpleVector{T}) where T <: AbstractVector  = self.m_data
set_data(self::SimpleVector{T},data::Vector{T}) where T <: AbstractVector  = self.m_data = data

using Adapt

Adapt.@adapt_structure SimpleVector