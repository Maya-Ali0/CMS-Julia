module RecoLocalTracker_SiPixelRecHits_plugins_PixelRecHits_h
using ..BeamSpotPOD_h
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat
using ..pixelGPUDetails.pixelConstants
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..PixelGPU_h
using ..Printf

export makeHits
# missing more includes



function setHitsLayerStart(hitsModuleStart::Vector{UInt32}, cpeParams::ParamsOnGPU, hitsLayerStart::Vector{UInt32})
    @assert 0 == hitsModuleStart[1]
    begin_t = 1 
    end_t = 11
    for i in begin_t:end_t
        hitsLayerStart[i] = hitsModuleStart[layerGeometry(cpeParams).layerStart[i] + 1]
    end
end

function makeHits(digis_d::SiPixelDigisSoA,
                  clusters_d::SiPixelClustersSoA,
                  bs_d::BeamSpotPOD, 
                  cpeParams::ParamsOnGPU)
    nHits = nClusters(clusters_d)

    hits_d = TrackingRecHit2DHeterogeneous(nHits, cpeParams, clus_module_start(clusters_d))

    if (n_modules(digis_d) != 0)
        getHits(cpeParams, bs_d, digiView(digis_d), n_digis(digis_d), clusterView(clusters_d), histView(hits_d))
    end

    if (nHits != 0)
        setHitsLayerStart(clus_module_start(clusters_d), cpeParams, hits_layer_start(hits_d))
    end

    if (nHits != 0)
        # HistoContainer::fillManyFromVector(phi_binner(hits_d), 10, iphi(hits_d), hits_layer_start(hits_d), nHits)
    end

    
    hits = histView(hits_d)
    nHits = length(hits.m_xl) 
    open("testttt.txt","a") do file
        for i in 1:nHits
            write(file,"m_xl: ", @sprintf("%.9f", hits.m_xl[i]), "\n")
            write(file,"m_yl: ", @sprintf("%.9f", hits.m_yl[i]), "\n")
            write(file, "m_xerr: ", @sprintf("%.9f", hits.m_xerr[i]), "\n")
            write(file, "m_yerr: ", @sprintf("%.9f", hits.m_yerr[i]), "\n")
            write(file, "m_xg: ", @sprintf("%.9f", hits.m_xg[i]), "\n")
            write(file, "m_yg: ", @sprintf("%.9f", hits.m_yg[i]), "\n")
            write(file, "m_zg: ", @sprintf("%.9f", hits.m_zg[i]), "\n")
            write(file, "m_rg: ", @sprintf("%.9f", hits.m_rg[i]), "\n")
            write(file, "m_iphi: ", string(hits.m_iphi[i]), "\n")
            write(file, "m_charge: ", string(hits.m_charge[i]), "\n")
            write(file, "m_xsize: ", string(hits.m_xsize[i]), "\n")
            write(file, "m_ysize: ", string(hits.m_ysize[i]), "\n")
            write(file, "m_detInd: ", string(hits.m_det_ind[i]), "\n")  # Assuming m_det_ind is an integer
            write(file, "\n")  
        end
    end
    
    
    return hits_d
end

end