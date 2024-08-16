module RecoPixelVertexing_PixelTrackFitting_interface_RiemannFit_h

using .RecoPixelVertexing_PixelTrackFitting_interface_FitUtils_h


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
    @Inline function compute_rad_len_uniform_material(length_values::VNd1, rad_lengths::VNd2) where {VNd1, VNd2}
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
                                      fast_fit::V4,
                                      s_arcs::VNd1,
                                      z_values::VNd2,
                                      theta::Float64,
                                      B::Float64,
                                      ret::Matrix{Float64}) where {V4,VNd1,VNd2,N}
        n = N
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
    @inline function scatter_cov_rad(p2D::M2xN, fast_fit::V4, rad::Vector{Float64}, B::Float64) where {M2xN,V4,N}
        n = N
        p_t = min(20, fast_fit[2] * B)
        p_2 = p_t * p_t * ( 1 + 1/fast_fit[3] * fast_fit[3])
        theta = atan(fast_fit[3])
        theta = theta < 0 ? theta + pi : theta
        rad_lengths = Vector{Float64}(undef, N)
        S_values =  Vector{Float64}(undef, N)
        o =  Vector{Float64}(undef, 2)
        push!(o, fast_fit[0])
        push!(o, fast_fit[1])

        for i in 1:N
            p = p2D[0:i:2:1] - o
            cross = cross2D(-o, p)
            dot = (-o).* p
            atan2 = atan2(cross, dot)
            S_values[i] = abs(atan2 * fast_fit[2])
        end

        compute_rad_len_uniform_material(S_values .* sqrt(1 + 1/ (fast_fit[3] * fast_fit[3])),rad_lengths)
        scatter_cov_rad = zeros(Float64, N, N)
        sig2 = Vector{Float64}(undef, N)
        sig2 = abs2(1. + 0.038 * log.(rad_lengths_S)) .* rad_lengths
        sig2 = sig2 .*  0.000225 / (p_2 * sqr(sin(theta)))

        for k in 1:N
            for k in k:N
                for i in 1:min(k,l)
                    scatter_cov_rad[k,l] = scatter_cov_rad[k,l] + (rad[k] - rad[i]) * (rad[l] - rad[i]) * sig2[i]
                end
                scatter_cov_rad[l,k] = scatter_cov_rad[k,l]
            end
        end
        return scatter_cov_rad
    end


    # \brief Transform covariance matrix from radial (only tangential component)
    # to Cartesian coordinates (only transverse plane component).
    # \param p2D 2D points in the transverse plane.
    # \param cov_rad covariance matrix in radial coordinate.
    # \return cov_cart covariance matrix in Cartesian coordinates.

    @inline function cov_radtocart(p2D::M2xN, rad::Vector{Float64}, cov_rad::Matrix{Float64}) where {M2xN,N}
        printIt(p2D, "cov_radtocart - p2D:")
        n = N
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

    @inline function cov_cart_to_rad(p2D::M2xN, rad::Vector{Float64}, cov_cart::Matrix{Float64}) where {M2xN, N}
        n = N
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

    @inline function cov_carttorad_prefit(p2D::M2xN, cov_cart::Matrix{Float64},fast_fit::V4,rad::VectorNd{Float64}) where {M2xN, V4,N}
        n = N
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



end