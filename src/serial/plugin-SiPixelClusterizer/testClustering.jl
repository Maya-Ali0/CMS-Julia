module ClusteringTest

using Printf
using Test

using ..gpuClustering:find_clus, count_modules

const INV_ID = 65535
const MAX_NUM_MODULES = 10
const num_cols_in_module = 416

# Mockup data for testing
id = UInt16[1, 1, 1, 1, 1, 1, 1, 1]
x = UInt16[1, 2, 3, 1, 2, 3, 1, 2]
y = UInt16[1, 1, 1, 2, 2, 2, 3, 3]

num_elements = length(id)
println(num_elements)
module_start = fill(0, MAX_NUM_MODULES + 1)
cluster_id = fill(0, num_elements)
n_clusters_in_module = fill(UInt32(0), MAX_NUM_MODULES + 1)
moduleId = fill(1, MAX_NUM_MODULES + 1)

expected_clusters = 1

count_modules(id, module_start, cluster_id, num_elements)

find_clus(id, x, y, module_start, n_clusters_in_module, moduleId, cluster_id, num_elements)

actual_clusters = n_clusters_in_module[1]

println("Expected number of clusters: ", expected_clusters)
println("Actual number of clusters: ", actual_clusters)

@test actual_clusters == expected_clusters

end
