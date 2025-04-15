module gpuClusterCharge

    include("../CUDACore/cuda_assert.jl")
    # using .gpuConfig
    include("../CUDACore/prefix_scan.jl")
    using .prefix_scan:block_prefix_scan
    include("../CUDADataFormats/gpu_clustering_constants.jl")
    using .CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants.pixelGPUConstants:INV_ID, MAX_NUM_CLUSTERS_PER_MODULES, MAX_NUM_MODULES
    using Printf
    using CUDA
    function cluster_charge_cut(id, adc, module_start, n_clusters_in_module, module_id, cluster_id, num_elements)

        # check number of blocks match number of modules
        if blockIdx().x > module_start[1] 
            return
        end
        # Access first pixel of module
        first_pixel = module_start[1 + blockIdx().x]

        # Access the module id from the first pixel
        this_module_id = id[first_pixel]

        # module ids are zero indexed
        @cuassert this_module_id < MAX_NUM_MODULES
        @cuassert this_module_id == module_id[blockIdx().x]
        
        # acces number of clusters in the module
        n_clus = n_clusters_in_module[this_module_id+1]

        if n_clus == 0 
            return
        end

        if threadIdx().x == 1 && n_clus > MAX_NUM_CLUSTERS_PER_MODULES
            @cuprintf("warning too many clusters in module %d in block %d: %d > %d \n",this_module_id,blockIdx().x,n_clus,MAX_NUM_CLUSTERS_PER_MODULES)
        end
        # Assign a thread to each pixel in the module
        first = first_pixel + (threadIdx().x-1)

        if n_clus > MAX_NUM_CLUSTERS_PER_MODULES
            # loop over all pixels 
            for i ∈ first:blockDim().x:num_elements
                # ignore if module id of pixel is invalid
                if id[i] == INV_ID || id[i] == -INV_ID
                    continue
                end

                # ignore if module id of pixel is not this module
                if id[i] != this_module_id
                    break
                end

                # invalidate the pixel by setting its cluster and module id maps to INV_ID
                if cluster_id[i] > MAX_NUM_CLUSTERS_PER_MODULES
                    id[i] = INV_ID
                    cluster_id[i] = INV_ID
                end
            end
        end
        
        # allocate needed shared memory
        charge = @cuStaticSharedMem(Int32,MAX_NUM_CLUSTERS_PER_MODULES) # m
        ok = @cuStaticSharedMem(UInt8, MAX_NUM_CLUSTERS_PER_MODULES) # m
        new_clus_id = @cuStaticSharedMem(UInt16, MAX_NUM_CLUSTERS_PER_MODULES) # m 
        
        @cuassert n_clus <= MAX_NUM_CLUSTERS_PER_MODULES

        # set charge up to n_clusters to 0
        for i ∈ threadIdx().x:blockDim().x:n_clus
            charge[i] = 0 
        end

        sync_threads()
        
        # loop over all pixels in module
        for i ∈ first:blockDim().x:num_elements
            # ignore if module id of pixel is invalid
            if id[i] == INV_ID || id[i] == -INV_ID
                continue
            end

            # ignore if module id of pixel is not this module
            if id[i] != this_module_id
                break
            end

            # atomically add the charge value of each pixel to its cluster
            CUDA.atomic_add!(pointer(charge,cluster_id[i]),Int32(adc[i]))
        end

        sync_threads()

        charge_cut = this_module_id < 96 ? 2000 : 4000 # L1 : 2000 , other layers : 4000

        # loop over all clusters
        for i ∈ threadIdx().x:blockDim().x:n_clus
            # create a vector of ones where you set the cluster that meets the charge threshold to 1
            new_clus_id[i] = ok[i] = charge[i] > charge_cut ? 1 : 0
        end

        sync_threads()
 
        # create ws for block prefix scan
        ws = @cuStaticSharedMem(UInt16,32)

        # apply block prefix scan on new_clus_id to obtain the new cluster ids
        block_prefix_scan(new_clus_id,n_clus,ws)

        @cuassert(n_clus >= new_clus_id[n_clus])

        # if number of clusters did not change, return as no need to reassign cluster ids
        if n_clus == new_clus_id[n_clus]
            return
        end

        # update number of clusters in module
        n_clusters_in_module[this_module_id+1] = new_clus_id[n_clus]
        sync_threads()
        
        # loop over all clusters and invalidate clusters that did not meet the threshold
        for i ∈ threadIdx().x:blockDim().x:n_clus
            if ok[i] == 0
                new_clus_id[i] = INV_ID 
            end
        end
        
        sync_threads()

        # loop over all pixels, and update their cluster ids accordingly
        for i ∈ first:blockDim().x:num_elements
            # ignore if module id of pixel is invalid
            if id[i] == INV_ID
                continue
            end

            # ignore if module id of pixel is not this module
            if id[i] != this_module_id
                break
            end
            # update the cluster id of the pixel
            cluster_id[i] = new_clus_id[cluster_id[i]] 
            if cluster_id[i] == INV_ID || cluster_id[i] == -INV_ID 
                id[i] = INV_ID
            end
        end
        
    end
end