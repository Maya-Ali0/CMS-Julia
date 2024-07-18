module RecoLocalTracker_SiPixelRecHits_plugins_PixelRecHits_h
using ..BeamSpotPOD_h
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA: SiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA: SiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h: ParamsOnGPU
using ..heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat
using ..pixelGPUDetails.pixelConstants
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
# missing more includes


# used for the include (so later will change to using .module name of the gpu pixel rec hits)
struct PixelRecHitGPUKernel

end
function setHitsLayerStart(hitsModuleStart::Vector{UInt32}, cpeParams::ParamsOnGPU, hitsLayerStart::Vector{UInt32})
    @assert 0 == hitsModuleStart[1]
    begin_t = 1 
    end_t = 11
    for i in begin_h:end_h 
        hitsLayerStart[i] = hitsModuleStart[layerGeometry(cpeParams).layerStart[i]]
    end
end 

function makeHits(self::PixelRecHitGPUKernel, 
                  digis_d::SiPixelDigisSoA,
                  clusters_d::SiPixelClustersSoA, 
                  bs_d::BeamSpotPOD, 
                  cpeParams::ParamsOnGPU)
    nHits = nClusters(clusters_d)
    TrackingRecHit2DCPU = TrackingRecHit2DHeterogeneous{CPUTraits} 
    hits_d = TrackingRecHit2DCPU(nHits, cpeParams, clus_module_star(clusters_d),null)


    if n_modules(digis_d)
        # gpuPixelRecHits::getHits(cpeParams, &bs_d, view(digis_d), nDigis(digis_d), view(digis_d), view(digis_d))
    end

    if nHits
        setHitsLayerStart(clus_module_star(clusters_d), cpeParams, hits_layer_start(hits_d))
    end

    if nHits
        # HistoContainer::fillManyFromVector(phi_binner(hits_d), 10, iphi(hits_d), hits_layer_start(hits_d), nHits)
    end

    return hits_d
end


end