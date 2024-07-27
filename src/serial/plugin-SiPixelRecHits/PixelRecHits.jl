module RecoLocalTracker_SiPixelRecHits_plugins_PixelRecHits_h
using ..BeamSpotPOD_h
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA: SiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h: ParamsOnGPU
using ..heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat
using ..pixelGPUDetails.pixelConstants
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h


export makeHits
# missing more includes



function setHitsLayerStart(hitsModuleStart::Vector{UInt32}, cpeParams::ParamsOnGPU, hitsLayerStart::Vector{UInt32})
    @assert 0 == hitsModuleStart[1]
    begin_t = 1 
    end_t = 11
    for i in begin_h:end_h 
        hitsLayerStart[i] = hitsModuleStart[layerGeometry(cpeParams).layerStart[i]]
    end
end 

function makeHits(digis_d::SiPixelDigisSoA,
                  clusters_d::SiPixelClustersSoA,
                  bs_d::BeamSpotPOD, 
                  cpeParams::ParamsOnGPU)
    nHits = nClusters(clusters_d)
    hits_d = TrackingRecHit2DHeterogeneous(nHits, cpeParams, clus_module_star(clusters_d))


    if (n_modules(digis_d) != 0)
        the_View = digiView(digis_d)
        getHits(cpeParams, bs_d, the_View, n_digis(digis_d), the_View, the_View)
    end

    if nHits
        setHitsLayerStart(clus_module_star(clusters_d), cpeParams, hits_layer_start(hits_d))
    end

    if nHits
        # HistoContainer::fillManyFromVector(phi_binner(hits_d), 10, iphi(hits_d), hits_layer_start(hits_d), nHits)
    end

    return hits_d
end
# open("rechits.txt", "w") do file
#     hits = hit_d.m_view
#     nHits = length(hits.m_xl) 

#     for i in 1:nHits
#         write(file, "m_yl: ", hits.m_yl[i], "\n")
#         write(file, "m_xerr: ", hits.m_xerr[i], "\n")
#         write(file, "m_yerr: ", hits.m_yerr[i], "\n")
#         write(file, "m_xg: ", hits.m_xg[i], "\n")
#         write(file, "m_yg: ", hits.m_yg[i], "\n")
#         write(file, "m_zg: ", hits.m_zg[i], "\n")
#         write(file, "m_rg: ", hits.m_rg[i], "\n")
#         write(file, "m_iphi: ", hits.m_iphi[i], "\n")
#         write(file, "m_charge: ", hits.m_charge[i], "\n")
#         write(file, "m_xsize: ", hits.m_xsize[i], "\n")
#         write(file, "m_ysize: ", hits.m_ysize[i], "\n")
#         write(file, "m_det_ind: ", hits.m_det_ind[i], "\n")
#         write(file, "m_average_geometry: ", string(hits.m_average_geometry), "\n")
#         write(file, "m_cpe_params: ", string(hits.m_cpe_params), "\n")
#         write(file, "m_hits_module_start: ", hits.m_hits_module_start[i], "\n")
#         write(file, "m_hits_layer_start: ", hits.m_hits_layer_start[i], "\n")
#         write(file, "m_hist: ", string(hits.m_hist), "\n")
#         write(file, "m_nHits: ", hits.m_nHits, "\n")
#         write(file, "\n")  
#     end
# end

end