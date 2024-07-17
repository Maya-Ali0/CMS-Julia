using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using .CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using .CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
# more includes are missing (waiting on files to be done)

struct SiPixelRecHitCUDA <: EDProducer
    tBeamSpot::EDGetTokenT{BeamSpotPOD}
    token::EDGetTokenT{SiPixelClustersSoA}
    tokenDigi::EDGetTokenT{SiPixelDigisSoA}
    tokenHit::EDPutTokenT{TrackingRecHit2DCPU}
    gpuAlgo::PixelRecHitGPUKernel

    function SiPixelRecHitCUDA(reg::ProductRegistry)
        tBeamSpot= consumes(reg, BeamSpotPOD)
        token = consumes(reg, SiPixelClustersSoA)
        tokenDigi = consumes(reg, SiPixelDigisSoA)
        tokenHit = produces(reg, TrackingRecHit2DCPU)
        new(tBeamSpot, token, tokenDigi, tokenHit, 0)
    end
end

function produce(self::SiPixelRecHitCUDA,iEvent::Event, es::EventSetup)
    fcpe::PixelCPEFast
    fcpe = get(es, self.PixelCPEFast)
    clusters = get(iEvent, self.token)
    digis = get(iEvent, self.tokenDigi)
    bs = get(iEvent, self.tBeamSpot)
    nHits = nClusters(clusters)
    if nHits >= TrackingRecHit2DSOAView::maxHits()
        println("Clusters/Hits Overflow ",nHits," >= ", TrackingRecHit2DSOAView::maxHits())
    end
    emplace(iEvent, tokenHit, makeHits(self.gpuAlgo, digis, clusters, bs, getCPUProduct(fcpe)))
end
