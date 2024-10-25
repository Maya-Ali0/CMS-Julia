using InteractiveUtils
# Output in a txt file
# opening file with .txt extension and in write mode
 
# let the ans be the output of a question
# struct Pair{T,U}
#     a::T
#     b::U
# end

# function temp()
#     x = 3
#     y = 2
#     return (x,y)
# end

# function test()
#     z =  0
#     y = 0
#     pot{T,U} = Pair{T,U}
# for i ∈ 1:10000
     
# end
# end

# @code_llvm test()
# function f()
#     for j in 1:100
#         a = (0x2,0xC,0xF0,0xFF00,0xFFFF0000)
#         acc = 0
#         for i in 1:5
#             acc += a[i]
#         end
#     end
# end

# @time f()

mutable struct CircleEq{T}
    m_xp::T
    m_yp::T
    m_c::T
    m_alpha::T
    m_beta::T
    CircleEq{T}() where T = new(0,0,0,0,0)
end



function compute(self::CircleEq{T},x1::T,y1::T,x2::T,y2::T,x3::T,y3::T) where T <: AbstractFloat
    no_flip::Bool = abs(x3-x1) < abs(y3-y1)
    x1p = no_flip ? x1 - x2 : y1 - y2
    y1p = no_flip ? y1 - y2 : x1 - x2
    d12 = x1p * x1p + y1p * y1p
    x3p = no_flip ? x3 - x2 : y3 - y2
    y3p = no_flip ? y3 - y2 : x3 - x2
    d32 = x3p * x3p + y3p * y3p
    num = x1p * y3p - y1p * x3p  # num also gives correct sign for CT
    det = d12 * y3p - d32 * y1p
    st2 = (d12 * x3p - d32 * x1p)
    seq = det * det + st2 * st2
    al2 = T(1.) / √(seq)
    be2 = -st2 * al2
    ct = T(2.) * num * al2
    al2 *= det
    self.m_xp = x2
    self.m_yp = y2
    self.m_c = ct
    self.m_alpha = no_flip ? al2 : -be2
    self.m_beta = no_flip ? be2 : -al2
    return Nothing
end

c = CircleEq{Float32}()
@time compute(c,1.12f0,1.13f0,1.14f0,1.15f0,1.16f0,1.17f0)
@time compute(c,1.12f0,1.13f0,1.14f0,1.15f0,1.16f0,1.17f0)