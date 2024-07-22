module RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h

using ..BeamSpotPOD_h: BeamSpotPOD
using ..gpuConfig
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA: SiPixelClustersSoA, DeviceConstView
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA: SiPixelDigisSoA, DeviceConstView
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h: TrackingRecHit2DSOAView, ParamsOnGPU, CommonParams, DetParams, LayerGeometry, ClusParamsT

function getHits(cpeParams::ParamsOnGPU, 
                 bs::BeamSpotPOD, 
                 pdigis::DeviceConstView, 
                 numElements::Integer,
                 pclusters::DeviceConstView,
                 phits::Vector{TrackingRecHit2DSOAView})

        @assert(phits)
        @assert(cpeParams)
        hits = phits
        digis = pdigis
        clusters = pclusters
        agc = average_geometry(hits)
        ag = averageGeometry(cpeParams)
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

        clusParams:: pixelCPEforGPU::ClusParams

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
                    iphi(hits, h) = unsafe_atan2s<7>(yg, xg)

                end
            end

        end
end 

function test_getHits()
    # Mock data setup

    common_params = CommonParams(
    theThicknessB = 0.1f0,
    theThicknessE = 0.2f0,
    thePitchX = 0.01f0,
    thePitchY = 0.01f0
    )

    det_params = [DetParams() for _ in 1:10]  
    layer_geometry = LayerGeometry(
        layerStart = [UInt32(0) for _ in 1:10],  
        layer = [UInt8(1) for _ in 1:10]        
    )

   
    number_of_ladders_in_barrel = 10  # Example number, adjust as needed

    ladderZ = [1.0f0, 2.0f0, 3.0f0]  # Replace with realistic Z positions
    ladderX = [0.5f0, 1.5f0, 2.5f0]  # Replace with realistic X positions
    ladderY = [0.2f0, 0.4f0, 0.6f0]  # Replace with realistic Y positions
    ladderR = [1.2f0, 2.2f0, 3.2f0]  # Replace with realistic radius values
    ladderMinZ = [0.0f0, 1.0f0, 2.0f0]  # Replace with realistic min Z values
    ladderMaxZ = [1.5f0, 2.5f0, 3.5f0]  # Replace with realistic max Z values

   
    endCapZ = (0.1f0, -0.1f0)  # Example values for positive and negative end caps

    average_geometry = AverageGeometry(
        number_of_ladders_in_barrel = number_of_ladders_in_barrel,
        ladderZ = ladderZ,
        ladderX = ladderX,
        ladderY = ladderY,
        ladderR = ladderR,
        ladderMinZ = ladderMinZ,
        ladderMaxZ = ladderMaxZ,
        endCapZ = endCapZ
    )

    cpeParams = ParamsOnGPU(
        commonParams = common_params,
        detParams = det_params,
        layerGeometry = layer_geometry,
        averageGeometry = average_geometry
    )


    bs = BeamSpotPOD(
        x = 0.0f0,
        y = 0.0f0,
        z = 0.0f0,
        sigmaX = 0.1f0,
        sigmaY = 0.1f0
    )
     
    xx = [500, 600, 700, 800, 900]   # Example X coordinates as Int16
    yy = [15, 25, 35, 45, 55]       # Example Y coordinates as Int16
    adc = [100, 150, 200, 250, 300] # Example ADC values as Int16
    module_ind = [10, 20, 30, 40, 50] # Example module indices as Int16
    clus = [5, 10, 15, 20, 25]      

    pdigis = DeviceConstView(
        xx = xx,
        yy = yy,
        adc = adc,
        module_ind = module_ind,
        clus = clus
    ) 

    xx = [100, 200, 300, 400, 500]  # Example X coordinates as Int16
    yy = [10, 20, 30, 40, 50]      # Example Y coordinates as Int16
    adc = [15, 25, 35, 45, 55]     # Example ADC values as Int16
    module_ind = [1, 2, 3, 4, 5]   # Example module indices as Int16
    clus = [10, 20, 30, 40, 50]    # Example cluster values as Int32

    pclusters = DeviceConstView(
        xx = xx,
        yy = yy,
        adc = adc,
        module_ind = module_ind,
        clus = clus
    )


    m_xl = [1.0, 2.0, 3.0, 4.0]                 # X positions of hits
    m_yl = [5.0, 6.0, 7.0, 8.0]                 # Y positions of hits
    m_xerr = [0.1, 0.2, 0.1, 0.2]               # X errors of hits
    m_yerr = [0.1, 0.2, 0.2, 0.1]               # Y errors of hits
    m_xg = [0.5, 0.6, 0.7, 0.8]                 # X global coordinates
    m_yg = [0.5, 0.6, 0.7, 0.8]                 # Y global coordinates
    m_zg = [1.0, 2.0, 3.0, 4.0]                 # Z global coordinates
    m_rg = [1.1, 1.2, 1.3, 1.4]                 # R global coordinates

    m_iphi = [10, 20, 30, 40]                   # Phi indices
    m_charge = [1000, 2000, 1500, 2500]         # Charge values
    m_xsize = [10, 20, 15, 25]                  # X sizes
    m_ysize = [5, 10, 7, 12]                    # Y sizes
    m_det_ind = [1, 2, 3, 4]                    # Detector indices


    average_geometry = AverageGeometry(
        number_of_ladders_in_barrel = 5,
        ladderZ = [0.1, 0.2, 0.3, 0.4, 0.5],
        ladderX = [1.0, 2.0, 3.0, 4.0, 5.0],
        ladderY = [1.1, 2.1, 3.1, 4.1, 5.1],
        ladderR = [1.5, 2.5, 3.5, 4.5, 5.5],
        ladderMinZ = [0.0, 0.1, 0.2, 0.3, 0.4],
        ladderMaxZ = [0.1, 0.2, 0.3, 0.4, 0.5],
        endCapZ = (10.0f0, -10.0f0)
    )

    
    cpe_params = ParamsOnGPU() 

    hist_container = HisToContainer{Float64, 10, 100, 5, 3}()

    hits_module_start = [0, 10, 20, 30]  
    hits_layer_start = [0, 5, 10, 15]   

    nHits = 4

    tracking_rec_hit_view = TrackingRecHit2DSOAView(
        m_xl = m_xl,
        m_yl = m_yl,
        m_xerr = m_xerr,
        m_yerr = m_yerr,
        m_xg = m_xg,
        m_yg = m_yg,
        m_zg = m_zg,
        m_rg = m_rg,
        m_iphi = m_iphi,
        m_charge = m_charge,
        m_xsize = m_xsize,
        m_ysize = m_ysize,
        m_det_ind = m_det_ind,
        m_average_geometry = average_geometry,
        m_cpe_params = cpe_params,
        m_hits_module_start = hits_module_start,
        m_hits_layer_start = hits_layer_start,
        m_hist = hist_container,
        m_nHits = nHits
    )

    
    phits = Vector{TrackingRecHit2DSOAView}(undef, 10)
    push!(phits, tracking_rec_hit_view)

    numElements = 100 

    getHits(cpeParams, bs, pdigis, numElements, pclusters, phits)
end

# Call the test function
test_getHits()

    
end