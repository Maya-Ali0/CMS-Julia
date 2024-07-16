struct SOARotation{T}
    R11::T
    R12::T
    R13::T
    R21::T
    R22::T
    R23::T
    R31::T
    R32::T
    R33::T

    function SOARotation{T}() where {T}
        return new{T}(one(Int32), zero(Int32), zero(Int32), zero(Int32), one(Int32), zero(Int32), zero(Int32), zero(Int32), one(Int32))
    end

    function SOARotation{T}(v::T) where {T}
        return new{T}(one(T), zero(T), zero(T), zero(T), one(T), zero(T), zero(T), zero(T), one(T))
    end

    function SOARotation{T}(xx::T, xy::T, xz::T, yx::T, yy::T, yz::T, zx::T, zy::T, zz::T) where {T}
        return new{T}(xx, xy, xz, yx, yy, yz, zx, zy, zz)
    end

    function SOARotation{T}(p::Vector{T}) where {T}
        return new{T}(p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
    end

    # function SOARotation{T}(a::TkRotation{U}) where {T, U}
    #     return new{T}(a.xx(), a.xy(), a.xz(), a.yx(), a.yy(), a.yz(), a.zx(), a.zy(), a.zz())
    # end
end

function transposed(r::SOARotation{T}) where {T}
    return SOARotation{T}(r.R11, r.R21, r.R31, r.R12, r.R22, r.R32, r.R13, r.R23, r.R33)
end

function multiply(r::SOARotation{T}, vx::T, vy::T, vz::T) where {T}
    ux = r.R11 * vx + r.R12 * vy + r.R13 * vz
    uy = r.R21 * vx + r.R22 * vy + r.R23 * vz
    uz = r.R31 * vx + r.R32 * vy + r.R33 * vz
    return ux, uy, uz
end

function multiplyInverse(r::SOARotation{T}, vx::T, vy::T, vz::T) where {T}
    ux = r.R11 * vx + r.R21 * vy + r.R31 * vz
    uy = r.R12 * vx + r.R22 * vy + r.R32 * vz
    uz = r.R13 * vx + r.R23 * vy + r.R33 * vz
    return ux, uy, uz
end

function multiplyInverse(r::SOARotation{T}, vx::T, vy::T) where {T}
    ux = r.R11 * vx + r.R21 * vy
    uy = r.R12 * vx + r.R22 * vy
    uz = r.R13 * vx + r.R23 * vy
    return ux, uy, uz
end

xx(r::SOARotation) = r.R11
xy(r::SOARotation) = r.R12
xz(r::SOARotation) = r.R13
yx(r::SOARotation) = r.R21
yy(r::SOARotation) = r.R22
yz(r::SOARotation) = r.R23
zx(r::SOARotation) = r.R31
zy(r::SOARotation) = r.R32
zz(r::SOARotation) = r.R33
