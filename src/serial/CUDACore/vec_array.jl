mutable struct VecArray{T,maxSize}
    m_data::MArray{Tuple{maxSize},T}
    m_size::Int
    VecArray{T,maxSize}() where {T,maxSize} = new(MArray{Tuple{maxSize},T}(undef),0)
end

function Base.push!(self::VecArray{T,maxSize},element::T) where {T,maxSize}
    self.m_size += 1
    current_size = self.m_size
    if(current_size <= maxSize)
        self.m_data[current_size] = element
        return current_size
    else
        self.m_size-=1
        return -1
    end
end

function Base.pop!(self::VecArray{T,maxSize}) where {T,maxSize}
    if(maxSize > 0)
        self.m_size -= 1
        return self.m_data[m_size+1]
    else
        return -1
    end
end

# function reset(self::VecArray{T,maxSize}) where {T,maxSize}
#     self.m_size = 0
# end

Base.last(self::VecArray{T,maxSize}) where {T,maxSize} = self.m_data[self.m_size]
full(self::VecArray{T,maxSize}) where {T,maxSize} = self.m_size == maxSize
empty(self::VecArray{T,maxSize}) where {T,maxSize} = self.m_size == 0
resize(self::VecArray{T,maxSize},size::Integer) where {T,maxSize} = (self.m_size = size) 
data(self::VecArray{T,maxSize}) where {T,maxSize} = self.m_data
capacity(self::VecArray{T,maxSize}) where {T,maxSize} = maxSize
reset!(self::VecArray{T,maxSize}) where {T,maxSize} = self.m_size = 0 
Base.getindex(self::VecArray{T,maxSize}, i::Int) where {T,maxSize} = self.m_data[i]
Base.length(self::VecArray{T,maxSize}) where {T,maxSize} = length(self.m_data)
begin_v(self::VecArray{T,maxSize}) where {T,maxSize} = 1
end_v(self::VecArray{T,maxSize}) where {T,maxSize} = maxSize

