module RecoPixelVertexing_PixelTrackFitting_interface_FitResult_h

using StaticArrays
export circle_fit, line_fit, helix_fit
struct circle_fit
    par::SVector{3,Float64} # parameter: (X0,Y0,R)
    cov::SMatrix{3,3,Float64}
    # < covariance matrix: \n
    #   |cov(X0,X0)|cov(Y0,X0)|cov( R,X0)| \n
    #   |cov(X0,Y0)|cov(Y0,Y0)|cov( R,Y0)| \n
    #   |cov(X0, R)|cov(Y0, R)|cov( R, R)|
    q::Int32 #particle charge
    chi2::Float64
end
struct line_fit
    par::SVector{2,Float64} #cotan(theta),Zip
    cov::SMatrix{2,2,Float64}
    # |cov(c_t,c_t)|cov(Zip,c_t)| \n
    #   |cov(c_t,Zip)|cov(Zip,Zip)|
    chi2::Float64
end

struct helix_fit
    par::SVector{5,Float64} #(phi,Tip,pt,cotan(theta)),Zip)
    cov::SMatrix{5,5,Float64}
    # < ()->cov() \n
    #   |(phi,phi)|(Tip,phi)|(p_t,phi)|(c_t,phi)|(Zip,phi)| \n
    #   |(phi,Tip)|(Tip,Tip)|(p_t,Tip)|(c_t,Tip)|(Zip,Tip)| \n
    #   |(phi,p_t)|(Tip,p_t)|(p_t,p_t)|(c_t,p_t)|(Zip,p_t)| \n
    #   |(phi,c_t)|(Tip,c_t)|(p_t,c_t)|(c_t,c_t)|(Zip,c_t)| \n
    #   |(phi,Zip)|(Tip,Zip)|(p_t,Zip)|(c_t,Zip)|(Zip,Zip)|
    # */
    chi2_circle::Float64
    chi2_line::Float64
    q::Int32
end


end