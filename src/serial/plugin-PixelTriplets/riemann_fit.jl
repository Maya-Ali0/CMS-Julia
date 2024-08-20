module RecoPixelVertexing_PixelTrackFitting_interface_RiemannFit_h
using LinearAlgebra
using Test
using StaticArrays
using ..RecoPixelVertexing_PixelTrackFitting_interface_FitUtils_h


    #  Compute the Radiation length in the uniform hypothesis
    # *
    # * The Pixel detector, barrel and forward, is considered as an omogeneous
    # * cilinder of material, whose radiation lengths has been derived from the TDR
    # * plot that shows that 16cm correspond to 0.06 radiation lengths. Therefore
    # * one radiation length corresponds to 16cm/0.06 =~ 267 cm. All radiation
    # * lengths are computed using this unique number, in both regions, barrel and
    # * endcap.
    # *
    # * NB: no angle corrections nor projections are computed inside this routine.
    # * It is therefore the responsibility of the caller to supply the proper
    # * lengths in input. These lenghts are the path travelled by the particle along
    # * its trajectory, namely the so called S of the helix in 3D space.
    # *
    # * \param length_values vector of incremental distances that will be translated
    # * into radiation length equivalent. Each radiation length i is computed
    # * incrementally with respect to the previous length i-1. The first lenght has
    # * no reference point (i.e. it has the dca).
    # *
    # * \return incremental radiation lengths that correspond to each segment.
    @inline function compute_rad_len_uniform_material(length_values::Vector{Float64}, rad_lengths::Vector{Float64})
        xx_0_inv = 0.06 / 16
        n = size(length_values, 1)
        rad_lengths[1] = length_values[1] * xx_0_inv
        for j  in 2:n
            rad_lengths[j] = abs(length_values[j] - length_values[j - 1]) * xx_0_inv
        end
    end

   
    # \brief Compute the covariance matrix along cartesian S-Z of points due to
    # multiple Coulomb scattering to be used in the line_fit, for the barrel
    # and forward cases.
    # The input covariance matrix is in the variables s-z, original and
    # unrotated.
    # The multiple scattering component is computed in the usual linear
    # approximation, using the 3D path which is computed as the squared root of
    # the squared sum of the s and z components passed in.
    # Internally a rotation by theta is performed and the covariance matrix
    # returned is the one in the direction orthogonal to the rotated S3D axis,
    # i.e. along the rotated Z axis.
    # The choice of the rotation is not arbitrary, but derived from the fact that
    # putting the horizontal axis along the S3D direction allows the usage of the
    # ordinary least squared fitting techiques with the trivial parametrization y
    # = mx + q, avoiding the patological case with m = +/- inf, that would
    # correspond to the case at eta = 0.
    @inline function scatter_cov_line(cov_sz::Matrix{Float64}, 
                                      fast_fit::Vector{Float64},
                                      s_arcs::Matrix{Float64},
                                      z_values::Matrix{Float64},
                                      theta::Float64,
                                      B::Float64,
                                      ret::Matrix{Float64}) 
        N = size(cov_sz,2)
        p_t = min(20, fast_fit[2] * B)
        p_2 = p_t * p_t * ( 1 + 1/fast_fit[3] * fast_fit[3])
        rad_lengths_S = Vector{Float64}(undef, N)
        S_values =  Vector{Float64}(undef, N)
        S_values = s_arcs .* s_arcs + z_values .* z_values
        S_values = sqrt.(S_values)
        compute_rad_len_uniform_material(S_values, rad_lengths_S)
        sig2_S = Vector{Float64}(undef, N)
        sig2_S = .000225 / p_2 * abs2(1. + 0.038 * log.(rad_lengths_S)) .* rad_lengths_S
        tmp = zeros(Float64, 2 * N, 2 * N)
        for k in 1:n
            tmp[k , k] = cov_sz[k][1, 1]
            tmp[k + n, k + n] = cov_sz[k][2, 2]
            tmp[k , k + n] = tmp[k + n,k] = cov_sz[k][1,2]
        end
        for k in 1:N
            for l in k:N
                for i in 1:min(k,l)
                    tmp[k+n,l+n] =  tmp[k+n,l+n] + abs(S_values[k] - S_values[i]) * abs(S_values[l] - S_values[i]) * sig2_S
                end
                tmp[l+n, k+n] = tmp[k+n, l+n]
            end
        end

        ret = tmp[n:n:n:n]
    end

    
    # \brief Compute the covariance matrix (in radial coordinates) of points in
    # the transverse plane due to multiple Coulomb scattering.
    # \param p2D 2D points in the transverse plane.
    # \param fast_fit fast_fit Vector4d result of the previous pre-fit
    # structured in this form:(X0, Y0, R, Tan(Theta))).
    # \param B magnetic field use to compute p
    # \return scatter_cov_rad errors due to multiple scattering.
    # \warning input points must be ordered radially from the detector center
    # (from inner layer to outer ones; points on the same layer must ordered too).
    # \details Only the tangential component is computed (the radial one is
    # negligible).
    @inline function scatter_cov_rad(p2D::Matrix{Float64}, fast_fit::Vector{Float64}, rad::Vector{Float64}, B::Float64) 
        N = size(p2D, 2)
        p_t = min(20, fast_fit[2] * B)
        p_2 = p_t * p_t * (1 + 1 / fast_fit[3]^2)
        theta = atan(fast_fit[3])
        theta = theta < 0 ? theta + π : theta
        rad_lengths = Vector{Float64}(undef, N)
        S_values = Vector{Float64}(undef, N)
        o = [fast_fit[1], fast_fit[2]]
    
        for i in 1:N
            p = p2D[:, i] - o
            cross = cross2D(-o, p) 
            dot = dot(-o, p)
            atan2 = atan2(cross, dot)
            S_values[i] = abs(atan2 * fast_fit[2])
        end
    
        compute_rad_len_uniform_material(S_values .* sqrt(1 + 1 / fast_fit[3]^2), rad_lengths)
        scatter_cov_rad = zeros(Float64, N, N)
        sig2 = abs.(1. + 0.038 * log.(rad_lengths)) .* rad_lengths
        sig2 = sig2 .* 0.000225 / (p_2 * sin(theta)^2)
    
        for k in 1:N
            for l in 1:N
                for i in 1:min(k, l)
                    scatter_cov_rad[k, l] += (rad[k] - rad[i]) * (rad[l] - rad[i]) * sig2[i]
                end
                scatter_cov_rad[l, k] = scatter_cov_rad[k, l]
            end
        end
        
        return scatter_cov_rad
    end
    


    # \brief Transform covariance matrix from radial (only tangential component)
    # to Cartesian coordinates (only transverse plane component).
    # \param p2D 2D points in the transverse plane.
    # \param cov_rad covariance matrix in radial coordinate.
    # \return cov_cart covariance matrix in Cartesian coordinates.

    @inline function cov_radtocart(p2D::Matrix{Float64}, rad::Vector{Float64}, cov_rad::Matrix{Float64}) 
        printIt(p2D, "cov_radtocart - p2D:")
        N = size(p2D, 2)
        cov_cart = zeros(Float64, N, N)
        rad_inv = rad.cwiseInverse()
        printIt(rad_inv,"cov_radtocart - rad_inv:" )
        for i in 1:N
            for j in i:N
                cov_cart[i, j] = cov_rad[i, j] * p2D[1, i] * rad_inv[i] * p2D[1, j] * rad_inv[j]
                cov_cart[i + n, j + n] = cov_rad[i, j] * p2D[1, i] * rad_inv[i] * p2D[1, j] * rad_inv[j]
                cov_cart[i, j + n] = -cov_rad[i, j] * p2D[1, i] * rad_inv[i] * p2D[1, j] * rad_inv[j]
                cov_cart[i + n, j] = -cov_rad[i, j] * p2D[1, i] * rad_inv[i] * p2D[1, j] * rad_inv[j]
                cov_cart[j, i] = cov_cart[i, j]
                cov_cart[j + n, i + n] = cov_cart[i + n, j + n]
                cov_cart[j + n, i] = cov_cart[i, j + n]
                cov_cart[j, i + n] = cov_cart[i + n, j]
            end
        end

        return cov_cart
    end


    # \brief Transform covariance matrix from Cartesian coordinates (only
    # transverse plane component) to radial coordinates (both radial and
    # tangential component but only diagonal terms, correlation between different
    # point are not managed).
    # \param p2D 2D points in transverse plane.
    # \param cov_cart covariance matrix in Cartesian coordinates.
    # \return cov_rad covariance matrix in raidal coordinate.
    # \warning correlation between different point are not computed.

    @inline function cov_cart_to_rad(p2D::Matrix{Float64}, rad::Vector{Float64}, cov_cart::Matrix{Float64}) 
        N = size(p2D, 2)
        cov_rad = Vector{Float64}(undef, N)
        rad_inv2 = sqr(cwiseInverse(rad))
        for i in 1:N
            if rad[i] < exp(-4)
            cov_rad[i] = cov_cart[i,i]
            else
                cov_rad[i] = rad_inv2[i] * (cov_cart[i, i] * sqr(p2D[1, i]) + cov_cart[i + n, i + n] * sqr(p2D[2, i]) -
                2. * cov_cart[i, i + n] * p2D[2, i] * p2D[1, i])
            end
        end
        return cov_rad
    end
 
    # \brief Transform covariance matrix from Cartesian coordinates (only
    # transverse plane component) to coordinates system orthogonal to the
    # pre-fitted circle in each point.
    # Further information in attached documentation.
    # \param p2D 2D points in transverse plane.
    # \param cov_cart covariance matrix in Cartesian coordinates.
    # \param fast_fit fast_fit Vector4d result of the previous pre-fit
    # structured in this form:(X0, Y0, R, tan(theta))).
    # \return cov_rad covariance matrix in the pre-fitted circle's
    # orthogonal system.

    @inline function cov_carttorad_prefit(p2D::Matrix{Float64}, cov_cart::Matrix{Float64},fast_fit::Vector{Float64},rad::Vector{Float64})
        N = size(p2D, 2) 
        cov_rad = Vector{Float64}(undef, N, N)
        for i in 1:N
            if rad[i] < exp(-4)
                cov_rad[i] = cov_cart[i,i]
            else
                a = p2D[:, i]
                b = p2D[:, i] - fast_fit[2]
                x2 = a .* b
                y2 = cross2D(a,b)
                tan_c = -y2 / x2
                tan_c2 = sqr(tan_c)
                cov_rad[i] = 1/ (1 + tan_c2) * (cov_cart[i,i] + cov_cart[i+n,i+n] * tan_c2 + 2 * cov_cart[i,i+n] * tan_c)
            end
        end
        return cov_rad
    end

    # brief Compute the points' weights' vector for the circle fit when multiple
    # scattering is managed.
    # Further information in attached documentation.
    # \param cov_rad_inv covariance matrix inverse in radial coordinated
    # (or, beter, pre-fitted circle's orthogonal system).
    # \return weight VectorNd points' weights' vector.
    # \bug I'm not sure this is the right way to compute the weights for non
    # diagonal cov matrix. Further investigation needed.

    @inline function weight_circle(cov_rad_inv::Matrix{Float64})
        return return sum(cov_rad_inv, dims=1)'
    end

    # \brief Find particle q considering the  sign of cross product between
    # particles velocity (estimated by the first 2 hits) and the vector radius
    # between the first hit and the center of the fitted circle.
    # \param p2D 2D points in transverse plane.
    # \param par_uvr result of the circle fit in this form: (X0,Y0,R).
    # \return q int 1 or -1.
    @inline function Charge(p2D::Matrix{Float64}, par_uvr::Vector{Float64})
        return (p2D[1, 2] - p2D[1, 1]) * (par_uvr[2] - p2D[2, 1]) - (p2D[2, 2] - p2D[2, 1]) * (par_uvr[1] - p2D[1, 1]) > 0 ? -1 : 1
    end
    
    # \brief Compute the eigenvector associated to the minimum eigenvalue.
    # \param A the Matrix you want to know eigenvector and eigenvalue.
    # \param chi2 the double were the chi2-related quantity will be stored.
    # \return the eigenvector associated to the minimum eigenvalue.
    # \warning double precision is needed for a correct assessment of chi2.
    # \details The minimus eigenvalue is related to chi2.
    # We exploit the fact that the matrix is symmetrical and small (2x2 for line
    # fit and 3x3 for circle fit), so the SelfAdjointEigenSolver from Eigen
    # library is used, with the computedDirect  method (available only for 2x2
    # and 3x3 Matrix) wich computes eigendecomposition of given matrix using a
    # fast closed-form algorithm.
    # For this optimization the matrix type must be known at compiling time.
    @inline function min_eigen3D(A::Matrix{Float64})
        eigen_decomp = eigen(Symmetric(A)) 
        min_val, min_index = findmin(eigen_decomp.values) 
        chi2 = min_val  
        min_vector = eigen_decomp.vectors[:, min_index]  
        return min_vector, chi2
    end


    # \brief 2D version of min_eigen3D().
    # \param A the Matrix you want to know eigenvector and eigenvalue.
    # \param chi2 the double were the chi2-related quantity will be stored
    # \return the eigenvector associated to the minimum eigenvalue.
    # \detail The computedDirect() method of SelfAdjointEigenSolver for 2x2 Matrix
    # do not use special math function (just sqrt) therefore it doesn't speed up
    # significantly in single precision.
    @inline function min_eigen2D(A::Matrix{Float64}, chi2::Float64)
        eigen_decomp = eign(Symmetric(A))
        min_val, min_index = findmin(eigen_decomp.values)  
        chi2 = min_val  
        min_vector = eigen_decomp.vectors[:, min_index] 
        return min_vector, chi2
    end


    # \brief A very fast helix fit: it fits a circle by three points (first, middle
    # and last point) and a line by two points (first and last).
    # \param hits points to be fitted
    # \return result in this form: (X0,Y0,R,tan(theta)).
    # \warning points must be passed ordered (from internal layer to external) in
    # order to maximize accuracy and do not mistake tan(theta) sign.
    # \details This fast fit is used as pre-fit which is needed for:
    # - weights estimation and chi2 computation in line fit (fundamental);
    # - weights estimation and chi2 computation in circle fit (useful);
    # - computation of error due to multiple scattering.
    @inline function fast_fit(hits::Matrix{Float64}, result::Vector{Float64})
        N = size(matrix, 2)
        printIt(hits, "Fast_fit - hits: ")

        # circle fit
        b = hits[1:2, div(n, 2)] - hits[1:2, 1]  
        c = hits[1:2, n] - hits[1:2, 1]
        printIt(b, "Fast_fit - b: ")
        printIt(c, "Fast_fit - c: ")

        b2 = squareNorm(b)
        c2 = squaredNorm(c)

        flip = abs(b[1]) < abs(b[2])
        bx = flip ? b[2] : b[1]
        by = flip ? b[1] : b[2]
        cx = flip ? c[2] : c[1]
        cy = flip ? c[1] : c[2]
        
        div = 2 * (cx * by - bx * cy)

        Y0 = (cx * b2 - bx * c2) / div
        X0 = (0.5 * b2 -  Y0 * by)/ bx
        result[1] = hits[1,1] + (flip ? Y0 : X0)
        result[2] = hits[2,1] + (flip ? X0 : Y0)
        result[3] = sqrt(swqrt(X0) + sqr(Y0))
        printIt(result,"Fast_fit - result: ")

        # Line fit
        d = d = hits[1:2, 1] - result[1:2]  
        e = hits[1:2, n] - result[1:2]  
        printIt(d, "Fast_fit - d: ")
        printIt(e, "Fast_fit - e: ")

        dr = result[2] * atan2(cross2D(d, e), dot(d, e))
        dz = hits[2, n - 1] - hits[2, 1]
        result[4] = dr / dz
    end

    # \brief Fit a generic number of 2D points with a circle using Riemann-Chernov
    # algorithm. Covariance matrix of fitted parameter is optionally computed.
    # Multiple scattering (currently only in barrel layer) is optionally handled.
    # \param hits2D 2D points to be fitted.
    # \param hits_cov2D covariance matrix of 2D points.
    # \param fast_fit pre-fit result in this form: (X0,Y0,R,tan(theta)).
    # (tan(theta) is not used).
    # \param B magnetic field
    # \param error flag for error computation.
    # \param scattering flag for multiple scattering
    # \return circle circle_fit:
    # -par parameter of the fitted circle in this form (X0,Y0,R); \n
    # -cov covariance matrix of the fitted parameter (not initialized if
    # error = false); \n
    # -q charge of the particle; \n
    # -chi2.
    # \warning hits must be passed ordered from inner to outer layer (double hits
    # on the same layer must be ordered too) so that multiple scattering is
    # treated properly.
    # \warning Multiple scattering for barrel is still not tested.
    # \warning Multiple scattering for endcap hits is not handled (yet). Do not
    # fit endcap hits with scattering = true !
    # \bug for small pt (<0.3 Gev/c) chi2 could be slightly underestimated.
    # \bug further investigation needed for error propagation with multiple
    # scattering.
end


