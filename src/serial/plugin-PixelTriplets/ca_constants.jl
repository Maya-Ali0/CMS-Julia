module caConstants
    export MAX_CELLS_PER_HIT, OuterHitOfCell, CellNeighbors, CellTracks, CellNeighborsVector, CellTracksVector, HitToTuple, TupleMultiplicity
    export hindex_type
    export MAX_NUM_OF_ACTIVE_DOUBLETS, MAX_NUM_OF_LAYER_PAIRS
    using ..histogram:OneToManyAssoc
    using ..CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants:MAX_NUMBER_OF_HITS
    using ..Patatrack:VecArray
    using ..Patatrack:SimpleVector
    const MAX_NUM_TUPLES = 48 * 1024
    const MAX_NUM_QUADRUPLETS = MAX_NUM_TUPLES
    const MAX_NUM_OF_DOUBLETS = 2 * 1024 * 1024
    const MAX_CELLS_PER_HIT = 8 * 128
    const MAX_NUM_OF_ACTIVE_DOUBLETS = MAX_NUM_OF_DOUBLETS ÷ 8
    const MAX_NUM_OF_LAYER_PAIRS = 20
    const MAX_NUM_OF_LAYERS = 10
    const MAX_TUPLES = MAX_NUM_TUPLES
    const hindex_type = UInt16
    const tindex_type = UInt16
    const CellNeighbors = VecArray{UInt32,64}
    const CellTracks = VecArray{tindex_type,64}
    const CellNeighborsVector = SimpleVector{CellNeighbors}
    const CellTracksVector = SimpleVector{CellTracks}
    const OuterHitOfCell = VecArray{UInt32,MAX_CELLS_PER_HIT}
    # const TuplesContainer = OneToManyAssoc{hindex_type,MAX_TUPLES,5*MAX_TUPLES}
    const HitToTuple = OneToManyAssoc{tindex_type,MAX_NUMBER_OF_HITS,4*MAX_TUPLES}
    const TupleMultiplicity = OneToManyAssoc{tindex_type,8,MAX_TUPLES}
end
