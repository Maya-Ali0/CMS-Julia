module RecoLocalTracker_SiPixelRecHits_plugins_PixelRecHits_h
using ..BeamSpotPOD_h
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h:i_phi
using ..heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat
using ..pixelGPUDetails.pixelConstants
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h
using ..PixelGPU_h
using ..Printf
using ..histogram:fill_many_from_vector
using ..CUDA
export makeHits
# missing more includes



function setHitsLayerStart(hitsModuleStart::Vector{UInt32}, cpeParams::ParamsOnGPU, hitsLayerStart::Vector{UInt32})
    @assert 0 == hitsModuleStart[1]
    begin_t = 1 
    end_t = 11
    for i in begin_t:end_t
        hitsLayerStart[i] = hitsModuleStart[layerGeometry(cpeParams).layerStart[i] + 1] # the starting index for a hit in layer i 
        # print(hitsLayerStart[i]," ")
    end
end

# function f(a::TrackingRecHit2DHeterogeneous)
#     @cuprint(a.m_hitsModuleStart[1])
#     return nothing
# end

function makeHits(digis_d::SiPixelDigisSoA,
                  clusters_d::SiPixelClustersSoA,
                  bs_d::BeamSpotPOD, 
                  cpeParams::ParamsOnGPU)
    nHits = nClusters(clusters_d)


    hits_d = TrackingRecHit2DHeterogeneous(nHits, cpeParams, clus_module_start(clusters_d))
    # print(typeof(hits_d.m_store32))
    hits_d = cu(hits_d)


    # print(typeof(hits_d))
    threadsPerBlock::Int32 = 128;
    num_blocks::UInt32 = n_modules(digis_d)
    # print(num_blocks)

    if (num_blocks != 0)
        @cuda blocks=num_blocks threads=threadsPerBlock getHits(cpeParams, bs_d, digis_d, n_digis(digis_d), clusters_d, hits_d)
    end

    println(nHits)

    hits_h_16 = Array(hits_d.m_store16)
    hits_h_32 = Array(hits_d.m_store32)

    # if (nHits != 0)
    #     setHitsLayerStart(clus_module_start(clusters_d), cpeParams, hits_layer_start(hits_d))
    # end

    # if (nHits != 0)
    #    fill_many_from_vector(phi_binner(hits_d), 10, i_phi(hist_view(hits_d)), hits_layer_start(hits_d), nHits)
    # end

    # counter = 0
    # for x ∈ phi_binner(hits_d).bins
    #     if counter == 101
    #         break
    #     end
    #     println(counter, " ", x, " ", i_phi(histView(hits_d))[x])
    #     counter+=1
    # end
    open("rechits.txt", "w") do file
    
        for i in 1:4*nHits

            write(file, "val: ", string(hits_h_16[i]), "\n")  # Assuming m_det_ind is an integer
            # write(file, "\n") 
        end

        # for i in 1:(9*nHits + 11)

        # end
    end    
    return hits_d
end

end