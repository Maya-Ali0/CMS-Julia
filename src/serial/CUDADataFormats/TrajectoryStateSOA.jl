using StaticArrays
const Vector5f = SVector{5, Float32}
const Vector15f = SVector{15, Float32}
const Vector5d = SVector{5, Float64}
const Matrix5d = SMatrix{5, 5, Float64}

struct TrajectoryStateSoA
   state::Vector5f
   covariance::Vector15f
end
