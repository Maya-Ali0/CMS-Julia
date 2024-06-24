include("../CUDADataFormats/SiPixelClusterSoA.jl")
using .CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA

include("../CUDADataFormats/SiPixelDigisSoA.jl")
using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA

include("../CUDADataFormats/SiPixelDigiErrorsSoA.jl")
using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigiErrorsSoA
"""
Phase 1 Geometry Constants
"""
module pixelgpudetails
    const LAYER_START_BIT::UInt32 = 20 # 4 layers
    const LADDER_START_BIT::UInt32 = 12 # 148 ladders
    const MODULE_START_BIT::UInt32 = 2 # 1856 silicon modules each with 160 x 416 pixels connected to 16 ReadOut Chips (ROC)

    const PANEL_START_BIT::UInt32 = 10 # Group of ladders
    const DISK_START_BIT::UInt32 = 18  
    const BLADE_START_BIT::UInt32 = 12 # For FPIX, One half disk has 28 Blades (11 inner) and (17 outer). One module mounts each side of a blade

    const LAYER_MASK::UInt32 = 0xF # 4 bits
    const LADDER_MASK::UInt32 = 0xFF # 8 bits
    const MODULE_MASK::UInt32 = 0x3FF # 11 bits
    const PANEL_MASK::UInt32 = 0x3 # 3 bits
    const DISK_MASK::UInt32 = 0xF # 4 bits
    const BLADE_MASK::UInt32 = 0x3F # 7 bits


    const LINK_BITS::UInt32 = 6 
    const ROC_BITS::UInt32 = 5  
    const DCOL_BITS::UInt32 = 5 
    const PXID_BITS::UInt32 = 8
    const ADC_BITS::UInt32 = 8

    """
    [  6 bits  | 5 bits | 5 bits |  8 bits  |8 bits  ]
    [  Link    |  ROC   |  DCOL  |  PXID    |  ADC   ]
    Special For Layer 1
    """
    const LINK_BITS_L1::UInt32 = 6
    const ROC_BITS_L1::UInt32 = 5
    const COL_BITS_L1::UInt32 = 6
    const ROW_BITS_L1::UInt32 = 7
    const OMIT_ERR_BITS::UInt32 = 1 
    """
    Each ROC is an 80x52 pixel unit cell 
    They are grouping columns by 2 : 26 DCOL
    """
    const MAX_ROC_INDEX::UInt32 = 8 
    const NUM_ROWS_IN_ROC::UInt32 = 80 
    const NUM_COL_IN_ROC::UInt32 = 52 

    const MAX_WORD::UInt32 = 2000 # maxword in what ?

    const ADC_SHIFT::UInt32 = 0
    const PXID_SHIFT::UInt32 = ADC_SHIFT + ADC_BITS
    const DCOL_SHIFT::UInt32 = PXID_SHIFT + PXID_BITS
    const ROC_SHIFT::UInt32 = DCOL_SHIFT + DCOL_BITS
    const LINK_SHIFT::UInt32 = ROC_SHIFT + ROC_BITS
    """
    Special For Layer 1 ROC
    """
    const ROW_SHIFT::UInt32 = ADC_SHIFT + ADC_BITS
    const COL_shift::UInt32 = ROW_SHIFT + ROW_BITS_L1
    const OMIT_ERR_shift::UInt32 = 20 # ?

    const LINK_MASK::UInt32 = ~(~UInt32(0) << LINK_BITS_L1)
    const ROC_MASK::UInt32 = ~(~UInt32(0) << ROC_BITS_L1)
    const COL_MASK::UInt32 = ~(~UInt32(0) << COL_BITS_L1)
    const ROW_MASK::UInt32 = ~(~UInt32(0) << ROW_BITS_L1)
    const DCOL_MASK::UInt32 = ~(~UInt32(0) << DCOL_BITS) # ?
    const PXID_MASK::UInt32 = ~(~UInt32(0) << PXID_BITS) # ?
    const ADC_MASK::UInt32 = ~(~UInt32(0) << ADC_BITS)
    const ERROR_MASK::UInt32 = ~(~UInt32(0) << ROC_BITS_L1) # ?
    const OMIT_ERR_MASK::UInt32 = ~(~UInt32(0) << OMIT_ERR_BITS) # ?

    struct DetIdGPU
        raw_id::UInt32
        roc_in_det::UInt32
        module_id::UInt32
    end
    struct Pixel
        row::UInt32
        col::UInt32
    end
    const PackedDigiType = UInt32
    struct Packing
        
        row_width::UInt32
        column_width::UInt32
        adc_width::UInt32

        row_shift::UInt32
        column_shift::UInt32
        time_shift::UInt32
        adc_shift::UInt32

        row_mask::PackedDigiType
        column_mask::PackedDigiType
        time_mask::PackedDigiType
        adc_mask::PackedDigiType
        rowcol_mask::PackedDigiType

        max_row::UInt32
        max_column::UInt32
        max_adc::UInt32
        @inline function Packing(row_w::UInt32,column_w::UInt32,time_w::UInt32,adc_w::UInt32)
            new(
            row_w,
            column_w,
            adc_w,
            0,  
            row_w,
            row_w + column_w,
            row_w + column_w + time_w,
            ~(~UInt32(0) << row_w),
            ~(~UInt32(0) << column_w),
            ~(~UInt32(0) << time_w),
            ~(~UInt32(0) << adc_w),
            ~(~UInt32(0) << (column_w + row_w)),
            ~(~UInt32(0) << row_w),
            ~(~UInt32(0) << column_w),
            ~(~UInt32(0) << adc_w)
        )
        end
    end 


    Packing() = Packing(11,11,0,11)


    @inline function pack(row::UInt32,col::UInt32,adc::UInt32)::UInt32
        the_packing::Packing = Packing()
        adc = min(adc,the_packing.max_adc)
        return (row << the_packing.ROW_SHIFT) | (col << the_packing.column_shift) | (adc << the_packing.ADC_SHIFT);
    end

    function pixelToChannel(row::UInt32,col::UInt32)::UInt32
        the_packing::Packing = Packing()
        return (row << the_packing.column_width) | col
    end

    const MAX_FED_WORDS = MAX_FED * MAX_WORD

    struct WordFedAppender
        words::Vector{UInt32}
        fed_ids::Vector{UInt8}
    end

    WordFedAppender() = WordFedAppender(Vector{UInt32}(undef,MAX_FED_WORDS),Vector{UInt8}(undef,MAX_FED_WORDS))

    get_word(self::WordFedAppender) = return self.words

    get_fed_id(self::WordFedAppender) = return self.fed_ids
    

    function initialize_word_fed(word_fed_appender::WordFedAppender, fed_id::Int , word_counter_gpu::UInt , src::Vector{UInt8} , length::UInt)
        for index ∈ word_counter_gpu+1:word_counter_gpu + length
            counter = index-word_counter_gpu
            start_index_byte = 4*(counter-1) + 1
            word_32::Vector{UInt8} = src[start_index_byte:start_index_byte+3]
            get_word(word_fed_appender)[index] = reinterpret(UInt32,word_32)[1]
        end
        get_fed_id(word_fed_appender)[(cld((word_counter_gpu+1),2):(word_counter_gpu + length) ÷ 2)] .= fed_id
    end

    struct SiPixelRawToClusterGPUKernel
        digis_d::SiPixelDigisSOA
        clusters_d::SiPixelClustersSOA
        digi_errors_d::SiPixelDigiErrorsSOA
    
        function SiPixelRawToClusterGPUKernel()
            new(SiPixelDigisSOA(), SiPixelClustersSOA(), SiPixelDigiErrorsSOA())
        end
    end
    
    @inline get_errors(self::SiPixelRawToClusterGPUKernel) = return self.digi_errors_d

    @inlune get_results(self::SiPixelRawToClusterGPUKernel) = return Pair{SiPixelDigisSOA,SiPixelClustersSoA}(self.digis_d,self.clusters_d)

    function make_clusters(self::SiPixelRawToClusterGPUKernel,is_run_2::Bool,cabling_map::SiPixelFedCablingMapGPU,
        mod_to_unp::Vector{UInt8},gains::SiPixelGainForHLTonGPU,word_fed::WordFedAppender,errors::PixelFormatterErrors,
        word_counter::UInt32,fed_counter::UInt32,use_quality_info::Bool,include_errors::Bool,debug::bool)

    end

    get_link(ww::UInt32)::UInt32 = (ww >> LINK_SHIFT) & LINK_MASK

    get_roc(ww::UInt32)::UInt32 = (ww >> ROC_SHIFT) & ROC_MASK

    get_adc(ww::UInt32)::UInt32 = (ww >> ADC_SHIFT) & ADC_MASK

    is_barrel(raw_id::UInt32)::Bool = 1 == ((raw_id >> 25) & 0x7)

    function get_raw_id(cabling_map::SiPixelFedCablingMapGPU , fed::UInt8 , link::UInt32 , roc::UInt32)::DetIdGPU
        index::UInt32 = fed*MAX_LINK*MAX_ROC + (link-1) * MAX_ROC + roc 
        det_id = DetIdGPU(cabling_map.raw_id[index],cabling_map.roc_in_det[index],cabling_map.module_id[index])
    end

    function frame_conversion(bpix::bool,side::Int,layer::UInt32,roc_id_in_det_unit::UInt32,local_pixel::Pixel)
        slope_row = slope_col = 0
        row_offset = col_offset = 0

        if bpix # if barrel pixel
            if side == -1 && layer != 1 # -Z side: 4 non flipped modules oriented like 'dddd', except Layer 1
                if roc_id_in_det_unit < 8 # upper 8 ROCs in 2x8 array
                    slope_row = 1 
                    slope_col = -1
                    row_offset = 0 
                    col_offset = (8 - roc_id_in_det_unit) * NUM_COL_IN_ROC - 1
                else # lower 8 ROCs in 2x8 array
                    slope_row = -1
                    slope_col = 1
                    row_offset = 2 * NUM_ROWS_IN_ROC - 1
                    col_offset = (roc_id_in_det_unit - 8) * NUM_COL_IN_ROC
                end
            else # +Z side: 4 non flipped modules oriented like 'pppp', but all 8 in layer1
                if roc_id_in_det_unit < 8
                    slope_row = -1
                    slope_col = 1
                    row_offset = 2 * NUM_ROWS_IN_ROC - 1
                    col_offset = roc_id_in_det_unit * NUM_COL_IN_ROC
                else
                    slope_row = 1
                    slope_col = -1
                    row_offset = 0 
                    col_offset = (16 - roc_id_in_det_unit) * NUM_COL_IN_ROC - 1
                end
            end
        else # if fpix pixel
            if side == -1 # pannel 1
                if roc_id_in_det_unit < 8
                    slope_row = 1
                    slope_col = -1
                    row_offset = 0
                    col_offset = (8 - roc_id_in_det_unit) * NUM_COL_IN_ROC - 1
                else
                    slope_row = -1
                    slope_col = 1
                    row_offset = 2 * NUM_ROWS_IN_ROC - 1
                    col_offset = (roc_id_in_det_unit - 8) * NUM_COL_IN_ROC
                end
            else # pannel 2
                if roc_id_in_det_unit < 8
                    slope_row = 1
                    slope_col = -1
                    row_offset = 0 
                    col_offset = (8 - roc_id_in_det_unit) * NUM_COL_IN_ROC - 1
                else
                    slope_row = -1
                    slope_col = 1
                    row_offset = 2 * NUM_ROWS_IN_ROC - 1
                    col_offset = (roc_id_in_det_unit - 8) * NUM_COL_IN_ROC
                end
            end
        end
        g_row::UInt32 = slope_row * local_pixel.row + row_offset
        g_col::UInt32 = slope_col * local_pixel.col + col_offset

        global_pixel::Pixel = Pixel(g_row,g_col)
        return global_pixel
    end

    function conversion_error(fed_id::UInt8, status::UInt8, debug::Bool = false)::UInt8
        error_type::UInt8 = 0
    
        if debug
            # Import the Printf package for formatted printing
            using Printf
        end
    
        # Switch statement equivalent using multiple if-else
        if status == 1
            if debug
                @printf("Error in Fed: %i, invalid channel Id (error_type = 35)\n", fedId)
            end
            error_type = 35
        elseif status == 2
            if debug
                @printf("Error in Fed: %i, invalid ROC Id (error_type = 36)\n", fedId)
            end
            error_type = 36
        elseif status == 3
            if debug
                @printf("Error in Fed: %i, invalid dcol/pixel value (error_type = 37)\n", fedId)
            end
            error_type = 37
        elseif status == 4
            if debug
                @printf("Error in Fed: %i, dcol/pixel read out of order (error_type = 38)\n", fedId)
            end
            error_type = 38
        else
            if debug
                @printf("Cabling check returned unexpected result, status = %i\n", status)
            end
        end
    
        return error_type
    end

    row_col_is_valid(roc_row, roc_col)::Bool = (roc_row < NUM_ROWS_IN_ROC) & (roc_col < NUM_COL_IN_ROC)
    dcol_is_valid(dcol::UInt32,px_id::UInt32) = (dcol < 26) & (2 <= pxid) & (pxid < 162)

    function check_roc(error_word::UInt32, fed_id::UInt8, link::UInt32, cabling_map::SiPixelFedCablingMapGPU, debug::Bool = false)::UInt8
        
    




            


end