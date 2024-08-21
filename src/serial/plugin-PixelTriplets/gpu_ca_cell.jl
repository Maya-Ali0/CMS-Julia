module gpuCACELL
    using ..caConstants
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    using Patatrack:VecArray
    using Patatrack:SimpleVector
    using Printf
    const ptr_as_int = UInt64
    const Hits = TrackingRecHit2DSOAView
    const TmpTuple = VecArray{UInt32,6}
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h:z_global,r_global
    export GPUCACell

    struct GPUCACell
        the_outer_neighbors::CellNeighbors
        the_tracks::CellTracks
        the_doublet_id::Int32
        the_layer_pair_id::Int16
        the_used::UInt16
        the_inner_z::Float32
        the_inner_r::Float32
        the_inner_hit_id::hindex_type
        the_outer_hit_id::hindex_type
        function GPUCACell(cell_neighbors::CellNeighborsVector,cell_tracks::CellTracksVector,hh::Hits,layer_pair_id::Integer,doublet_id::Integer,
            inner_hit_id::Integer,outer_hit_id::Integer,file)
            z_global_inner = z_global(hh,inner_hit_id)
            r_global_inner = r_global(hh,inner_hit_id)
            # z_global_inner_str = @sprintf("%.8g", z_global_inner)
            # r_global_inner_str = @sprintf("%.8g", r_global_inner)
            # Construct the string to append to the file
            # doublet_id -=1
            # layer_pair_id -=1
            # inner_hit_id -= 1
            # outer_hit_id -= 1

            # output_string = @sprintf("doublet_id: %d, layer_pair_id: %d, z_global_inner: %s, r_global_inner: %s, inner_hit_id: %d, outer_hit_id: %d\n",
            # doublet_id, layer_pair_id, z_global_inner_str, r_global_inner_str, inner_hit_id, outer_hit_id)
            # doublet_id +=1
            # layer_pair_id +=1
            # inner_hit_id += 1
            # outer_hit_id += 1
            # Open the file in append mode and write the output_string
            
            #write(file, output_string)
            
            new(cell_neighbors[1],cell_tracks[1],doublet_id,layer_pair_id,0,z_global_inner,r_global_inner,inner_hit_id,outer_hit_id)
        end
    end
    print_cell(self::GPUCACell) = @printf("printing cell: %d, on layerPair: %d, innerHitId: %d, outerHitId: %d \n",
           theDoubletId,
           theLayerPairId,
           theInnerHitId,
           theOuterHitId)
    
    function init(self::GPUCACell,cell_neighbors::CellNeighborsVector,cell_tracks::CellTracksVector,hh::Hits,layer_pair_id::Integer,doublet_id::Integer,
                  inner_hit_id::Integer,outer_hit_id::Integer)
        self.the_inner_hit_id = inner_hit_id
        self.the_outer_hit_id = outer_hit_id
        self.the_doublet_id = doublet_id
        self.the_layer_pair_id = layer_pair_id
        self.the_used = 0 
        self.the_inner_r = r_global(hh,inner_hit_id)
        self.the_inner_z = z_global(hh,inner_hit_id)
        self.the_outer_neighbors = cell_neighbors[1]
        self.the_tracks = cell_tracks[1]
        #@assert()
        #@assert()
    end
    
end
