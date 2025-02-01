module RecoPixelVertexing_PixelTrackFitting_interface_BrokenLine_h

using ..RecoPixelVertexing_PixelTrackFitting_interface_FitUtils_h: circle_fit, line_fit, cross2D
using LinearAlgebra
using Statistics
using Test
using StaticArrays
using ..DataFormat_Math_choleskyInversion_h

#  Karimäki's parameters: (phi, d, k=1/R)
# /*!< covariance matrix: \n
#   |cov(phi,phi)|cov( d ,phi)|cov(  k ,phi)| \n
#   |cov(phi, d )|cov( d , d )|cov( k , d )| \n
#   |cov(phi, k )|cov( d , k )|cov( k , k )|

# Brief data needed for the Broken Line fit procedure.
mutable struct PreparedBrokenLineData
    q::Int                           # Particle charge
    radii::Matrix{Float64}           # Matrix: xy data in the system where the pre-fitted center is the origin
    s::Vector{Float64}               # Vector: total distance traveled in the transverse plane from the pre-fitted closest approach
    S::Vector{Float64}               # Vector: total distance traveled (three-dimensional)
    Z::Vector{Float64}               # Vector: orthogonal coordinate to the pre-fitted line in the sz plane
    VarBeta::Vector{Float64}         # Vector: kink angles in the SZ plane

    function PreparedBrokenLineData(q::Int64, radii::Matrix{Float64}, s::Vector{Float64}, S::Vector{Float64}, Z::Vector{Float64}, VarBeta::Vector{Float64})
        new(q, radii, s, S, Z, VarBeta)
    end
end


export PreparedBrokenLineData


# \brief Computes the Coulomb multiple scattering variance of the planar angle.

#     \param length length of the track in the material.
#     \param B magnetic field in Gev/cm/c.
#     \param R radius of curvature (needed to evaluate p).
#     \param Layer denotes which of the four layers of the detector is the endpoint of the multiple scattered track. For example, if Layer=3, then the particle has just gone through the material between the second and the third layer.

#     \todo add another Layer variable to identify also the start point of the track, so if there are missing hits or multiple hits, the part of the detector that the particle has traversed can be exactly identified.

#     \warning the formula used here assumes beta=1, and so neglects the dependence of theta_0 on the mass of the particle at fixed momentum.

#     \return the variance of the planar angle ((theta_0)^2 /3).
@inline function mult_scatt(length::Float64, B::Float64, R::Float64, Layer::Integer, slope::Float64)
    pt2 = min(20, B * R)
    pt2 = pt2 * pt2
    XXI_0 = 0.06 / 16 # inverse of radiation length of the material in cm
    geometry_factor = 0.7
    fact = geometry_factor * sqr(13.6 / 1000)
    return fact / (pt2 * (1 + sqr(slope))) * (abs(length) * XXI_0) * sqr(1 + 0.038 * log(abs(length) * XXI_0))
end

# \brief Computes the 2D rotation matrix that transforms the line y=slope*x into the line y=0.

#     \param slope tangent of the angle of rotation.

#     \return 2D rotation matrix.
@inline function rotation_matrix(slope::Float64)
    Rot = zeros(Float64, 2, 2)
    Rot[1, 1] = 1.0 / sqrt(1.0 + sqr(slope))
    Rot[1, 2] = slope * Rot[1, 1]
    Rot[2, 1] = -Rot[1, 2]
    Rot[2, 2] = Rot[1, 1]
    return Rot
end

# \brief Changes the Karimäki parameters (and consequently their covariance matrix) under a translation of the coordinate system, such that the old origin has coordinates (x0,y0) in the new coordinate system. The formulas are taken from Karimäki V., 1990, Effective circle fitting for particle trajectories, Nucl. Instr. and Meth. A305 (1991) 187.

#     \param circle circle fit in the old coordinate system.
#     \param x0 x coordinate of the translation vector.
#     \param y0 y coordinate of the translation vector.
#     \param jacobian passed by reference in order to save stack.
@inline function translate_karimaki(circle::circle_fit, x0::Float64, y0::Float64, jacobian::Matrix{Float64})
    DP = x0 * cos(circle.par[1]) + y0 * sin(circle.par[1])
    DO = x0 * sin(circle.par[1]) - y0 * cos(circle.par[1]) + circle.par[2]
    uu = 1 + circle.par[3] * circle.par[2]
    C = -circle.par[3] * y0 + uu * cos(circle.par[1])
    BB = circle.par[3] * x0 + uu * sin(circle.par[1])
    A = 2.0 * DO + circle.par[3] * (DO^2 + DP^2)
    U = sqrt(1.0 + circle.par[3] * A)
    xi = 1.0 / (BB^2 + C^2)
    v = 1.0 + circle.par[3] * DO
    lambda = (0.5 * A) / (U * (1.0 + U)^2)
    mu = 1.0 / (U * (1.0 + U)) + circle.par[3] * lambda
    zeta = DO^2 + DP^2

    jacobian[1, 1] = xi * uu * v
    jacobian[1, 2] = -xi * circle.par[3]^2 * DP
    jacobian[1, 3] = xi * DP

    jacobian[2, 1] = 2.0 * mu * uu * DP
    jacobian[2, 2] = 2.0 * mu * v
    jacobian[2, 3] = mu * zeta - lambda * A

    jacobian[3, 1] = 0.0
    jacobian[3, 2] = 0.0
    jacobian[3, 3] = 1.0

    circle.par[1] = atan2(BB, C)
    circle.par[2] = A / (1.0 + U)

    circle.cov = jacobian * circle.cov * jacobian'
end

# \brief Computes the data needed for the Broken Line fit procedure that are mainly common for the circle and the line fit.

#     \param hits hits coordinates.
#     \param hits_cov hits covariance matrix.
#     \param fast_fit pre-fit result in the form (X0,Y0,R,tan(theta)).
#     \param B magnetic field in Gev/cm/c.
#     \param results PreparedBrokenLineData to be filled (see description of PreparedBrokenLineData).
#   */
@inline function prepare_broken_line_data(hits::Matrix{Float64}, fast_fit::Vector{Float64}, B::Float64, results::PreparedBrokenLineData)
    n = size(hits, 2)
    d = zeros(2)
    e = zeros(2)
    d = hits[1:2, 2] - hits[1:2, 1]
    e = hits[1:2, n] - hits[1:2, n-1]
    results.q = cross2D(d, e) > 0 ? -1 : 1

    slope = -results.q / fast_fit[4]
    println("results.q: ", results.q)
    println("fast_fit[4]: ", fast_fit[4])
    println("slope: ", slope)

    R = rotation_matrix(slope)
    println("R: ", R)
    # Calculate radii and s
    results.radii = hits[1:2, :] .- fast_fit[1:2] * ones(1, n)
    e = -fast_fit[3] * fast_fit[1:2] / norm(fast_fit[1:2])
    for i in 1:n
        d = results.radii[1:2, i]
        results.s[i] = results.q * fast_fit[3] * atan2(cross2D(d, e), dot(d, e))
    end
    z = vec(hits[3, :])

    # Calculate S and Z
    pointsSZ = zeros(Float64, 2, n)
    for i in 1:n
        pointsSZ[1, i] = results.s[i]
        pointsSZ[2, i] = z[i]
        pointsSZ[1:2, i] = R * pointsSZ[1:2, i]
    end

    results.S = vec(pointsSZ[1, :]')
    results.Z = vec(pointsSZ[2, :]')

    results.VarBeta[1] = results.VarBeta[n] = 0
    for i in 2:n-1
        results.VarBeta[i] = mult_scatt(results.S[i+1] - results.S[i], B, fast_fit[3], i + 2, slope) +
                             mult_scatt(results.S[i] - results.S[i-1], B, fast_fit[3], i + 1, slope)
    end
end

# \brief Computes the n-by-n band matrix obtained minimizing the Broken Line's cost function w.r.t u. This is the whole matrix in the case of the line fit and the main n-by-n block in the case of the circle fit.

#     \param w weights of the first part of the cost function, the one with the measurements and not the angles (\sum_{i=1}^n w*(y_i-u_i)^2).
#     \param S total distance traveled by the particle from the pre-fitted closest approach.
#     \param VarBeta kink angles' variance.

#     \return the n-by-n matrix of the linear system
@inline function matrixc_u(w::Matrix{Float64}, S::Vector{Float64}, VarBeta::Vector{Float64})
    n = size(w, 1)
    C_U = zeros(Float64, n, n)
    for i in 1:n
        C_U[i, i] = w[i]

        if i > 2
            C_U[i, i] += 1.0 / (VarBeta[i-1] * (S[i] - S[i-1])^2)
        end

        if i > 1 && i < n
            C_U[i, i] += (1.0 / VarBeta[i]) * ((S[i+1] - S[i-1]) / ((S[i+1] - S[i]) * (S[i] - S[i-1])))^2
        end

        if i < n - 1
            C_U[i, i] += 1.0 / (VarBeta[i+1] * (S[i+1] - S[i])^2)
        end

        if i > 1 && i < n
            C_U[i, i+1] = 1.0 / (VarBeta[i] * (S[i+1] - S[i])) * (-(S[i+1] - S[i-1]) / ((S[i+1] - S[i]) * (S[i] - S[i-1])))
        end

        if i < n - 1
            C_U[i, i+1] += 1.0 / (VarBeta[i+1] * (S[i+1] - S[i])) * (-(S[i+2] - S[i]) / ((S[i+2] - S[i+1]) * (S[i+1] - S[i])))
        end

        if i < n - 1
            C_U[i, i+2] = 1.0 / (VarBeta[i+1] * (S[i+2] - S[i+1]) * (S[i+1] - S[i]))
        end

        C_U[i, i] *= 0.5
    end
    return C_U + C_U'
end

function squaredNorm(v::AbstractVector{T}) where {T}
    return sum(v .^ 2)
end

function atan2(y::Float64, x::Float64)
    if x > 0
        return atan(y / x)
    elseif x < 0
        return atan(y / x) + π
    elseif y > 0 && x == 0
        return π / 2  # 90 degrees
    elseif y < 0 && x == 0
        return -π / 2 # -90 degrees
    else
        return NaN    # undefined for (0, 0)
    end
end


# \brief A very fast helix fit.  
#     \param hits the measured hits.
#     \return (X0,Y0,R,tan(theta)).
#     \warning sign of theta is (intentionally, for now) mistaken for negative charges.
@inline function BL_Fast_fit(hits::Matrix{Float64}, results::Vector{Float64})
    n = size(hits, 2)
    a = hits[1:2, Int(n ÷ 2)+1] - hits[1:2, 1]
    b = hits[1:2, n] - hits[1:2, Int(n ÷ 2)+1]
    c = hits[1:2, 1] - hits[1:2, n]

    tmp = 0.5 / cross2D(c, a)
    results[1] = hits[1, 1] - (a[2] * squaredNorm(c) + c[2] * squaredNorm(a)) * tmp
    results[2] = hits[2, 1] + (a[1] * squaredNorm(c) + c[1] * squaredNorm(a)) * tmp

    results[3] = sqrt(squaredNorm(a) * squaredNorm(b) * squaredNorm(c)) / (2.0 * abs(cross2D(b, a)))

    d = hits[1:2, 1] - results[1:2]
    e = hits[1:2, n] - results[1:2]

    # println("cross2D(d,e):", cross2D(d, e))
    # println(" dot(d,e):", dot(d, e))
    # println("atan2(cross2D(d,e), dot(d,e)): ", atan2(cross2D(d, e), dot(d, e)))
    # println("hits[3, n-1]: ", hits[3, n])
    # println(" hits[3, 1]: ", hits[3, 1])
    # println("(hits[3, n-1] - hits[3, 1]): ", (hits[3, n] - hits[3, 1]))
    results[4] = results[3] * atan2(cross2D(d, e), dot(d, e)) / (hits[3, n] - hits[3, 1])

end

# \brief Performs the Broken Line fit in the curved track case (that is, the fit parameters are the interceptions u and the curvature correction \Delta\kappa).

#     \param hits hits coordinates.
#     \param hits_cov hits covariance matrix.
#     \param fast_fit pre-fit result in the form (X0,Y0,R,tan(theta)).
#     \param B magnetic field in Gev/cm/c.
#     \param data PreparedBrokenLineData.
#     \param circle_results struct to be filled with the results in this form:
#     -par parameter of the line in this form: (phi, d, k); \n
#     -cov covariance matrix of the fitted parameter; \n
#     -chi2 value of the cost function in the minimum.

#     \details The function implements the steps 2 and 3 of the Broken Line fit with the curvature correction.\n
#     The step 2 is the least square fit, done by imposing the minimum constraint on the cost function and solving the consequent linear system. It determines the fitted parameters u and \Delta\kappa and their covariance matrix.
#     The step 3 is the correction of the fast pre-fitted parameters for the innermost part of the track. It is first done in a comfortable coordinate system (the one in which the first hit is the origin) and then the parameters and their covariance matrix are transformed to the original coordinate system.
@inline function BL_Circle_fit(hits::Matrix{Float64}, hits_ge::Matrix{Float32}, fast_fit::Vector{Float64}, B::Float64, data::PreparedBrokenLineData, circle_results::circle_fit)
    n = size(hits, 2)
    circle_results.q = data.q
    radii = data.radii
    s = data.s
    S = data.S
    Z = data.Z
    VarBeta = data.VarBeta
    slope = -circle_results.q / fast_fit[4]
    VarBeta = VarBeta * (1 + sqr(slope))

    for i in 1:n
        Z[i] = norm(radii[1:2, i]) - fast_fit[3]
    end

    V = zeros(Float64, 2, 2)
    w = zeros(Float64, n, 1)
    RR = zeros(Float64, 2, 2)

    for i in 1:n
        V[1, 1] = hits_ge[1, i]
        V[1, 2] = V[2, 1] = hits_ge[2, i]
        V[2, 2] = hits_ge[3, i]
        RR = rotation_matrix(-radii[1, i] / radii[2, i])
        w[i] = 1 / ((RR*V*RR')[2, 2])
    end

    r_u = zeros(Float64, n + 1)
    r_u[n] = 0
    for i in 1:n
        r_u[i] = w[i] * Z[i]
    end

    C_U = zeros(Float64, n + 1, n + 1)
    C_U[1:n, 1:n] = matrixc_u(w, s, VarBeta)
    C_U[n+1, n+1] = 0.0
    for i in 1:n
        C_U[i, n+1] = 0.0

        if i > 1 && i < n
            C_U[i, n+1] += -(s[i+1] - s[i-1]) * (s[i+1] - s[i-1]) / (2.0 * VarBeta[i] * (s[i+1] - s[i]) * (s[i] - s[i-1]))
        end

        if i > 2
            C_U[i, n+1] += (s[i] - s[i-2]) / (2.0 * VarBeta[i-1] * (s[i] - s[i-1]))
        end

        if i < n - 1
            C_U[i, n+1] += (s[i+2] - s[i]) / (2.0 * VarBeta[i+1] * (s[i+1] - s[i]))
        end

        C_U[n+1, i] = C_U[i, n+1]

        if i > 1 && i < n
            C_U[n+1, n+1] += (s[i+1] - s[i-1])^2 / (4.0 * VarBeta[i])
        end
    end
    I = zeros(Float64, n + 1, n + 1)
    Main.DataFormat_Math_choleskyInversion_h.invert(C_U, I)
    u = I * r_u
    # println("u: ", u)
    # println("I: ", I)
    # println("r_u: ", r_u)

    radii[1:2, 1] /= norm(radii[1:2, 1])
    radii[1:2, 2] /= norm(radii[1:2, 2])

    d = hits[1:2, 1] .+ (-Z[1] + u[1]) .* radii[1:2, 1]
    e = hits[1:2, 2] .+ (-Z[2] + u[2]) .* radii[1:2, 2]

    # println("d: ", d)
    # println("e: ", e)

    # println("e-d: ", (e - d))
    # println("atan2((e-d)[2], (e-d)[1]): ", atan2((e-d)[2], (e-d)[1]))
    circle_results.par[1] = atan2((e-d)[2], (e-d)[1])
    circle_results.par[2] = -circle_results.q * (fast_fit[3] - sqrt(sqr(fast_fit[3]) - 0.25 * norm(e - d)^2))
    circle_results.par[3] = circle_results.q * (1.0 / fast_fit[3] + u[n+1])

    # println("Initial circle_results.par:", circle_results.par)
    @assert circle_results.q * circle_results.par[2] <= 0

    eMinusd = e - d
    tmp1 = sqr(norm(eMinusd))
    # println("tmp1: ", tmp1)
    # println("radii: ", radii)
    # println("fast_fit: ", fast_fit)
    jacobian = zeros(Float64, 3, 3)


    jacobian[1, 1] = (radii[2, 1] * eMinusd[1] - eMinusd[2] * radii[1, 1]) / tmp1
    jacobian[1, 2] = (radii[2, 2] * eMinusd[1] - eMinusd[2] * radii[1, 2]) / tmp1
    jacobian[1, 3] = 0
    jacobian[2, 1] = floor(circle_results.q / 2) * (eMinusd[1] * radii[1, 1] + eMinusd[2] * radii[2, 1]) /
                     sqrt(sqr(2 * fast_fit[3]) - tmp1)
    jacobian[2, 2] = floor(circle_results.q / 2) * (eMinusd[1] * radii[1, 2] + eMinusd[2] * radii[2, 2]) /
                     sqrt(sqr(2 * fast_fit[3]) - tmp1)
    jacobian[2, 3] = 0
    jacobian[3, 1] = 0
    jacobian[3, 2] = 0
    jacobian[3, 3] = circle_results.q

    circle_results.cov = [
        I[1, 1] I[1, 2] I[1, n+1];
        I[2, 1] I[2, 2] I[2, n+1];
        I[n+1, 1] I[n+1, 2] I[n+1, n+1]
    ]
    # println("circle_cov 1: ", circle_results.cov)
    # println("jacobian: ", jacobian)

    circle_results.cov = jacobian * circle_results.cov * jacobian'
    # println("circle_cov 2: ", circle_results.cov)

    translate_karimaki(circle_results, 0.5 * (e-d)[1], 0.5 * (e-d)[2], jacobian)
    # println("circle_cov 3: ", circle_results.cov)

    circle_results.cov[1, 1] += (1 + sqr(slope)) * mult_scatt(S[2] - S[1], B, fast_fit[3], 2, slope)
    # println("mult_scatt(S[2] - S[1], B, fast_fit[3], 2, slope): ", mult_scatt(S[2] - S[1], B, fast_fit[3], 2, slope))

    translate_karimaki(circle_results, d[1], d[2], jacobian)

    # println("circle_cov 4: ", circle_results.cov)
    circle_results.chi2 = 0
    for i in 1:n
        circle_results.chi2 += w[i] * sqr(Z[i] - u[i])

        if i > 1 && i < n
            circle_results.chi2 += sqr(u[i-1] / (s[i] - s[i-1]) -
                                       u[i] * (s[i+1] - s[i-1]) / ((s[i+1] - s[i]) * (s[i] - s[i-1])) +
                                       u[i+1] / (s[i+1] - s[i]) + (s[i+1] - s[i-1]) * u[n+1] / 2) / VarBeta[i]
        end
    end
    return circle_results.cov
end
# /*!
# \brief Performs the Broken Line fit in the straight track case (that is, the fit parameters are only the interceptions u).

# \param hits hits coordinates.
# \param hits_cov hits covariance matrix.
# \param fast_fit pre-fit result in the form (X0,Y0,R,tan(theta)).
# \param B magnetic field in Gev/cm/c.
# \param data PreparedBrokenLineData.
# \param line_results struct to be filled with the results in this form:
# -par parameter of the line in this form: (cot(theta), Zip); \n
# -cov covariance matrix of the fitted parameter; \n
# -chi2 value of the cost function in the minimum.

# \details The function implements the steps 2 and 3 of the Broken Line fit without the curvature correction.\n
# The step 2 is the least square fit, done by imposing the minimum constraint on the cost function and solving the consequent linear system. It determines the fitted parameters u and their covariance matrix.
# The step 3 is the correction of the fast pre-fitted parameters for the innermost part of the track. It is first done in a comfortable coordinate system (the one in which the first hit is the origin) and then the parameters and their covariance matrix are transformed to the original coordinate system.
# */
@inline function BL_Line_fit(hits_ge::Matrix{Float32}, fast_fit::Vector{Float64}, B::Float64, data::PreparedBrokenLineData, line_results::line_fit)
    n = size(hits_ge, 2)
    radii = data.radii
    S = data.S
    Z = data.Z
    VarBeta = data.VarBeta

    slope = -data.q / fast_fit[4]

    R = rotation_matrix(slope)
    # println("R BL_Line_Fit: ", R)

    V = zeros(Float64, 3, 3)
    JacobXYZtosZ = zeros(Float64, 2, 3)
    w = zeros(Float64, n, 1)

    for i in 1:n
        V[1, 1] = hits_ge[1, i]
        V[1, 2] = V[2, 1] = hits_ge[2, i]
        V[1, 3] = V[3, 1] = hits_ge[4, i]
        V[2, 2] = hits_ge[3, i]
        V[3, 2] = V[2, 3] = hits_ge[4, i]
        V[3, 3] = hits_ge[6, i]
        tmp = 1 / norm(radii[1:2, i])
        JacobXYZtosZ[1, 1] = radii[2, i] * tmp
        JacobXYZtosZ[1, 2] = -radii[1, i] * tmp
        JacobXYZtosZ[2, 3] = 1.0
        w[i] = 1 / ((R*JacobXYZtosZ*V*JacobXYZtosZ'*R')[2, 2])
    end
    # println("JacobXYZtosZ: ", JacobXYZtosZ)
    # println("V:", V)
    # println("w:", w)

    r_u = zeros(n)
    for i in 1:n
        r_u[i] = w[i] * Z[i]
    end

    # println("matrixc_u(w, S, VarBeta): ", matrixc_u(w, S, VarBeta))

    I = zeros(Float64, n, n)
    Main.DataFormat_Math_choleskyInversion_h.invert(matrixc_u(w, S, VarBeta), I)
    # println("I: ", I)
    u = I * r_u
    # println("u: ", u)
    line_results.par = [(u[2] - u[1]) / (S[2] - S[1]), u[1]]
    # println("line_results.par: ", line_results.par)
    idiff = 1.0 / (S[2] - S[1])


    line_results.cov = [
        (I[1, 1]-2*I[1, 2]+I[2, 2])*idiff^2+mult_scatt(S[2] - S[1], B, fast_fit[3], 2, slope) (I[1, 2]-I[1, 1])*idiff;
        (I[1, 2]-I[1, 1])*idiff I[1, 1]
    ]


    jacobian = zeros(2, 2)
    jacobian[1, 1] = 1
    jacobian[1, 2] = 0
    jacobian[2, 1] = -S[1]
    jacobian[2, 2] = 1

    line_results.par[2] = line_results.par[2] - line_results.par[1] * S[1]

    line_results.cov = jacobian * line_results.cov * jacobian'

    tmp = R[1, 1] - line_results.par[1] * R[1, 2]
    jacobian[2, 2] = 1 / tmp
    jacobian[1, 1] = jacobian[2, 2] * jacobian[2, 2]
    jacobian[1, 2] = 0
    jacobian[2, 1] = line_results.par[2] * R[1, 2] * jacobian[1, 1]
    line_results.par[2] = line_results.par[2] * jacobian[2, 2]
    line_results.par[1] = (R[1, 2] + line_results.par[1] * R[1, 1]) * jacobian[2, 2]
    line_results.cov = jacobian * line_results.cov * jacobian'

    line_results.chi2 = 0
    for i in 1:n
        line_results.chi2 += w[i] * (Z[i] - u[i])^2
        if i > 1 && i < n
            line_results.chi2 += ((u[i-1] / (S[i] - S[i-1]) -
                                   u[i] * (S[i+1] - S[i-1]) / ((S[i+1] - S[i]) * (S[i] - S[i-1])) +
                                   u[i+1] / (S[i+1] - S[i]))^2 /
                                  VarBeta[i])^2
        end
    end

    return line_results
end

# \brief Helix fit by three step:
# -fast pre-fit (see Fast_fit() for further info); \n
# -circle fit of the hits projected in the transverse plane by Broken Line algorithm (see BL_Circle_fit() for further info); \n
# -line fit of the hits projected on the (pre-fitted) cilinder surface by Broken Line algorithm (see BL_Line_fit() for further info); \n
# Points must be passed ordered (from inner to outer layer).

# \param hits Matrix3xNd hits coordinates in this form: \n
# |x1|x2|x3|...|xn| \n
# |y1|y2|y3|...|yn| \n
# |z1|z2|z3|...|zn|
# \param hits_cov Matrix3Nd covariance matrix in this form (()->cov()): \n
# |(x1,x1)|(x2,x1)|(x3,x1)|(x4,x1)|.|(y1,x1)|(y2,x1)|(y3,x1)|(y4,x1)|.|(z1,x1)|(z2,x1)|(z3,x1)|(z4,x1)| \n
# |(x1,x2)|(x2,x2)|(x3,x2)|(x4,x2)|.|(y1,x2)|(y2,x2)|(y3,x2)|(y4,x2)|.|(z1,x2)|(z2,x2)|(z3,x2)|(z4,x2)| \n
# |(x1,x3)|(x2,x3)|(x3,x3)|(x4,x3)|.|(y1,x3)|(y2,x3)|(y3,x3)|(y4,x3)|.|(z1,x3)|(z2,x3)|(z3,x3)|(z4,x3)| \n
# |(x1,x4)|(x2,x4)|(x3,x4)|(x4,x4)|.|(y1,x4)|(y2,x4)|(y3,x4)|(y4,x4)|.|(z1,x4)|(z2,x4)|(z3,x4)|(z4,x4)| \n
# .       .       .       .       . .       .       .       .       . .       .       .       .       . \n
# |(x1,y1)|(x2,y1)|(x3,y1)|(x4,y1)|.|(y1,y1)|(y2,y1)|(y3,x1)|(y4,y1)|.|(z1,y1)|(z2,y1)|(z3,y1)|(z4,y1)| \n
# |(x1,y2)|(x2,y2)|(x3,y2)|(x4,y2)|.|(y1,y2)|(y2,y2)|(y3,x2)|(y4,y2)|.|(z1,y2)|(z2,y2)|(z3,y2)|(z4,y2)| \n
# |(x1,y3)|(x2,y3)|(x3,y3)|(x4,y3)|.|(y1,y3)|(y2,y3)|(y3,x3)|(y4,y3)|.|(z1,y3)|(z2,y3)|(z3,y3)|(z4,y3)| \n
# |(x1,y4)|(x2,y4)|(x3,y4)|(x4,y4)|.|(y1,y4)|(y2,y4)|(y3,x4)|(y4,y4)|.|(z1,y4)|(z2,y4)|(z3,y4)|(z4,y4)| \n
# .       .       .    .          . .       .       .       .       . .       .       .       .       . \n
# |(x1,z1)|(x2,z1)|(x3,z1)|(x4,z1)|.|(y1,z1)|(y2,z1)|(y3,z1)|(y4,z1)|.|(z1,z1)|(z2,z1)|(z3,z1)|(z4,z1)| \n
# |(x1,z2)|(x2,z2)|(x3,z2)|(x4,z2)|.|(y1,z2)|(y2,z2)|(y3,z2)|(y4,z2)|.|(z1,z2)|(z2,z2)|(z3,z2)|(z4,z2)| \n
# |(x1,z3)|(x2,z3)|(x3,z3)|(x4,z3)|.|(y1,z3)|(y2,z3)|(y3,z3)|(y4,z3)|.|(z1,z3)|(z2,z3)|(z3,z3)|(z4,z3)| \n
# |(x1,z4)|(x2,z4)|(x3,z4)|(x4,z4)|.|(y1,z4)|(y2,z4)|(y3,z4)|(y4,z4)|.|(z1,z4)|(z2,z4)|(z3,z4)|(z4,z4)|
# \param B magnetic field in the center of the detector in Gev/cm/c, in order to perform the p_t calculation.

# \warning see BL_Circle_fit(), BL_Line_fit() and Fast_fit() warnings.

# \bug see BL_Circle_fit(), BL_Line_fit() and Fast_fit() bugs.

# \return (phi,Tip,p_t,cot(theta)),Zip), their covariance matrix and the chi2's of the circle and line fits.
@inline function BL_Helix_fit(hits::Matrix{Float64}, hits_ge::Matrix{Float64}, B::Float64)

    helix = helix_fit(zeros(5), zeros(5, 5), 0.0, 0.0, 1)
    fast_fit = Vector{Float64}(undef, 4)
    BL_Fast_fit(hits, fast_fit)

    data = PreparedBrokenLineData(
        0,
        zeros(3, 3),
        zeros(3),
        zeros(3),
        zeros(3),
        zeros(3)
    )
    circle = circle_fit(
        zeros(3),
        zeros(3, 3),
        0,
        0.0
    )
    line = line_fit(
        zeros(2),
        zeros(2, 2),
        0.0
    )
    jacobian = zeros(3, 3)
    prepare_broken_line_data(hits, fast_fit, B, data)
    BL_Line_fit(hits_ge, fast_fit, B, data, line)
    BL_Circle_fit(hits, hits_ge, fast_fit, B, data, circle)

    jacobian .= [1.0 0 0;
        0 1.0 0;
        0 0 -abs(circle.par[3])*B/(circle.par[3]^2*circle.par[3])]

    circle.par[3] = B / abs(circle.par[3])
    circle.cov = jacobian * circle.cov * jacobian'

    helix.par = vcat(circle.par, line.par)
    helix.cov = zeros(5, 5)
    helix.cov[1:3, 1:3] .= circle.cov
    helix.cov[4:5, 4:5] .= line.cov
    helix.q = circle.q
    helix.chi2_circle = circle.chi2
    helix.chi2_line = line.chi2


    return helix
end


end