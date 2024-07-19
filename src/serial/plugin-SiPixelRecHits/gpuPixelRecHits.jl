module RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h

using ..BeamSpotPOD_h: BeamSpotPOD
# using approx_atan2.h
using ..gpuConfig
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA: SiPixelClustersSoA, DeviceConstView
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA: SiPixelDigisSoA, DeviceConstView
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView

function getHits(cpeParams::ParamsOnGPU, 
                 bs::BeamSpotPOD, 
                 pdigis::DeviceConstView, 
                 numElements::Integer,
                 pclusters::DeviceConstView,
                 phits::Vector{TrackingRecHit2DSOAView})

        assert(phits)
        assert(cpeParams)
        hits = phits
        digis = pdigis
        clusters = pclusters
        agc = hits.averageGeometry()
        ag = cpeParams.averageGeometry()
        for il in 1:TrackingRecHit2DSOAView::AverageGeometry::numberOfLaddersInBarrel
            agc.ladderZ[il] = ag.ladderZ[il] - bs.z
            agc.ladderX[il] = ag.ladderX[il] - bs.x
            agc.ladderY[il] = ag.ladderY[il] - bs.y
            agc.ladderR[il] = sqrt(agc.ladderX[il] * agc.ladderX[il] + agc.ladderY[il] * agc.ladderY[il])
            agc.ladderMinZ[il] = ag.ladderMinZ[il] - bs.z
            agc.ladderMaxZ[il] = ag.ladderMaxZ[il] - bs.z
        end
        agc.endCapZ[0] = ag.endCapZ[0] - bs.z
        agc.endCapZ[1] = ag.endCapZ[1] - bs.z


        InvId = 9999
        MaxHitsInIter = pixelCPEforGPU::MaxHitsInIter

        clusParams::pixelCPEforGPU::ClusParams

        firstModule = 1
        endModule = moduleStart(clusters, 1)
        for mod in firstModule:endModule
            me = moduleId(clusters, mod)
            nclus = clusInModule(clusters, me)
            
            if 0 == nclus
                continue
            end
            
            for startClus in 0:MaxHitsInIter:(nclus-1)
                first = moduleStart(clusters, mod + 1)

                nClusterInIter = min(maxHitsInIer, endClus - startClus)
                lastClus = startClus + nClusterInIter
                @assert nClusterInIter <= nclus
                @assert nClusterInIter > 0
                @assert lastClus <= nclus

                @assert nclus > MaxHitsInIter || (0 == startClus && nClusterInIter ==  nclus && lastClus == nclus)
                

                for ic in 0:nClusterInIter
                    clusParams.minRow[ic] = UInt32(typemax(UInt32))
                    clusParams.maxRow[ic] = UInt32(0)
                    clusParams.minCol[ic] = UInt32(typemax(UInt32))
                    clusParams.maxCol[ic] = UInt32(0)
                    clusParams.charge[ic] = UInt32(0)
                    clusParams.Q_f_X[ic] = UInt32(0)
                    clusParams.Q_l_X[ic] = UInt32(0)
                    clusParams.Q_f_Y[ic] = UInt32(0)
                    clusParams.Q_l_Y[ic] = UInt32(0)
                end
                

                for i in first:numElements
                    id = moduelInd(digis, i)
                    if id == InvId
                        continue
                    end
                    if id != me
                        break
                    end
                    cl = clus(digis, i)
                    if cl < startClus || cl >= lastClus
                        continue
                    end
                    cl = cl - startClus
                    @assert cl >= 0 
                    @assert cl < MaxHitsInIter

                    x = xx(digis, i)
                    y = yy(digis, i)
                    ch = min(adc(digis, i), pixmx)
                    clusParams.charge[cl] = clusParams.charge[cl] + ch
                    if clusParams.minRow[cl] == x
                        clusParams.Q_f_X[cl] = clusParams.Q_f_X[cl] + ch
                    end
                    if clusParams.maxRow[cl] == x
                        clusParams.Q_l_X[cl] = clusParams.Q_l_X[cl] + ch
                    end
                    if clusParams.minCol[cl] == y
                        clusParams.Q_f_Y[cl] = clusParams.Q_f_Y[cl] + ch
                    end
                    if clusParams.maxCol[cl] == y
                        clusParams.Q_l_Y[cl] = clusParams.Q_l_Y[cl] + ch
                    end
                end

                first = clusModuleStart(clusters, me) + startClus

                for ic in 0:nClusterInIter
                    h = first + ic

                    if h >= TrackingRecHit2DSOAView::macHits()
                        break
                    end
                    @assert h < nHits(hits)
                    @assert h < clusModuleStart(clusters, me + 1)

                    # FIXME
                    pixelCPEforGPU::position(cpeParams.commonParams(), cpeParams.detParams(me), clusParams, ic);
                    pixelCPEforGPU::errorFromDB(cpeParams.commonParams(), cpeParams.detParams(me), clusParams, ic);
                    
                    charge(hits, h) =clusParams.charge[ic]
                    detectorIndex(hits, h) = me

                    xLocal(hits, h) = xl = clusParams.xpos[ic]
                    yLocal(hits, h) = yl = clusParams.ypos[ic]
                             
                    clusterSizeX(hits, h) = clusParams.xsize[ic]
                    clusterSizeY(hits, h) = clusParams.ysize[ic]

                    xerrLocal(hits, h) = clusParams.xerr[ic] * clusParams.xerr[ic]
                    yerrLocal(hits, h) = clusParams.yerr[ic] * clusParams.yerr[ic]

                    
                    cpeParams.detParams(me).frame.toGlobal(xl, yl, xg, yg, zg)
                
                    xg = xg - bs.x
                    yg = yg - bs.y
                    zg = zg - bs.z

                    xGlobal(hits, h) = xg
                    yGlobal(hits, h) = yg
                    zGlobal(hits, h) = zg

                    
                    rGlobal(hits, h) = sqrt(xg * xg + yg * yg)
                    # FIXME
                    # iphi(hits, h) = unsafe_atan2s<7>(yg, xg)

                end
            end

        end
end 

    
end