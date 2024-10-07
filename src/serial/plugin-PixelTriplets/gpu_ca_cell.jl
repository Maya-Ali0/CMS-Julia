module gpuCACELL
    using ..caConstants
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h
    using Patatrack:VecArray
    using Patatrack:SimpleVector
    using Patatrack:empty,extend!,reset!
    using Printf
    const ptr_as_int = UInt64
    const Hits = TrackingRecHit2DSOAView
    const TmpTuple = VecArray{UInt32,6}
    using ..CUDADataFormats_TrackingRecHit_interface_TrackingRecHit2DSOAView_h:z_global,r_global
    using Patatrack:CircleEq, compute, dca0, curvature
    export GPUCACell
    export get_outer_x,get_outer_y,get_outer_z,get_inner_x,get_inner_y,get_inner_z,get_inner_det_index
    # using Main:CircleEq
    # using Main:curvature
    # using Main:dca0
    # using Main:extend!
    # using Main:reset
    # using Main:push!
    # using Main:empty

    mutable struct GPUCACell
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
    


function get_inner_hit_id(self::GPUCACell)
    return self.the_inner_hit_id
end

function get_inner_x(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return x_global(hh, self.the_inner_hit_id)
end

function get_inner_y(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return y_global(hh, self.the_inner_hit_id)
end

function get_outer_x(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return x_global(hh, self.the_outer_hit_id)
end

function get_outer_y(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return y_global(hh, self.the_outer_hit_id)
end

function get_inner_r(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return self.the_inner_r
end

function get_inner_z(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return self.the_inner_z
end

function get_outer_r(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return r_global(hh, self.the_outer_hit_id)
end

function get_outer_z(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return z_global(hh, self.the_outer_hit_id)
end

function get_inner_det_index(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return detector_index(hh, self.the_inner_hit_id)
end

function get_outer_det_index(self::GPUCACell, hh::TrackingRecHit2DSOAView)
    return detector_index(hh, self.the_outer_hit_id)
end

function are_aligned(r1, z1, ri, zi, ro, zo, pt_min, theta_cut)
    radius_diff = abs(r1 - ro)
    distance_13_squared = radius_diff * radius_diff + (z1 - zo) * (z1 - zo)
    p_min = pt_min * √(distance_13_squared)
    tan_12_13_half_mul_distance_13_squared = abs(z1 * (ri - ro) + zi * (ro - r1) + zo * (r1 - ri))
    return tan_12_13_half_mul_distance_13_squared * p_min <= theta_cut * distance_13_squared * radius_diff
end

function dca_cut(cell::GPUCACell, other_cell::GPUCACell, hh::TrackingRecHit2DSOAView, region_origin_radius_plus_tolerance::AbstractFloat, max_curv::AbstractFloat)
    x1 = get_inner_x(other_cell, hh)
    y1 = get_inner_y(other_cell, hh)

    x2 = get_inner_x(cell, hh)
    y2 = get_inner_y(cell, hh)

    x3 = get_outer_x(cell, hh)
    y3 = get_outer_y(cell, hh)

    eq = CircleEq{Float32}()
    compute(eq,x1, y1, x2, y2, x3, y3)
    curvature_c = curvature(eq)
    if curvature_c > max_curv
        return false
    end
    return abs(dca0(eq)) < region_origin_radius_plus_tolerance * abs(curvature_c)
end

function outer_neighbors(self::GPUCACell)
    return self.the_outer_neighbors
end
"""
check if oughter_neighbor vector for the other_doublet if it is empty
if its empty, assign for it a neighbors slot within cell_neighbors by extending cell_neighbors.
Finally push the second doublet index t to the oughter_neighbor forming the triplet
"""
function add_outer_neighbor(other_cell::GPUCACell, t::Integer, cell_neighbors::CellNeighborsVector)
    outer_neighbor = outer_neighbors(other_cell)
    if empty(outer_neighbor)
        i = extend!(cell_neighbors)
        if i > 1
            reset!(cell_neighbors[i])
            outer_neighbor = cell_neighbors[i]
        else
            return -1
        end
    end
    return push!(outer_neighbor, UInt32(t))
end

function find_ntuplets(self,::Val{DEPTH},cells,cell_tracks,found_ntuplets,apc,quality,temp_ntuplet,min_hits_per_ntuplet,start_at_0)
    push!(temp_ntuplet,self.doublet_id)
    @assert length(temp_ntuplet) <= 4
    last = true
    for i ∈ 1:length(self.the_outer_neighbors)
        other_cell = self.the_outer_neighbors[i]

        if cells[other_cell].the_doublet_id < 0 
            continue # killed by early_fishbone
        end
        last = false
        find_ntuplets(self,Val{DEPTH-1}(),cells,cell_tracks,found_ntuplets,apc,quality,temp_ntuplet,min_hits_per_ntuplet,start_at_0)
    end
    if last
        if length(temp_ntuplet) >= min_hits_per_ntuplet - 1
           hits = @MArray [0,0,0,0,0,0]
           nh = length(temp_ntuplet)
            for c ∈ temp_ntuplet
                hits[nh] = cells[c].the_inner_hit_id
                nh -= 1
            end
            hits[length(temp_ntuplet)+1] = self.the_outer_hit_id
            it = bulk_fill(found_ntuplets,apc,hits,length(temp_ntuplet)+1)
            
            if it >= 0
                for c ∈ temp_ntuplet
                    add_track(cells[c],it,cell_tracks)
                end
                quality[it] = bad
            end
        end
    end
    pop!(temp_ntuplet)
    @assert length(temp_ntuplet) < 4
end

end