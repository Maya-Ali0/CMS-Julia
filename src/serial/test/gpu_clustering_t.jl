include("../plugin-SiPixelClusterizer/gpu_clustering.jl")
using .RecoLocalTrackerSiPixelClusterizerPluginsGpuClustering.gpuClustering

include("../plugin-SiPixelClusterizer/gpu_cluster_charge_cut.jl")
using .gpuClustering

const max_num_modules = 2000  # Assuming MaxNumModules is predefined
num_elements = 256 * 2000

# these in reality are already on GPU
h_id = Vector{UInt16}(undef, num_elements)
h_x = Vector{UInt16}(undef, num_elements)
h_y = Vector{UInt16}(undef, num_elements)
h_adc = Vector{UInt16}(undef, num_elements)
h_clus = Vector{Int}(undef, num_elements)

h_moduleStart = Vector{UInt32}(undef, max_num_modules + 1)
h_clusInModule = Vector{UInt32}(undef, max_num_modules)
h_moduleId = Vector{UInt32}(undef, max_num_modules)

# later random number
n = 0
ncl = 0
y = [5, 7, 9, 1, 3, 0, 4, 8, 2, 6]

function generateClusters(kn)
    addBigNoise = 1 == kn % 2

    global n, ncl  # Declare n and ncl as global

    n = 0
    ncl = 0
    InvId = 0

    if addBigNoise
        MaxPixels = 1000
        id = 666
        
        for x in 0:3:139
            for yy in 0:3:399
                h_id[n+1] = id
                h_x[n+1] = x
                h_y[n+1] = yy
                h_adc[n+1] = 1000
                n += 1
                ncl += 1
                
                if MaxPixels <= ncl
                    break
                end
            end
            
            if MaxPixels <= ncl
                break
            end
        end
    end
    
    # isolated
    id = 42
    x = 10
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x
    h_y[n+1] = x
    h_adc[n+1] = kn == 0 ? 100 : 5000
    n += 1
    
    # first column
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x
    h_y[n+1] = 0
    h_adc[n+1] = 5000
    n += 1
    
    # first columns
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x + 80
    h_y[n+1] = 2
    h_adc[n+1] = 5000
    n += 1
    
    h_id[n+1] = id
    h_x[n+1] = x + 80
    h_y[n+1] = 1
    h_adc[n+1] = 5000
    n += 1
    
    # last column
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x
    h_y[n+1] = 415
    h_adc[n+1] = 5000
    n += 1
    
    # last columns
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x + 80
    h_y[n+1] = 415
    h_adc[n+1] = 2500
    n += 1
    
    h_id[n+1] = id
    h_x[n+1] = x + 80
    h_y[n+1] = 414
    h_adc[n+1] = 2500
    n += 1
    
    # diagonal
    ncl += 1
    for x in 20:24
        h_id[n+1] = id
        h_x[n+1] = x
        h_y[n+1] = x
        h_adc[n+1] = 1000
        n += 1
    end
    
    ncl += 1
    # reversed
    for x in 45:-1:41
        h_id[n+1] = id
        h_x[n+1] = x
        h_y[n+1] = x
        h_adc[n+1] = 1000
        n += 1
    end
    
    ncl += 1
    h_id[n+1] = InvId  # error
    n += 1
    
    # messy
    xx = [21, 25, 23, 24, 22]
    for k in 1:5
        h_id[n+1] = id
        h_x[n+1] = xx[k]
        h_y[n+1] = 20 + xx[k]
        h_adc[n+1] = 1000
        n += 1
    end
    
    # holes
    ncl += 1
    for k in 1:5
        h_id[n+1] = id
        h_x[n+1] = xx[k]
        h_y[n+1] = 100
        h_adc[n+1] = kn == 2 ? 100 : 1000
        n += 1
        
        if xx[k] % 2 == 0
            h_id[n+1] = id
            h_x[n+1] = xx[k]
            h_y[n+1] = 101
            h_adc[n+1] = 1000
            n += 1
        end
    end
    
    # id == 0 (make sure it works!)
    id = 0
    x = 10
    ncl += 1
    h_id[n+1] = id
    h_x[n+1] = x
    h_y[n+1] = x
    h_adc[n+1] = 5000
    n += 1
    
    # all odd id
    for id in 11:2:1800
        if (id ÷ 20) % 2 != 0
            n += 1  # error, equivalent to h_id[n+1] = InvId
        end
        
        for x in 0:4:39
            ncl += 1
            
            if (id ÷ 10) % 2 != 0
                for k in 1:10
                    h_id[n+1] = id
                    h_x[n+1] = x
                    h_y[n+1] = x + y[k]
                    h_adc[n+1] = 100
                    n += 1
                    
                    h_id[n+1] = id
                    h_x[n+1] = x + 1
                    h_y[n+1] = x + y[k] + 2
                    h_adc[n+1] = 1000
                    n += 1
                end
            else
                for k in 10:-1:1
                    h_id[n+1] = id
                    h_x[n+1] = x
                    h_y[n+1] = x + y[k]
                    h_adc[n+1] = kn == 2 ? 10 : 1000
                    n += 1
                    
                    if y[k] == 3
                        continue  # hole
                    end
                    
                    if id == 51
                        h_id[n+1] = InvId
                        n += 1
                        h_id[n+1] = InvId
                        n += 1
                    end
                    
                    h_id[n+1] = id
                    h_x[n+1] = x + 1
                    h_y[n+1] = x + y[k] + 2
                    h_adc[n+1] = kn == 2 ? 10 : 1000
                    n += 1
                end
            end
        end
    end
end

for kkk in 0:4
    n = 0
    ncl = 0
    generateClusters(kkk)
    
    println("created ", n, " digis in ", ncl, " clusters")
    @assert n <= num_elements
    
    nModules = 0
    h_moduleStart[1] = nModules
    Main.RecoLocalTrackerSiPixelClusterizerPluginsGpuClustering.gpuClustering.GPU_DEBUG.count_modules(h_id, h_moduleStart, h_clus, n)
    fill!(h_clusInModule, 0)
    
    Main.RecoLocalTrackerSiPixelClusterizerPluginsGpuClustering.gpuClustering.GPU_DEBUG.find_clus(h_id, h_x, h_y, h_moduleStart, h_clusInModule, h_moduleId, h_clus, n)
    
    nModules = h_moduleStart[1]  
    nclus = h_clusInModule
    
    println("before charge cut found ", sum(nclus), " clusters")
    for i in max_num_modules:-1:2  # Changed to 2 to avoid accessing 0 index
        if nclus[i] > 0
            println("last module is ", i - 1, ' ', nclus[i])
            break
        end
    end
    
    @assert ncl == sum(nclus)
    
    gpuClustering.GPU_DEBUG.clusterChargeCut(h_id, h_adc, h_moduleStart, h_clusInModule, h_moduleId, h_clus, n)
    
    println("found ", nModules, " Modules active")
    
    clids = Set{UInt}()
    for i in 1:n
        @assert h_id[i] != 666  # only noise
        if h_id[i] == InvId
            continue
        end
        @assert 0 <= h_clus[i] < nclus[h_id[i]]
        push!(clids, h_id[i] * 1000 + h_clus[i])
    end
    
    # verify no hole in numbering
    p = first(clids)
    cmid = p ÷ 1000
    @assert 0 == p % 1000
    for c in Iterators.drop(clids, 1)
        cc = c
        pp = p
        mid = cc ÷ 1000
        pnc = pp % 1000
        nc = cc % 1000
        if mid != cmid
            @assert 0 == cc % 1000
            @assert nclus[cmid + 1] - 1 == pp % 1000
            cmid = mid
            p = c
            continue
        end
        p = c
        @assert nc == pnc + 1
    end
    
    println("found ", sum(nclus), ' ', length(clids), " clusters")
    for i in max_num_modules:-1:2  # Changed to 2 to avoid accessing 0 index
        if nclus[i] > 0
            println("last module is ", i - 1, ' ', nclus[i])
            break
        end
    end
end
