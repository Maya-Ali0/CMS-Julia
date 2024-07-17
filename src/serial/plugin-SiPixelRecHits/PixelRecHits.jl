module RecoLocalTracker_SiPixelRecHits_plugins_PixelRecHits_h

using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..heterogeneousCoreCUDAUtilitiesInterfaceCudaCompat
using ..pixelGPUDetails.pixelConstants
using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants
# missing more includes

struct PixelRecHitGPUKernel

end
function setHitsLayerStart(hitsModuleStart::UInt32, cpeParams::ParamsOnGPU, hitsLayerStart::UInt32)
    @assert 0 == hitsModuleStart
    begin_t = 0 
    end_t = 11
    for i in begin_h:end_h 
        hitsLayerStart[i] = hitsModuleStart[cpeParams->layerGeometry().layerStart[i]]
    end
end 

function makeHits(self::PixelRecHitGPUKernel, 
                  digis_d::SiPixelDigisSoA,
                  clusters_d::SiPixelClustersSoA, 
                  bs_d::BeamSpotPOD, 
                  cpeParams::ParamsOnGPU)
    nHits = nClusters(clusters_d)
    hits_d = TrackingRecHit2DCPU(nHits, cpeParams, clusModuleStart(clusters_d),null)


    if nModules(digis_d)
        getHits(cpeParams, &bs_d, view(digis_d), nDigis(digis_d), view(digis_d), view(digis_d))
    end

    if nHits
        setHitsLayerStart(clusModuleStart(clusters_d), cpeParams, hitsLayerStart(hits_d))
    end

    if nHits
        fillManyFromVector(phiBinner(hits_d), 10, iphi(hits_d), hitsLayerStart(hits_d), nHits)
    end

    return hits_d
end


end