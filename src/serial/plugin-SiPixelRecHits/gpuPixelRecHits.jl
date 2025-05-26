module RecoLocalTracker_SiPixelRecHits_plugins_gpuPixelRecHits_h

using ..BeamSpotPOD_h: BeamSpotPOD
using ..Geometry_TrackerGeometryBuilder_phase1PixelTopology_h.phase1PixelTopology
# using ..gpuConfig
using ..CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA
using ..CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA
# using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DHeterogeneous_h
using ..PixelGPU_h
using ..SOA_h
using ..DataFormatsMathAPPROX_ATAN2_H
using ..CUDA
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
                  pdigis::SiPixelDigisSoA,
                  numElements::UInt32,
                  pclusters::SiPixelClustersSoA,
                  phits::TrackingRecHit2DHeterogeneous)

          hits = phits
          digis = pdigis
          clusters = pclusters

          # Obtain thread and block indices
          tx = threadIdx().x
          bx = blockIdx().x
          bd = blockDim().x

          if bx == 1
               agc = average_geometry(hits)
               ag  = averageGeometry(cpeParams)

               # Parallel loop: each thread processes a subset of ladders
               for il = tx:bd:number_of_ladders_in_barrel
                    agc.ladderZ[il]    = ag.ladderZ[il]    - bs.z
                    agc.ladderX[il]    = ag.ladderX[il]    - bs.x
                    agc.ladderY[il]    = ag.ladderY[il]    - bs.y
                    agc.ladderR[il]    = sqrt( agc.ladderX[il]^2 + agc.ladderY[il]^2 )
                    agc.ladderMinZ[il] = ag.ladderMinZ[il] - bs.z
                    agc.ladderMaxZ[il] = ag.ladderMaxZ[il] - bs.z
               end

               # One thread (the first thread) handles the endcap update
               if tx == 1
                    agc.endCapZ[1] = ag.endCapZ[1] - bs.z
                    agc.endCapZ[2] = ag.endCapZ[2] - bs.z
               end
          end

          InvId = 9999
          MaxHitsInIter = PixelGPU_h.MaxHitsInIter


          clusParamSM = ClusParamsT{160,CuDeviceVector{UInt32,AS.Shared},CuDeviceVector{Int32,AS.Shared},CuDeviceVector{Float32,AS.Shared},CuDeviceVector{Int16,AS.Shared}}

          clusParams = @cuStaticSharedMem(clusParamSM,1)
          clusParams[1] = clusParamSM()
          clusParams_d = clusParams[1]

          me = module_id(clusters)[bx]
          nclus = clus_in_module(clusters)[UInt32(me + 1)]

          if nclus == 0
               return
          end

          endClus = nclus

          for startClus in 1:MaxHitsInIter:(endClus)
               first = module_start(clusters)[bx + 1]

               nClusInIter = min(MaxHitsInIter, endClus - startClus + 1)
               lastClus = startClus - 1 + nClusInIter
               
               @assert nClusInIter <= nclus
               @assert nClusInIter > 0
               @assert lastClus <= nclus
               @assert nclus > MaxHitsInIter || (1 == startClus && nClusInIter == nclus && lastClus == nclus)

               for ic = tx:bd:nClusInIter
                    clusParams_d.minRow[ic] = UInt32(typemax(UInt32))
                    clusParams_d.maxRow[ic] = zero(UInt32)
                    clusParams_d.minCol[ic] = UInt32(typemax(UInt32))
                    clusParams_d.maxCol[ic] = zero(UInt32)
                    clusParams_d.charge[ic] = zero(UInt32)
                    clusParams_d.Q_f_X[ic] = zero(UInt32)
                    clusParams_d.Q_l_X[ic] = zero(UInt32)
                    clusParams_d.Q_f_Y[ic] = zero(UInt32)
                    clusParams_d.Q_l_Y[ic] = zero(UInt32)
               end

               first = first + tx - 1

               sync_threads()


               for i = first:bd:numElements
                    id = module_ind(digis)[i]

                    if id == InvId
                        continue
                    end

                    if id != me
                        break
                    end

                    cl = clus(digis)[i]
                    
                    if cl < startClus || cl > lastClus
                        continue
                    end
                    
                    x = xx(digis)[i]
                    
                    y = yy(digis)[i]
                    
                    cl = cl - startClus + 1
                    @assert cl >= 1 
                    @assert cl <= MaxHitsInIter  # will verify later
                    
 
                    CUDA.atomic_min!(pointer(clusParams_d.minRow, cl), UInt32(x))
                    CUDA.atomic_max!(pointer(clusParams_d.maxRow, cl), UInt32(x))
                    CUDA.atomic_min!(pointer(clusParams_d.minCol, cl), UInt32(y))
                    CUDA.atomic_max!(pointer(clusParams_d.maxCol, cl), UInt32(y))
                end

                sync_threads()

                pixmx = typemax(UInt16)

                for i = first:bd:numElements
                    id = module_ind(digis)[i]

                    if id == InvId
                        continue
                    end

                    if id != me
                        break
                    end

                    cl = clus(digis)[i]
                    
                    if cl < startClus || cl > lastClus
                        continue
                    end
                    
                    x = xx(digis)[i]
                    
                    y = yy(digis)[i]
                    
                    cl = cl - startClus + 1
                    @assert cl >= 1 
                    @assert cl <= MaxHitsInIter  # will verify later
                    ch = min(adc(digis)[i], pixmx)

                    CUDA.atomic_add!(pointer(clusParams_d.charge, cl), Int32(ch))
                    if clusParams_d.minRow[cl] == x
                         CUDA.atomic_add!(pointer(clusParams_d.Q_f_X, cl), Int32(ch))
                    end
                    if clusParams_d.maxRow[cl] == x
                         CUDA.atomic_add!(pointer(clusParams_d.Q_l_X, cl), Int32(ch))
                    end
                    if clusParams_d.minCol[cl] == y
                         CUDA.atomic_add!(pointer(clusParams_d.Q_f_Y, cl), Int32(ch))
                    end
                    if clusParams_d.maxCol[cl] == y
                         CUDA.atomic_add!(pointer(clusParams_d.Q_l_Y, cl), Int32(ch))
                    end
                end

                sync_threads()







          end


          @cuprint(pclusters.nClusters_h,"\n")
          return nothing
          # hits = phits
          # digis = pdigis
          # clusters = pclusters

          # clusParams = @cuStaticSharedMem(ClusParamsT{160},1)
          # clusParams[1] = ClusParamsT{160}()
          # clusParams_d = clusParams[1]


     #     InvId = 9999
     #     MaxHitsInIter = PixelGPU_h.MaxHitsInIter

     #     clusParams = ClusParamsT{100000}() #160 ?? 

     #    firstModule = 1
     # #    write(file, "firstModule: $firstModule\n")

     #    endModule = module_start(clusters, 1)
        #print(endModule)
     #    write(file, "endModule: $endModule\n")
     #    write(file, "##############################################\n")
     #    write(file, "FOR module 1 to $(endModule )\n")

     #    close(file)
end 


    
end