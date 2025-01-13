module CUDADataFormatsTrackTrajectoryStateSOA_H

using StaticArrays
const Vector5f = SVector{5,Float32}
const Vector15f = SVector{15,Float32}
const Vector5d = SVector{5,Float64}
const Matrix5d = SMatrix{5,5,Float64}

struct TrajectoryStateSoA
   state::Vector{Float32}
   covariance::Matrix{Float32}

   function TrajectoryStateSoA()
      new([], zeros(Float32, 0, 0))
   end

   function TrajectoryStateSoA(n::Int)
      new(zeros(Float32, n), zeros(Float32, n, n))
   end
end


function copyFromCircle!(trajectory::TrajectoryStateSoA,
   cp::Vector5d, ccov::Matrix5d,
   lp::Vector5d, lcov::Matrix5d,
   b::Float32, i::Int)

   trajectory.state[i] = Vector5f(cp[1], cp[2], cp[3] * b, lp[1], lp[2])

   trajectory.covariance[i] = Vector15f(
      ccov[1, 1],  # cov(0)
      ccov[1, 2],  # cov(1)
      b * ccov[1, 3],  # cov(2)
      0.0f0,  # cov(3)
      0.0f0,  # cov(4)
      ccov[2, 2],  # cov(5)
      b * ccov[2, 3],  # cov(6)
      0.0f0,  # cov(7)
      0.0f0,  # cov(8)
      b^2 * ccov[3, 3],  # cov(9)
      0.0f0,  # cov(10)
      0.0f0,  # cov(11)
      lcov[1, 1],  # cov(12)
      lcov[1, 2],  # cov(13)
      lcov[2, 2]   # cov(14)
   )
end
export copyFromCircle!
end
