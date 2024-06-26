module Geometry_TrackerGeometryBuilder_phase1PixelTopology_h

module phase1PixelTopology
    num_rows_in_ROC = 80
    num_cols_in_ROC = 52
    last_row_in_roc = num_rows_in_ROC - 1
    last_col_in_roc = num_cols_in_ROC - 1

    num_rows_in_module = 2 * num_rows_in_ROC
    num_cols_in_module = 8 * num_cols_in_ROC
    last_row_in_module = num_rows_in_module - 1
    last_col_in_module = num_cols_in_module - 1
    
    x_offset = -81
    y_offset = -54 * 4

    num_pixs_in_module = num_rows_in_module * num_cols_in_module

    number_of_modules = 1856
    numer_of_layers = 10
    layer_start = [
        0,
        96,
        320,
        672,   # barrel
        1184,
        1296,
        1408,  # positive endcap
        1520,
        1632,
        1744,  # negative endcap
        number_of_modules
    ]
    
    layer_name = [
        "BL1",
        "BL2",
        "BL3",
        "BL4",   # barrel
        "E+1",
        "E+2",
        "E+3",  # positive endcap
        "E-1",
        "E-2",
        "E-3"   # negative endcap
    ]


    number_of_module_in_barrel = 1184
    number_of_ladders_in_barrel = number_of_module_in_barrel / 8

    # Helper function to map indices to an array using function `f`
    map_to_array_helper(f::Function, indices) = [f(i) for i in indices]

    # Function to generate an array of size `N` using `map_to_array_helper`
    function map_to_array(N::UInt32, f::Function)
        indices = 0:N-1
        return map_to_array_helper(f, indices)
    end

    function find_max_module_stride()
        n = 2
        while true
            all_divisible = true
            for i in 1:10
                if layer_start[i+1] % n != 0
                    all_divisible = false
                    break
                end
            end
            if all_divisible
                return n
            end
            n *= 2
        end
    end

    max_module_stride = find_max_module_stride()

    function find_layer(det_id::UInt32)
        for i in 0:11
            if det_id < layer_start[i + 1]
                return i
            end
        end
        return 11
    end

    function find_layer_from_compact(det_id::UInt32)
        det_id *= max_module_stride
        for i in 0:11
            if det_id < layer_start[i + 1]
                return i
            end
        end
        return 11
    end

    layer_index_size = number_of_modules ÷ max_module_stride

    layer = map_to_array(layer_index_size, find_layer_from_compact)

    function validate_layer_index()::Bool
        res = true
        for i in 0:number_of_modules 
            j = i ÷ max_module_stride
            res = layer[j] < 10
            res = i >= layer_start[layer[j]]
            res = i < layer_start[layer[j]+1]
        end
        return res
    end

    @assert validate_layer_index() "layer from detIndex algo is buggy"

    function divu52(n::UInt16)
        n = n >> 2
        q = (n >> 1) + (n >> 4)
        q = q + (q >> 4) + (q >> 5)
        q = q >> 3
        r = n - q * 13
        return q + ((r + 3) >> 4)
    end
    
    @inline function is_edge_x(px::UInt16)::Bool
        return (px == 0) | (px == last_row_in_module)
    end
    
    @inline function is_edge_y(py::UInt16)::Bool
        return (py == 0) | (py == last_col_in_module)
    end

    @inline function to_ROC_x(px::UInt16)::UInt16
        return (px < num_rows_in_ROC) ? px : px - num_rows_in_ROC
    end

    @inline function to_ROC_x(py::UInt16)::UInt16
        roc = divu52(py)
        return py - 52 * roc
    end

    @inline function is_big_pix_y(py::UInt16)::Bool
        ly = to_ROC_x(py)
        return (ly == 0) | (ly == last_col_in_roc)
    end

    @inline function local_x(px::UInt16)::UInt16
        shift = 0
        if px > last_row_in_roc
            shift += 1
        end
        if px > num_rows_in_ROC
            shift += 1
        end
        return px + shift
    end

    @inline function local_y(py::UInt16)::UInt16
        roc = divu52(py)
        shift = 2 * roc
        y_in_ROC = py - 52 * roc
        if y_in_ROC > 0
            shift += 1
        end
        return py + shift
    end

    using StaticArrays

    struct AverageGeometry
        numberOfLaddersInBarrel::Int
        ladderZ::SVector{Float32, numberOfLaddersInBarrel}
        ladderX::SVector{Float32, numberOfLaddersInBarrel}
        ladderY::SVector{Float32, numberOfLaddersInBarrel}
        ladderR::SVector{Float32, numberOfLaddersInBarrel}
        ladderMinZ::SVector{Float32, numberOfLaddersInBarrel}
        ladderMaxZ::SVector{Float32, numberOfLaddersInBarrel}
        endCapZ::NTuple{2, Float32}  # just for pos and neg Layer1
    end

end

end
