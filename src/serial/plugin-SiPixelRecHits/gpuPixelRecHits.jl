module RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h

using ..BeamSpotPOD_h: BeamSpotPOD
using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology
using ..gpuConfig
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
using ..PixelGPU_h
using ..SOA_h

export getHits
""" getHits function

 Processes pixel hit data from clusters and digis, adjusts for the beam spot position, 
    and calculates hit positions and errors. This function operates in iterations over the modules and clusters.

    **Inputs**:
    - `cpeParams::ParamsOnGPU`: Parameters for the cluster position estimation on GPU.
    - `bs::BeamSpotPOD`: Beam spot position and spread.
    - `pdigis::DeviceConstView`: Device view for accessing pixel digi data.
    - `numElements::Integer`: Number of elements in the digi data.
    - `pclusters::DeviceConstView`: Device view for accessing pixel cluster data.
    - `phits::Vector{TrackingRecHit2DSOAView}`: Vector of tracking hit views where results will be stored.

    **Outputs**:
    - `phits` is updated with the calculated hit positions, charges, sizes, and errors.

"""
function getHits(cpeParams::ParamsOnGPU, 
                 bs::BeamSpotPOD, 
                 pdigis::CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA.DeviceConstView,
                 numElements::Integer,
                 pclusters::CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA.DeviceConstView,
                 phits::TrackingRecHit2DSOAView)

        file = open("someData.txt", "w")

        hits = phits
        digis = pdigis
        clusters = pclusters

        write(file, "FOR 1 EVENT THIS IS WHAT's HAPPENING:\n##############################################\n")

        agc = average_geometry(hits)
        ag = averageGeometry(cpeParams)

        write(file, "FOR I FROM 1 to $(number_of_ladders_in_barrel)\n")

        for il in 1:number_of_ladders_in_barrel
            write(file, "agc.ladderZ[$il] = $(ag.ladderZ[il] - bs.z)\n")
            agc.ladderZ[il] = ag.ladderZ[il] - bs.z
            write(file, "agc.ladderX[$il] = $(ag.ladderX[il] - bs.z)\n")
            agc.ladderX[il] = ag.ladderX[il] - bs.x
            write(file, "agc.ladderY[$il] = $(ag.ladderY[il] - bs.z)\n")
            agc.ladderY[il] = ag.ladderY[il] - bs.y
            write(file, "agc.ladderR[$il] = $(sqrt(agc.ladderX[il] * agc.ladderX[il] + agc.ladderY[il] * agc.ladderY[il]))\n")
            agc.ladderR[il] = sqrt(agc.ladderX[il] * agc.ladderX[il] + agc.ladderY[il] * agc.ladderY[il])
            write(file, "agc.ladderMinZ[$il] = $(ag.ladderMinZ[il] - bs.z)\n")
            agc.ladderMinZ[il] = ag.ladderMinZ[il] - bs.z
            write(file, "agc.ladderMaxZ[$il] = $(ag.ladderMaxZ[il] - bs.z)\n")
            agc.ladderMaxZ[il] = ag.ladderMaxZ[il] - bs.z
        end
        write(file, "agc.endCapZ[0] = $(ag.endCapZ[1] - bs.z)\n")
        agc.endCapZ[1] = ag.endCapZ[1] - bs.z
        write(file, "agc.endCapZ[1] = $(ag.endCapZ[2] - bs.z)\n")
        agc.endCapZ[2] = ag.endCapZ[2] - bs.z

        write(file, "##############################################\n")



        InvId = 9999
        MaxHitsInIter = PixelGPU_h.MaxHitsInIter

        clusParams = ClusParamsT{10000}()

        firstModule = 1
        write(file, "firstModule: $firstModule\n")

        endModule = module_start(clusters, 1)
        write(file, "endModule: $endModule\n")
        write(file, "##############################################\n")
        write(file, "FOR module 1 to $(endModule )\n")

        for mod in firstModule:endModule
            write(file, "me = $(module_id(clusters, mod))\n")
            me = module_id(clusters, mod)
            nclus = clus_in_module(clusters, UInt32(me + 1))
            write(file, "nclus = $(nclus)\n")
            
            if 0 == nclus
                continue
            end
            
        endClus = nclus

        write(file, "FOR startClus 1 to $(nclus) incrementing by $MaxHitsInIter\n")

            for startClus in 1:MaxHitsInIter:(endClus)
                first = module_start(clusters, mod + 1)
                write(file, "first: $first\n")


                nClusInIter = min(MaxHitsInIter, nclus - startClus + 1)
                write(file, "nClusInIter: $nClusInIter\n")
                lastClus = startClus - 1 + nClusInIter
                write(file, "lastClus: $lastClus\n")
                @assert nClusInIter <= nclus
                @assert nClusInIter > 0
                @assert lastClus <= nclus
                @assert nclus > MaxHitsInIter || (1 == startClus && nClusInIter == nclus && lastClus == nclus)
                
                write(file, "##############################################\n")
                write(file, "FOR ic 1 to $(nClusInIter )\n")

                for ic in 1:nClusInIter
                    clusParams.minRow[ic] = UInt32(typemax(UInt32))
                    write(file, "clusParams.minRow[$ic] = $(clusParams.minRow[ic])\n")
                    
                    clusParams.maxRow[ic] = zero(UInt32)
                    write(file, "clusParams.maxRow[$ic] = $(clusParams.maxRow[ic])\n")
                    
                    clusParams.minCol[ic] = UInt32(typemax(UInt32))
                    write(file, "clusParams.minCol[$ic] = $(clusParams.minCol[ic])\n")
                    
                    clusParams.maxCol[ic] = zero(UInt32)
                    write(file, "clusParams.maxCol[$ic] = $(clusParams.maxCol[ic])\n")
                    
                    clusParams.charge[ic] = zero(UInt32)
                    write(file, "clusParams.charge[$ic] = $(clusParams.charge[ic])\n")
                    
                    clusParams.Q_f_X[ic] = zero(UInt32)
                    write(file, "clusParams.Q_f_X[$ic] = $(clusParams.Q_f_X[ic])\n")
                    
                    clusParams.Q_l_X[ic] = zero(UInt32)
                    write(file, "clusParams.Q_l_X[$ic] = $(clusParams.Q_l_X[ic])\n")
                    
                    clusParams.Q_f_Y[ic] = zero(UInt32)
                    write(file, "clusParams.Q_f_Y[$ic] = $(clusParams.Q_f_Y[ic])\n")
                    
                    clusParams.Q_l_Y[ic] = zero(UInt32)
                    write(file, "clusParams.Q_l_Y[$ic] = $(clusParams.Q_l_Y[ic])\n")
                end
                
                write(file,"FOR i in $first to $numElements \n")

                for i in first:numElements
                    id = module_ind(digis, i)
                    write(file, "id = $id\n")
                    if id == InvId
                        continue
                    end
                    if id != me
                        break
                    end
                    cl = clus(digis, i)
                    write(file, "cl = $cl\n")
                    
                    if cl < startClus || cl > lastClus
                        continue
                    end
                    
                    x = xx(digis, i)
                    write(file, "x = $x\n")
                    
                    y = yy(digis, i)
                    write(file, "y = $y\n")
                    
                    cl = cl - startClus + 1
                    @assert cl >= 1 
                    @assert cl <= MaxHitsInIter  # will verify later
                    
                    if clusParams.minRow[cl] > x
                        clusParams.minRow[cl] = x
                    end
                    write(file, "clusParams.minRow[$cl] = $(clusParams.minRow[cl])\n")
                    
                    if clusParams.maxRow[cl] < x
                        clusParams.maxRow[cl] = x
                    end
                    write(file, "clusParams.maxRow[$cl] = $(clusParams.maxRow[cl])\n")
                    
                    if clusParams.minCol[cl] > y
                        clusParams.minCol[cl] = y
                    end
                    write(file, "clusParams.minCol[$cl] = $(clusParams.minCol[cl])\n")
                    
                    if clusParams.maxCol[cl] < y
                        clusParams.maxCol[cl] = y
                    end
                    write(file, "clusParams.maxCol[$cl] = $(clusParams.maxCol[cl])\n")
                end

                pixmx = typemax(UInt16)
                print()
                write(file,"##################################\n")
                write(file,"pixmx: $pixmx\n")
                write(file,"FOR i IN $first to $numElements\n")
                for i in first:numElements
                    id = module_ind(digis, i)
                    write(file, "id = $id\n")
                    
                    if id == InvId
                        continue
                    end
                    
                    if id != me
                        break
                    end
                    
                    cl = clus(digis, i)
                    write(file, "cl = $cl\n")
                    
                    if cl < startClus || cl > lastClus
                        continue
                    end
                    
                    cl = cl - startClus + 1
                    @assert cl >= 1 
                    @assert cl <= MaxHitsInIter
                    
                    x = xx(digis, i)
                    write(file, "x = $x\n")
                    
                    y = yy(digis, i)
                    write(file, "y = $y\n")
                    
                    ch = min(adc(digis, i), pixmx)
                    write(file, "ch = $ch\n")

                    if(ch == 6267)
                        print("hi")
                        write(file,"peeepo\n")
                    end
                    
                    clusParams.charge[cl] = clusParams.charge[cl] + ch
                    write(file, "clusParams.charge[$cl] = $(clusParams.charge[cl])\n")
                    
                    if clusParams.minRow[cl] == x
                        clusParams.Q_f_X[cl] = clusParams.Q_f_X[cl] + ch
                    end
                    write(file, "clusParams.Q_f_X[$cl] = $(clusParams.Q_f_X[cl])\n")
                    
                    if clusParams.maxRow[cl] == x
                        clusParams.Q_l_X[cl] = clusParams.Q_l_X[cl] + ch
                    end
                    write(file, "clusParams.Q_l_X[$cl] = $(clusParams.Q_l_X[cl])\n")
                    
                    if clusParams.minCol[cl] == y
                        clusParams.Q_f_Y[cl] = clusParams.Q_f_Y[cl] + ch
                    end
                    write(file, "clusParams.Q_f_Y[$cl] = $(clusParams.Q_f_Y[cl])\n")
                    
                    if clusParams.maxCol[cl] == y
                        clusParams.Q_l_Y[cl] = clusParams.Q_l_Y[cl] + ch
                    end
                    write(file, "clusParams.Q_l_Y[$cl] = $(clusParams.Q_l_Y[cl])\n")
                end

                write(file,"###########################################\n")

                first = clus_module_start(clusters, UInt32(me + 1)) + startClus
                write(file, "first = $first\n")

                # exit(404)
                write(file, "FOR ic in 1 to $nClusInIter\n")
                for ic in 1:nClusInIter
                    h = UInt32(first - 1 + ic)
                    write(file,"h is: $h\n")
                    if (h > max_hits())
                        break
                    end
                    @assert h <= n_hits(hits)
                    @assert h <= clus_module_start(clusters, UInt32(me + 2))
                    write(file,"n_hits = $(n_hits(hits))\n")
                    write(file,"clus_module_start = $(clus_module_start(clusters, UInt32(me + 2)))\n")


                    position_corr(commonParams(cpeParams), detParams(cpeParams,UInt32(me + 1)), clusParams, UInt32(ic));
                    errorFromDB(commonParams(cpeParams), detParams(cpeParams,UInt32(me + 1)), clusParams, UInt32(ic));
                    
                    charge(hits, h, clusParams.charge[ic])
                    detector_index(hits, h, me)

                    xl = x_local(hits, h, clusParams.xpos[ic])
                    yl = y_local(hits, h, clusParams.ypos[ic])
                    
                    cluster_size_x(hits, h) = clusParams.xsize[ic]
                    cluster_size_y(hits, h) = clusParams.ysize[ic]

                    xerr_local(hits, h) = clusParams.xerr[ic] * clusParams.xerr[ic]
                    yerr_local(hits, h) = clusParams.yerr[ic] * clusParams.yerr[ic]
                    
                    xg::Float32 = 0
                    yg::Float32 = 0 
                    zg::Float32 = 0
                    
                    frame = detParams(cpeParams, me).frame
                    # println(xg," ", yg," ", zg)
                    toGlobal_special(frame, xl, yl, xg, yg, zg)
               
                    xg = xg - bs.x
                    yg = yg - bs.y
                    zg = zg - bs.z

                
                    set_x_global(hits, h, xg)
                    set_y_global(hits, h, yg)
                    set_z_global(hits, h, zg) 

                  
                    r_global(hits, h) = sqrt(xg * xg + yg * yg)
                    i_phi(hits, h) = unsafe_atan2s<7>(yg, xg)

                end
            end

        end
end 

# function test_getHits()
#     # Mock data setup

#     common_params = CommonParams(
#     0.1f0,
#     0.2f0,
#     0.01f0,
#     0.01f0
#     )

#     det_params = [DetParams() for _ in 1:10]  
#     layer_geometry = LayerGeometry(
#         [UInt32(0) for _ in 1:10],  
#         [UInt8(1) for _ in 1:10]        
#     )

   
#     number_of_ladders_in_barrel = 10  # Example number, adjust as needed

#     ladderZ = [1.0f0, 2.0f0, 3.0f0]  # Replace with realistic Z positions
#     ladderX = [0.5f0, 1.5f0, 2.5f0]  # Replace with realistic X positions
#     ladderY = [0.2f0, 0.4f0, 0.6f0]  # Replace with realistic Y positions
#     ladderR = [1.2f0, 2.2f0, 3.2f0]  # Replace with realistic radius values
#     ladderMinZ = [0.0f0, 1.0f0, 2.0f0]  # Replace with realistic min Z values
#     ladderMaxZ = [1.5f0, 2.5f0, 3.5f0]  # Replace with realistic max Z values

   
#     endCapZ = (0.1f0, -0.1f0)  # Example values for positive and negative end caps

#     average_geometry = AverageGeometry(
#         number_of_ladders_in_barrel,
#         ladderZ,
#         ladderX,
#         ladderY,
#         ladderR,
#         ladderMinZ,
#         ladderMaxZ,
#         endCapZ
#     )

#     cpeParams = ParamsOnGPU(
#         common_params,
#         det_params,
#         layer_geometry,
#         average_geometry
#     )


#     bs = BeamSpotPOD(
#         0.0f0,
#         0.0f0,
#         0.0f0,
#         0.1f0,
#         0.1f0
#     )
     
#     xx = [500, 600, 700, 800, 900]   # Example X coordinates as Int16
#     yy = [15, 25, 35, 45, 55]       # Example Y coordinates as Int16
#     adc = [100, 150, 200, 250, 300] # Example ADC values as Int16
#     module_ind = [10, 20, 30, 40, 50] # Example module indices as Int16
#     clus = [5, 10, 15, 20, 25]      

#     pdigis = DeviceConstView(
#         xx = xx,
#         yy = yy,
#         adc = adc,
#         module_ind = module_ind,
#         clus = clus
#     ) 

#     xx = [100, 200, 300, 400, 500]  # Example X coordinates as Int16
#     yy = [10, 20, 30, 40, 50]      # Example Y coordinates as Int16
#     adc = [15, 25, 35, 45, 55]     # Example ADC values as Int16
#     module_ind = [1, 2, 3, 4, 5]   # Example module indices as Int16
#     clus = [10, 20, 30, 40, 50]    # Example cluster values as Int32

#     pclusters = DeviceConstView(
#         xx,
#         yy,
#         adc,
#         module_ind,
#         clus
#     )


#     m_xl = [1.0, 2.0, 3.0, 4.0]                 # X positions of hits
#     m_yl = [5.0, 6.0, 7.0, 8.0]                 # Y positions of hits
#     m_xerr = [0.1, 0.2, 0.1, 0.2]               # X errors of hits
#     m_yerr = [0.1, 0.2, 0.2, 0.1]               # Y errors of hits
#     m_xg = [0.5, 0.6, 0.7, 0.8]                 # X global coordinates
#     m_yg = [0.5, 0.6, 0.7, 0.8]                 # Y global coordinates
#     m_zg = [1.0, 2.0, 3.0, 4.0]                 # Z global coordinates
#     m_rg = [1.1, 1.2, 1.3, 1.4]                 # R global coordinates

#     m_iphi = [10, 20, 30, 40]                   # Phi indices
#     m_charge = [1000, 2000, 1500, 2500]         # Charge values
#     m_xsize = [10, 20, 15, 25]                  # X sizes
#     m_ysize = [5, 10, 7, 12]                    # Y sizes
#     m_det_ind = [1, 2, 3, 4]                    # Detector indices


#     average_geometry = AverageGeometry(
#         number_of_ladders_in_barrel = 5,
#         ladderZ = [0.1, 0.2, 0.3, 0.4, 0.5],
#         ladderX = [1.0, 2.0, 3.0, 4.0, 5.0],
#         ladderY = [1.1, 2.1, 3.1, 4.1, 5.1],
#         ladderR = [1.5, 2.5, 3.5, 4.5, 5.5],
#         ladderMinZ = [0.0, 0.1, 0.2, 0.3, 0.4],
#         ladderMaxZ = [0.1, 0.2, 0.3, 0.4, 0.5],
#         endCapZ = (10.0f0, -10.0f0)
#     )

    
#     cpe_params = ParamsOnGPU() 

#     hist_container = HisToContainer{Float64, 10, 100, 5, 3}()

#     hits_module_start = [0, 10, 20, 30]  
#     hits_layer_start = [0, 5, 10, 15]   

#     nHits = 4

#     tracking_rec_hit_view = TrackingRecHit2DSOAView(
#         m_xl = m_xl,
#         m_yl = m_yl,
#         m_xerr = m_xerr,
#         m_yerr = m_yerr,
#         m_xg = m_xg,
#         m_yg = m_yg,
#         m_zg = m_zg,
#         m_rg = m_rg,
#         m_iphi = m_iphi,
#         m_charge = m_charge,
#         m_xsize = m_xsize,
#         m_ysize = m_ysize,
#         m_det_ind = m_det_ind,
#         m_average_geometry = average_geometry,
#         m_cpe_params = cpe_params,
#         m_hits_module_start = hits_module_start,
#         m_hits_layer_start = hits_layer_start,
#         m_hist = hist_container,
#         m_nHits = nHits
#     )

    
#     phits = Vector{TrackingRecHit2DSOAView}(undef, 10)
#     push!(phits, tracking_rec_hit_view)

#     numElements = 100 

#     getHits(cpeParams, bs, pdigis, numElements, pclusters, phits)
# end
# println("hey hey hey")
# test_getHits()
# println("Bye bye bye")
    
end