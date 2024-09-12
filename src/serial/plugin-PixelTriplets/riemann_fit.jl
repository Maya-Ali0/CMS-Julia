module RecoPixelVertexing_PixelTrackFitting_interface_RiemannFit_h
using LinearAlgebra
using Statistics
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
        N = size(hits, 2)
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
    function circle_fit(hits2D::Matrix{Float64}, hits_cov2D::Matrix{Float64}, fast_fit::Vector{Float64}, rad::Vector{Float64}, B::Float64, error::Bool)
        V = hits_cov2D
        n = size(hits2D,2)
        printIt(hits2D, "circle_fit - hits2D:")
        printIt(hits_cov2D, "circle_fit - hits_cov2D:")
        
        # weight computation
        cov_rad = diagonal(cov_carttorad_prefit(hits2D, V, fast_fit, rad))
        scatter_cov_rad = scatter_cov_rad(hits2D, fast_fit, rad, B)
        printIt(scatter_cov_rad, "circle_fit - scatter_cov_rad:")
        printIt(hits2D, "circle_fit - hits2D bis:")

        V += cov_radtocart(hits2D, scatter_cov_rad, rad)
        printIt(V, "circle_fit - V:")
        cov_rad += scatter_cov_rad
        printIt(cov_rad, "circle_fit - cov_rad:")
        
        invert(cov_rad, G)
        renorm = sum(G)

        G =  G .* 1/renorm 
        weight = weight_circle(G)

        printIt(weight, "circle_fit - weight:")

        h_ = mean.(eachrow(hits2D))
        printIt(h, "circle_fit - h:")
        p3D = zeros(size(hits2D))
        p3D[1:2, 1:n] = hits2D .- hits_cov2D
        printIt(p3D, "circle_fit: p3D:a) ")
        
        mc = vcat(p3D[1, :]', p3D[2, :]')
        printIt(mc, "circle_fit: mc(centered hits): ")

        # scale
        squared_norm = dot(mc, mc)
        q = squared_norm
        s = sqrt(n/ q)
        p3D = p3D .* s

        # Project on Paraboloid
        block = p3D[1:2, 1:n]
        colwise_squared_norms = sum(abs2, block; dims=1)
        p3D[3, 1:n] .= colwise_squared_norms 
        printIt(p3D, "circle_fit - p3D: b)")

        # cost function
        # compute
        r0 = p3D .* weight
        X = p3D .- r0
        A = X .* G * X'
        printIt(A, "circle_fit - A:")

        printIt(v, "v BEFORE INVERSION")
        v = v .* (v[3] > 0 ) ? 1 : -1
        printIt(v, "v AFTER INVERSION")

        # This hack to be able to run on GPU where the automatic assignment to a
        # double from the vector multiplication is not working.

        # COMPUTE CIRCLE PARAMETER

        # auxiliary quantities
        h = sqrt(1 - sqrt(v[3]) - 4 .*c .* v[3])
        v2x2_inv = 1 / (2 .* v[3])
        s_inv = 1 / s

        par_uvr_ = Vector{Float64}(undef, 3)

        par_uvr_[1] = -v[1] * v2x2_inv       
        par_uvr_[2] = -v[2] * v2x2_inv      
        par_uvr_[3] = h * v2x2_inv         

        circle::circle_fit
        circle.par[1] = par_uvr_[1] * s_inv + h_[1]   
        circle.par[2] = par_uvr_[2] * s_inv + h_[2] 
        circle.par[3] = par_uvr_[3] * s_inv   

        circle.q = Charge(hits2D, circle.par)
        circle.chi2 = abs(chi2) * renorm * 1 / sqr(2 * v[3] * par_uvr_[3] * s)

        printIt(circle.par, "circle_fit - CIRCLE PARAMETERS:")
        printIt(circle.cov, "circle_fit - CIRCLE COVARIANCE:")

        # ERROR PROPAGATION
        if(error) 
            Vcs_ = [zeros(n, n) for _ in 1:2, _ in 1:2]  # Covariance matrix of center & scaled points
            C = [zeros(n, n) for _ in 1:3, _ in 1:3]     # Covariance matrix of 3D transformed points
            
            cm = zeros(1, 1)
            cm2 = zeros(1, 1)
            
            cm .= mc' * V * mc 
            c = cm[1, 1] 
            Vcs = zeros(n, n)
            Vcs .= sqr(s) * V .+ sqr(sqr(s)) * 1. / (4. * q * n) *
                (2. * norm(V)^2 + 4. * c) * (mc * mc')  
            
            printIt(Vcs, "circle_fit - Vcs:")

            C[1][1] .= Symmetric(Vcs[1:n, 1:n]) 
            Vcs_[1][2] .= Vcs[1:n, n+1:2n]       
            C[2][2] .= Symmetric(Vcs[n+1:2n, n+1:2n]) 
            Vcs_[2][1] .= Vcs_[1][2]'  
            
            printIt(Vcs, "circle_fit - Vcs:")

            t0 = ones(n) * p3D[1, :]  
            t1 = ones(n) * p3D[2, :]  
            t00 = p3D[1, :]' * p3D[1, :]
            t01 = p3D[1, :]' * p3D[2, :]
            t11 = p3D[2, :]' * p3D[2, :]
            t10 = t01'

            Vcs_[1][1] = C[1][1]
            C[1][2] = Vcs_[1][2]
            C[1][3] = 2.0 * (Vcs_[1][1] * t0 + Vcs_[1][2] * t1)
            Vcs_[2][2] = C[2][2]
            C[2][3] = 2.0 * (Vcs_[2][1] * t0 + Vcs_[2][2] * t1)

            tmp = zeros(N, N)
            tmp .= 2.0 * (Vcs_[1][1]^2 + Vcs_[1][1] * Vcs_[1][2] + Vcs_[2][2] * Vcs_[2][1] + Vcs_[2][2]^2) +
                4.0 * (Vcs_[1][1] * t00 + Vcs_[1][2] * t01 + Vcs_[2][1] * t10 + Vcs_[2][2] * t11)

            C[3][3] = Symmetric(tmp)
            printIt(C[1][1], "circle_fir - C[0][0]:")

            C0 = Matrix{Float64}(undef, 3, 3)  
            tmp = Float64(undef)     

            for i in 1:3
                for j in i:3
                    tmp = weight' .* C[i][j] .* weight
                    c = tmp
                    C0[i, j] = c 
                    C0[j, i] = C0[i][j]
                end
            end
            printIt(C0, "circle_fit - C0:")

            W = weight * weight'
            H = I - weight'
            s_v = H * p3D'
            printIt(W, "circle_fit - W:")
            printIt(H, "circle_fit - H:")
            printIt(s_v, "circle_fit - s_v:")

            D_ = Matrix{Float64}(undef, 3,3)

            D_[1][1] = (H * C[1][1] * H') .* W   
            D_[1][2] = (H * C[1][2] * H') .* W
            D_[1][3] = (H * C[1][3] * H') .* W
            D_[2][2] = (H * C[2][2] * H') .* W
            D_[2][3] = (H * C[2][3] * H') .* W
            D_[3][3] = (H * C[3][3] * H') .* W

            D_[2][1] = D_[1][2]'   
            D_[3][1] = D_[1][3]'
            D_[3][2] = D_[2][3]'

            printIt(D_[1][1] ,"circle_fit - D[1][1]:")

            const nu = [0 0; 0 1; 0 2; 1 1; 1 2; 2 2]
            E = Matrix{Float64}(undef, 6,6)

            for a in 1:6
                i = nu[a][1]
                j = nu[a][2]

                for b in a:6
                    k = nu[b][1]
                    l = nu[b][2]
                    t0 = Vector{Float64}(undef, n)
                    t1 = Vector{Float64}(undef, n)
                    if ( l == k)
                        t0 = 2 * D_[j][l] * s_v[:, l]
                        if(i == j)
                            t1 = t0
                        else
                            t1 = 2 * D_[i][l] * s_v[:, l]
                        end
                    else
                        t0 = D_[j][l] * s_v[:k] + D_[j][k] * s_v[:l]
                        if ( i ==j)
                            t1 = t0
                        else
                            t1 = D_[i][l] * s_v[:k] + D[i][k] * s_v[:l]
                        end
                    end

                    if(i == j)
                        cm = s_v[:i]' * (t0 + t1)
                        c = cm
                        E[a,b] = c
                    else
                        cm = (s_v[:i]' * t0) + (s_v[:j]' * t1)
                        c = cm
                        E[a,b] = c
                    end
                    if (b != a)
                        E[b,a] = E[a,b]
                    end
                end 
            end

            printIt(E, "circle_fit - E:")

            J2 = Matrix{Float64}(undef, 3, 6)
            for a in 1:6
                i = nu[a][1] 
                j = nu[a][2]
                Delta = zeros(Float64, 3, 3)
                Delta[i,j] = Delta[j,i] = abs(A[i,j] * d)
                J2[:a] = min_eigen3D[A + Delta]
                sign = J2[:a][2] > 0 ? 1 : -1
                J2[:a] = J2[:a] * sign - v / Delta[i,j]
            end
            printIt(J2, "circle_fit - J2")

            Cvc = Matrix{Float64}(undef, 4,4)

            t0 = J2 * E * J2'
            t1 = - t0 * r0
            Cvc[1:3, 1:3] .= reshape(t0, 3, 1)  
            Cvc[1:3, 4] .= t1  
            Cvc[4, 1:3] .= t1'  
            
            cm1 = v' * C0 * v
            cm3 = r0' * t0 * r0
    
            c = cm1[1, 1] + sum(C0 .* reshape(t0, 3, 1)) + cm3[1, 1]

            Cvc[4, 4] = c

            printIt(Cvc, "circle_fit - Cvc:")
           
            J3 = Matrix{Float64}(undef, 3,4)
            t = 1/h
            J3[1, 1] = -v2x2_inv
            J3[1, 3] = v[1] * sqr(v2x2_inv) * 2.0
            J3[2, 2] = -v2x2_inv
            J3[2, 3] = v[2] * sqr(v2x2_inv) * 2.0
            J3[3, 1] = v[1] * v2x2_inv * t
            J3[3, 2] = v[2] * v2x2_inv * t
            J3[3, 3] = -h * sqr(v2x2_inv) * 2.0 - (2.0 * c + v[3]) * v2x2_inv * t
            J3[3, 4] = -t
            
            printIt(J3, "circle_fit - J3:")

            Jq = mc' * s * 1/n
            printIt(Jq ,"circle_fit - Jq: ")

            cov_uvr = J3 * Cvc * J3' * sqr(s_inv) + (par_uvr_ * par_uvr_')* Jq * V * Jq'
            circle.cov = cov_uvr

         
        end

        printIt(circle.cov, "Circle cov:")
        return circle
    end

#     *!  \brief Perform an ordinary least square fit in the s-z plane to compute
#  * the parameters cotTheta and Zip.
#  *
#  * The fit is performed in the rotated S3D-Z' plane, following the formalism of
#  * Frodesen, Chapter 10, p. 259.
#  *
#  * The system has been rotated to both try to use the combined errors in s-z
#  * along Z', as errors in the Y direction and to avoid the patological case of
#  * degenerate lines with angular coefficient m = +/- inf.
#  *
#  * The rotation is using the information on the theta angle computed in the
#  * fast fit. The rotation is such that the S3D axis will be the X-direction,
#  * while the rotated Z-axis will be the Y-direction. This pretty much follows
#  * what is done in the same fit in the Broken Line approach.
 
    @inline function line_fit(hits::Matrix{Float64},
                              hits_ge::Matrix{Float64},
                              circle::circle_fit,
                              V4::fast_fit,
                              B::Float64,
                              error::Bool)

        n = size(hits,2)
        theta = - circle.q * atan(fast_fit[4])
        theta = theta < 0 ? theta + M_PI : theta

        rot = [sin(theta) cos(theta); -cos(theta) sin(theta)]

        # PROJECTION ON THE CILINDER
        
        # p2D will be:
        # [s1, s2, s3, ..., sn]
        # [z1, z2, z3, ..., zn]
        # s values will be ordinary x-values
        # z values will be ordinary y-values

        p2D = zeros(Float64, 2, n)
        Jx = Matrix{Float64}(undef, 2,6)

        #  x & associated Jacobian
        #  cfr https://indico.cern.ch/event/663159/contributions/2707659/attachments/1517175/2368189/Riemann_fit.pdf
        #  Slide 11
        #  a ==> -o i.e. the origin of the circle in XY plane, negative
        #  b ==> p i.e. distances of the points wrt the origin of the circle.
        
        o = [circle_par[1], circle_par[2]]
        
        # associated Jacobian, used in weights and errors computation
        Cov = zeros(Float64, 6, 6)
        cov_sz = [zeros(Float64, 2, 2) for _ in 1:n]

        for i in 1:n
            p = hits[1:2, i:i] - o
            cross = cross2D(-o, p)
            dot = dot(-o, p)
            atan2_ = -circle.q * atan2(cross, dot)
            p2D[1,i] = atan2_ * circle.par[3]

            temp0 = -circle.q * circle.par[3] * 1/( sqr(dot) + sqr(cross))
            d_X0 = 0
            d_Y0 = 0
            d_R = 0

            if (error)
                d_X0 = -temp0 * ((p[2] + o[2]) * dot - (p[1] - o[1]) * cross)
                d_Y0 = temp0 * ((p[1] + o[1]) * dot - (o[2] - p[2]) * cross)
                d_R = atan2_
            end
            d_x = temp0 * ( o[2] * dot + o[1] * cross)
            d_y = temp0 * (-o[1] * dot + o[2] * cross)
            
            Jx = [d_X0  d_Y0  d_R   d_x  d_y  0.0;
                0.0  0.0  0.0  0.0  0.0  0.0;
                0.0  1.0]
            Cov[1:3, 1:3] .= circle_cov

               
            Cov[4, 4] = hits_ge[i, 1]  # x errors
            Cov[5, 5] = hits_ge[i, 3]  # y errors
            Cov[6, 6] = hits_ge[i, 6]  # z errors
            Cov[4, 5] = Cov[5, 4] = hits_ge[i, 2]  # cov_xy
            Cov[4, 6] = Cov[6, 4] = hits_ge[i, 4]  # cov_xz
            Cov[5, 6] = Cov[6, 5] = hits_ge[i, 5]  # cov_yz
                
            
            tmp = Jx * Cov * Jx'
            cov_sz[i] .= rot * tmp * rot'
        end
        
        p2D[2, :] = hits[3, :] 

        # The following matrix will contain errors orthogonal to the rotated S
        # component only, with the Multiple Scattering properly treated!!
        cov_with_ms = Matrix{Float64}(undef, n, n)
        scatter_cov_line(cov_sz, fast_fit, p2D[1, :], p2D[2,:], theta, B, cov_with_ms)

        p2D_rot = rot * p2D

        ones_row = ones(Float64, 1, n)
        
        A = hcat(ones_row, p2D_rot[1, :])

        Vy_inv =  Matrix{Float64}(undef, n, n)
        invert(cov_with_ms, Vy_inv)

        Cov_params = A * Vy_inv * A'
        invert(Cov_params, Cov_params)

        sol = Cov_params * A * Vy_inv * p2D_rot[2, :]'

        # We need now to transfer back the results in the original s-z plane

        common_factor = 1 / (sin(theta) - sol(2,1) * cos(theta) )
        J = Matrix{Float64}(undef, 2,2)
        J = [0.0  common_factor * common_factor;
         common_factor  sol[1] * cos(theta) * common_factor * common_factor]

        m = common_factor * (sol(2,1) * sin(theta) + cos(theta))
        q = common_factor * sol(1,1)
        cov_mq = J * Cov_params * J'

        res = p2D_rot[2,:]' - A' * sol
        chi2 = res' * Vy_inv * res

        line::line_fit
        line_par[1] = m
        line_par[2] = q
        line.cov = cov_mq
        line.chi2 = chi2

        return line

    end
    #     \brief Helix fit by three step:
    #     -fast pre-fit (see Fast_fit() for further info); \n
    #     -circle fit of hits projected in the transverse plane by Riemann-Chernov
    #         algorithm (see Circle_fit() for further info); \n
    #     -line fit of hits projected on cylinder surface by orthogonal distance
    #         regression (see Line_fit for further info). \n
    #     Points must be passed ordered (from inner to outer layer).
    #     \param hits Matrix3xNd hits coordinates in this form: \n
    #         |x0|x1|x2|...|xn| \n
    #         |y0|y1|y2|...|yn| \n
    #         |z0|z1|z2|...|zn|
    #     \param hits_cov Matrix3Nd covariance matrix in this form (()->cov()): \n
    #    |(x0,x0)|(x1,x0)|(x2,x0)|.|(y0,x0)|(y1,x0)|(y2,x0)|.|(z0,x0)|(z1,x0)|(z2,x0)| \n
    #    |(x0,x1)|(x1,x1)|(x2,x1)|.|(y0,x1)|(y1,x1)|(y2,x1)|.|(z0,x1)|(z1,x1)|(z2,x1)| \n
    #    |(x0,x2)|(x1,x2)|(x2,x2)|.|(y0,x2)|(y1,x2)|(y2,x2)|.|(z0,x2)|(z1,x2)|(z2,x2)| \n
    #        .       .       .    .    .       .       .    .    .       .       .     \n
    #    |(x0,y0)|(x1,y0)|(x2,y0)|.|(y0,y0)|(y1,y0)|(y2,x0)|.|(z0,y0)|(z1,y0)|(z2,y0)| \n
    #    |(x0,y1)|(x1,y1)|(x2,y1)|.|(y0,y1)|(y1,y1)|(y2,x1)|.|(z0,y1)|(z1,y1)|(z2,y1)| \n
    #    |(x0,y2)|(x1,y2)|(x2,y2)|.|(y0,y2)|(y1,y2)|(y2,x2)|.|(z0,y2)|(z1,y2)|(z2,y2)| \n
    #        .       .       .    .    .       .       .    .    .       .       .     \n
    #    |(x0,z0)|(x1,z0)|(x2,z0)|.|(y0,z0)|(y1,z0)|(y2,z0)|.|(z0,z0)|(z1,z0)|(z2,z0)| \n
    #    |(x0,z1)|(x1,z1)|(x2,z1)|.|(y0,z1)|(y1,z1)|(y2,z1)|.|(z0,z1)|(z1,z1)|(z2,z1)| \n
    #    |(x0,z2)|(x1,z2)|(x2,z2)|.|(y0,z2)|(y1,z2)|(y2,z2)|.|(z0,z2)|(z1,z2)|(z2,z2)|
    #    \param B magnetic field in the center of the detector in Gev/cm/c
    #    unit, in order to perform pt calculation.
    #    \param error flag for error computation.
    #    \param scattering flag for multiple scattering treatment.
    #    (see Circle_fit() documentation for further info).
    #    \warning see Circle_fit(), Line_fit() and Fast_fit() warnings.
    #    \bug see Circle_fit(), Line_fit() and Fast_fit() bugs.
    @inline function helix_fit(hits::Matrix{Float64},
                            hits_ge::Matrix{Float64},
                            B::Float64,
                            error::Bool)

        n = size(hits,2)
        submatrix = hits[1:2, :]
        rad = vecnorm(submatrix, 2, 1)

        fast_fit = Vector{Float64}(undef, 4)
        fast_fit(hits, fast_fit)
        hits_cov =  zeros(Float64, 2 * n, 2 * n)
        loadCovariance2D(hits_ge, hits_cov)
        circle = circle_fit(hits[1:2, 1:n], hits_cov, fast_fit,rad, B, error)
        line = line_fit(hits, hits_ge, circle, fast_fit, B, error)
        
        par_urvtopak(circle, B, error)

        helix::helix_fit
        helix.par[1] = circle.par
        helix.par[2] = line.par

        if (error)
            helix.cov =  zeros(Float64, 5,5)
            helix_cov[1:3, 1:3] .= circle_cov
            helix_cov[4:5, 4:5] .= line_cov
        end
        helix.q = circle.q
        helix.chi2_circle = circle.chi2
        helix.chi2_line = line.chi2

        return helix
    end

end


