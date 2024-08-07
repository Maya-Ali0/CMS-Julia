module gpuCACELL
    using ..caConstants
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    using Main:VecArray
    using Main:SimpleVector
    const ptr_as_int = UInt64
    #const Hits = TrackingRecHit2DSOAView
    const TmpTuple = VecArray{UInt32,6}


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
        the_used = 0 
        self.the_inner_r = r_global(hh,inner_hit_id)
        self.the_inner_z = z_global(hh,inner_hit_id)
        self.the_outer_neighbors = cell_neighbors[1]
        self.the_tracks = cell_tracks[1]
        #@assert()
        #@assert()
    end
    
end
