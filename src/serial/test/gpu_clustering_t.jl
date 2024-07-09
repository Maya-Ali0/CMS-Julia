using Revise
include("../plugin-SiPixelClusterizer/gpu_clustering.jl")
using .gpuClustering:find_clus, count_modules

include("../plugin-SiPixelClusterizer/gpu_cluster_charge_cut.jl")
using .gpuClusterCharge:cluster_charge_cut

include("../plugin-SiPixelClusterizer/gpu_clustering_constants.jl")
using .gpuClustering:INV_ID

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

y= [5, 7, 9, 1, 3, 0, 4, 8, 2, 6]


function generateClusters(kn)
    n = 1
    ncl = 0

    addBigNoise = 1 == kn % 2
    y = [5, 7, 9, 1, 3, 0, 4, 8, 2, 6]

    if addBigNoise # if odd
        MaxPixels = 1000
        id = 666
        
        for x in 0:3:139 # skipping 80 to 159 rows
            for yy in 0:3:399 # skipping 400 to 415 columns
                h_id[n] = id
                h_x[n] = x
                h_y[n] = yy
                h_adc[n] = 1000
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
    
    # isolated (10,10)
    id = 42
    x = 10
    ncl += 1
    h_id[n] = id
    h_x[n] = x
    h_y[n] = x
    h_adc[n] = kn == 0 ? 100 : 5000
    n += 1
    
    # first column (10, 0)
    ncl += 1
    h_id[n] = id
    h_x[n] = x
    h_y[n] = 0
    h_adc[n] = 5000
    n += 1
    
    # first columns (90,2) (90,1) adjacent added one cluster
    ncl += 1
    h_id[n] = id
    h_x[n] = x + 80
    h_y[n] = 2
    h_adc[n] = 5000
    n += 1
    # (90,1)
    h_id[n] = id
    h_x[n] = x + 80
    h_y[n] = 1
    h_adc[n] = 5000
    n += 1
    
    # last column (10, 415)
    ncl += 1
    h_id[n] = id
    h_x[n] = x
    h_y[n] = 415
    h_adc[n] = 5000
    n += 1
    
    # last columns (90, 415) , (90, 414) adjacent pixels one cluster
    ncl += 1
    h_id[n] = id
    h_x[n] = x + 80
    h_y[n] = 415
    h_adc[n] = 2500
    n += 1
    # (90, 414)
    h_id[n] = id
    h_x[n] = x + 80
    h_y[n] = 414
    h_adc[n] = 2500
    n += 1
    
    # diagonal
    ncl += 1
    for x in 20:24
        h_id[n] = id
        h_x[n] = x
        h_y[n] = x
        h_adc[n] = 1000
        n += 1
    end
    
    ncl += 1
    # reversed
    for x in 45:-1:41
        h_id[n] = id
        h_x[n] = x
        h_y[n] = x
        h_adc[n] = 1000
        n += 1
    end
    
    ncl += 1
    h_id[n+1] = INV_ID  # error
    n += 1
    
    # messy
    xx = [21, 25, 23, 24, 22] # (21,41) , (25,45) , (23,43) , (22 , 42) , (24 , 44)
    for k in 1:5
        h_id[n] = id
        h_x[n] = xx[k]
        h_y[n] = 20 + xx[k]
        h_adc[n] = 1000
        n += 1
    end
    
    # holes
    ncl += 1
    for k in 1:5
        h_id[n] = id
        h_x[n] = xx[k]
        h_y[n] = 100 # (21,100) (25, 100) (23, 100) (24, 100) (22, 100)
        h_adc[n] = kn == 2 ? 100 : 1000
        n += 1

        if xx[k] % 2 == 0 # (22,101) (24,101)
            h_id[n] = id
            h_x[n] = xx[k]
            h_y[n] = 101
            h_adc[n] = 1000
            n += 1
        end
    end
    
    # id == 0 (make sure it works!)
    id = 0
    x = 10
    ncl += 1
    h_id[n] = id
    h_x[n] = x
    h_y[n] = x
    h_adc[n] = 5000
    n += 1
    
    # above ids used 0, 666, 42
    
    # all odd id 
    for id in 11:2:1800 # module ids go from module 11 to 1800
        if (id ÷ 20) % 2 != 0
            h_id[n] = INV_ID
            n += 1 
        end
        for x in 0:4:39
            ncl += 1
            
            if (id ÷ 10) % 2 != 0 # if tens digit id was odd do this
                for k in 1:10
                    h_id[n] = id
                    h_x[n] = x
                    h_y[n] = x + y[k]
                    h_adc[n] = 100
                    n += 1
                    
                    h_id[n] = id
                    h_x[n] = x + 1
                    h_y[n] = x + y[k] + 2
                    h_adc[n] = 1000
                    n += 1
                end
            else
                for k in 10:-1:1
                    h_id[n] = id
                    h_x[n] = x
                    h_y[n] = x + y[k]
                    h_adc[n] = kn == 2 ? 10 : 1000
                    n += 1
                    
                    if y[k] == 3
                        continue  # hole
                    end
                    
                    if id == 51
                        h_id[n] = INV_ID
                        n += 1
                        h_id[n] = INV_ID
                        n += 1
                    end
                    
                    h_id[n] = id
                    h_x[n] = x + 1
                    h_y[n] = x + y[k] + 2
                    h_adc[n] = kn == 2 ? 10 : 1000
                    n += 1
                end
            end
        end
    end
    return n, ncl
end

for kkk in 0:4
    n = 1
    ncl = 0
    n,ncl = generateClusters(kkk)
    
    println("created ", n, " digis in ", ncl, " clusters")
    @assert n <= num_elements
    
    nModules = 0
    h_moduleStart[1] = nModules
    count_modules(h_id, h_moduleStart, h_clus, n)
    fill!(h_clusInModule, 0)
    
    find_clus(h_id, h_x, h_y, h_moduleStart, h_clusInModule, h_moduleId, h_clus, n)
    
    nModules = h_moduleStart[1]  
    nclus = h_clusInModule
    
    println("before charge cut found ", sum(nclus), " clusters")
    for i in max_num_modules:-1:2  # Changed to 2 to avoid accessing 0 index
        if nclus[i] > 0
            println("last module is ", i - 1, ' ', nclus[i])
            break
        end
    end
    println("ncl: ", ncl, " nclus from function: ", sum(nclus))
    
    @assert ncl == sum(nclus)
    
    cluster_charge_cut(h_id, h_adc, h_moduleStart, h_clusInModule, h_moduleId, h_clus, n)
    
    println("found ", nModules, " Modules active")
    
    clids = Set{UInt}()
    for i in 1:n
        @assert h_id[i] != 666  # only noise
        if h_id[i] == INV_ID
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
