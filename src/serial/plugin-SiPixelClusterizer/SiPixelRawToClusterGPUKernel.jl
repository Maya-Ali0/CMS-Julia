

include("../CUDADataFormats/gpu_clustering_constants.jl")
using .CUDADataFormatsSiPixelClusterInterfaceGPUClusteringConstants: gpuClustering

include("../CUDACore/prefix_scan.jl")
using .prefix_scan:block_prefix_scan

"""
Phase 1 Geometry Constants
"""
module pixelGPUDetails
    include("../CUDADataFormats/SiPixelClusterSoA.jl")
    using .CUDADataFormatsSiPixelClusterInterfaceSiPixelClustersSoA:SiPixelClustersSoA
    
    include("../CUDADataFormats/SiPixelDigisSoA.jl")
    using .CUDADataFormatsSiPixelDigiInterfaceSiPixelDigisSoA:SiPixelDigisSoA

    include("../CUDADataFormats/SiPixelDigiErrorsSoA.jl")
    
    using .cudaDataFormatsSiPixelDigiInterfaceSiPixelDigiErrorsSoA:SiPixelDigiErrorsSoA

    include("../CondFormats/si_pixel_fed_cabling_map_gpu.jl")
    using .recoLocalTrackerSiPixelClusterizerSiPixelFedCablingMapGPU:SiPixelFedCablingMapGPU

    include("../DataFormats/PixelErrors.jl")
    using .DataFormatsSiPixelDigiInterfacePixelErrors: PixelErrorCompact, PixelFormatterErrors

    include("../CondFormats/si_pixel_gain_calibration_for_hlt_gpu.jl")
    using .CalibTrackerSiPixelESProducersInterfaceSiPixelGainCalibrationForHLTGPU:SiPixelGainForHLTonGPU

    using Printf
    module pixelConstants
        export LAYER_START_BIT, LADDER_START_BIT, MODULE_START_BIT, PANEL_START_BIT, DISK_START_BIT, BLADE_START_BIT, 
            LAYER_MASK, LADDER_MASK, MODULE_MASK, PANEL_MASK, DISK_MASK, BLADE_MASK,
            LINK_BITS, ROC_BITS, DCOL_BITS, PXID_BITS, ADC_BITS, LINK_BITS_L1, ROC_BITS_L1, COL_BITS_L1, ROW_BITS_L1, OMIT_ERR_BITS,
            MAX_ROC_INDEX, NUM_ROWS_IN_ROC, NUM_COL_IN_ROC, MAX_WORD, ADC_SHIFT, PXID_SHIFT, DCOL_SHIFT, ROC_SHIFT, LINK_SHIFT,
            ROW_SHIFT, COL_SHIFT, OMIT_ERR_SHIFT, LINK_MASK, ROC_MASK, COL_MASK, ROW_MASK, DCOL_MASK, PXID_MASK, ADC_MASK,
            ERROR_MASK, OMIT_ERR_MASK, MAX_FED, MAX_LINK, MAX_FED_WORDS
        const LAYER_START_BIT::UInt32 = 20 # 4 layers
        const LADDER_START_BIT::UInt32 = 12 # 148 ladders
        const MODULE_START_BIT::UInt32 = 2 # 1856 silicon modules each with 160 x 416 pixels connected to 16 ReadOut Chips (ROC) Used to determine on which side of the z-axis the pixel is on

        const PANEL_START_BIT::UInt32 = 10 # Group of ladders # Used to determine on which side of the z-axis the pixel is on
        const DISK_START_BIT::UInt32 = 18  
        const BLADE_START_BIT::UInt32 = 12 # For FPIX, One half disk has 28 Blades (11 inner) and (17 outer). One module mounts each side of a blade

        const LAYER_MASK::UInt32 = 0xF # 4 bits
        const LADDER_MASK::UInt32 = 0xFF # 8 bits
        const MODULE_MASK::UInt32 = 0x3FF # 10 bits
        const PANEL_MASK::UInt32 = 0x3 # 2 bits
        const DISK_MASK::UInt32 = 0xF # 4 bits
        const BLADE_MASK::UInt32 = 0x3F # 6 bits
        const MAX_FED::UInt32 = 150
        """
        32 bit word for pixels not on layer 1

        [  6 bits  | 5 bits | 5 bits |  8 bits  |8 bits  ]
        [  Link    |  ROC   |  DCOL  |  PXID    |  ADC   ]
        """
        const LINK_BITS::UInt32 = 6 
        const ROC_BITS::UInt32 = 5  
        const DCOL_BITS::UInt32 = 5 
        const PXID_BITS::UInt32 = 8
        const ADC_BITS::UInt32 = 8

        """
        Special For Layer 1

        [  6 bits  | 5 bits | 6 bits |  7 bits  | 8 bits  ]
        [  Link    |  ROC   |  COL   |  ROW     |   ADC   ]
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
    end
    using .pixelConstants
    """
    Detector id used to store information about the position of the pixel in the detector which are gathered from the cabling map given 
    link roc fedId
    """
    struct DetIdGPU
        raw_id::UInt32
        roc_in_det::UInt32
        module_id::UInt32
    end
    """
    Pixel Struct to store local coordinates inside ROC or global coordinates after mapping the local coordinates into its global coordinates within
    the module
    """
    struct Pixel
        row::UInt32
        col::UInt32
    end
    """
    Packing struct used to pack a digi into a 32 bit word which contains information about the global coordinates of the pixel within the module:
        row column and adc
     """
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

    """
    default outer constructor 
    """
    Packing() = Packing(11,11,0,10)

    """
    returns 32 bit word containing the packed digi
    """
    @inline function pack(row::UInt32,col::UInt32,adc::UInt32)::UInt32
        the_packing::Packing = Packing()
        adc = min(adc,the_packing.max_adc)
        return (row << the_packing.ROW_SHIFT) | (col << the_packing.column_shift) | (adc << the_packing.ADC_SHIFT);
    end
    """
    pixel packing without adc
    """
    function pixelToChannel(row::UInt32,col::UInt32)::UInt32
        the_packing::Packing = Packing()
        return (row << the_packing.column_width) | col
    end

    const MAX_FED_WORDS = pixelGPUDetails.MAX_FED * MAX_WORD

    """
    struct used to store all 32 bit words and their corresponding fed_ids
    """
    struct WordFedAppender
        words::Vector{UInt32}
        fed_ids::Vector{UInt8}
    end

    """
    Outer Default Constructor
    """
    WordFedAppender() = WordFedAppender(Vector{UInt32}(undef,MAX_FED_WORDS),Vector{UInt8}(undef,MAX_FED_WORDS))

    get_word(self::WordFedAppender) = return self.words

    get_fed_id(self::WordFedAppender) = return self.fed_ids
    
    """
        counter takes the values from 1 to length
        Every Consecutive 4 bytes are reinterpreted as one word UInt32
        the fed_ids array is filled with the fed_id value in the range ceiling((word_counter + 1) / 2) up to (wod_counter + length) ÷ 2
    """
    function initialize_word_fed(word_fed_appender::WordFedAppender, fed_id::Int , word_counter_gpu::UInt , src::Vector{UInt8} , length::UInt)
        for index ∈ word_counter_gpu+1:word_counter_gpu + length
            counter = index-word_counter_gpu
            start_index_byte = 4*(counter-1) + 1
            word_32::Vector{UInt8} = src[start_index_byte:start_index_byte+3]
            get_word(word_fed_appender)[index] = reinterpret(UInt32,word_32)[1]
        end
        get_fed_id(word_fed_appender)[(cld((word_counter_gpu+1),2):(word_counter_gpu + length) ÷ 2)] .= fed_id
    end


    """
    struct responsible for raw_data to cluster conversion
        stores digis_d , clusters_d, and digi_errors_d
    """
    struct SiPixelRawToClusterGPUKernel
        digis_d::SiPixelDigisSoA
        clusters_d::SiPixelClustersSoA
        digi_errors_d::SiPixelDigiErrorsSoA
    end
    
    @inline get_errors(self::SiPixelRawToClusterGPUKernel) = return self.digi_errors_d

    @inline get_results(self::SiPixelRawToClusterGPUKernel) = return Pair{SiPixelDigisSoA,SiPixelClustersSoA}(self.digis_d,self.clusters_d)

    """
    getters of the 32 bit word in payload
    """
    get_link(ww::UInt32)::UInt32 = (ww >> LINK_SHIFT) & LINK_MASK

    get_roc(ww::UInt32)::UInt32 = (ww >> ROC_SHIFT) & ROC_MASK

    get_adc(ww::UInt32)::UInt32 = (ww >> ADC_SHIFT) & ADC_MASK

    """
    Checker for whether the pixel lies on a disk or a layer
    """
    is_barrel(raw_id::UInt32)::Bool = 1 == ((raw_id >> 25) & 0x7)
    
    """
    getter for detectorID which constitutes the raw_id , roc_in_det index, and module_id 
    
    given as inputs the fed, link, and roc
    """
    function get_raw_id(cabling_map::SiPixelFedCablingMapGPU , fed::UInt8 , link::UInt32 , roc::UInt32)::DetIdGPU
        index::UInt32 = fed*MAX_LINK*MAX_ROC + (link-1) * MAX_ROC + roc 
        det_id = DetIdGPU(cabling_map.raw_id[index],cabling_map.roc_in_det[index],cabling_map.module_id[index])
    end

    function frame_conversion(bpix::Bool,side::Int,layer::UInt32,roc_id_in_det_unit::UInt32,local_pixel::Pixel)
        slope_row = slope_col = 0
        row_offset = col_offset = 0

        if bpix # if barrel pixel
            if side == -1 && layer != 1 # -Z side: 4 non flipped modules oriented like 'dddd', except Layer 1
                """
                think of 2x8 array of ROCs as 2 strips each of 1x8.
                The mapping here happens as follows: The first strip is rotated 180 degrees horizontally. While the second strip is rotated 180 degrees
                vertically in place. 
                """
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
                """
                Here the first strip is being rotated vertically by 180 degrees and is taking the place of the second strip. While the second strip is
                taking the place of the first strip and being rotated horizontally by 180 degrees
                """
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
                """
                think of 2x8 array of ROCs as 2 strips each of 1x8.
                The mapping here happens as follows: The first strip is rotated 180 degrees horizontally. While the second strip is rotated 180 degrees
                vertically in place. 
                """
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
                """
                Here the first strip is being rotated vertically by 180 degrees and is taking the place of the second strip. While the second strip is
                taking the place of the first strip and being rotated horizontally by 180 degrees
                """
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
    """
    Checkers that check the range of the local row and column of a pixel
    """
    roc_row_col_is_valid(roc_row, roc_col)::Bool = (roc_row < NUM_ROWS_IN_ROC) & (roc_col < NUM_COL_IN_ROC)
    dcol_is_valid(dcol::UInt32,px_id::UInt32) = (dcol < 26) & (2 <= pxid) & (pxid < 162)

    function check_roc(error_word::UInt32, fed_id::UInt8, link::UInt32, cabling_map::SiPixelFedCablingMapGPU, debug::Bool = false)::UInt8

        error_type::UInt8 = (error_word >> ROC_SHIFT) & ERROR_MASK
        
        if error_type < 25 
            return 0 
        end

        error_found = false

        if(error_type == 25)
            error_found = true
            index::UInt32 = fed_id * MAX_LINK * MAX_ROC + (link - 1) * MAX_ROC + 1

            if(index > 1 && index <= cabling_map.size)
                if(!(link == cabling_map.link[index] && 1 == cabling_map.roc[index]))
                    error_found = false 
                end
            end
            if debug && error_found
                printf("Invalid ROC = 25 found (error_type = 25) \n")
            end
        elseif error_found == 26
            if debug
                printf("Gap word found (error_type = 26) \n")
            end
            error_found = true 
        elseif error_found == 27
            if debug
                printf("Dummy word found (error_type = 27) \n")
            end
            error_found = true 
        elseif error_found == 28
            if debug
                prinf("Error fifo nearly full (error_type = 28) \n")
            end
            error_found = true 
        elseif error_found == 29
            if debug
                printf("Timeout on a channel (error_type = 29) \n")
            end
            if ((error_word >> OMIT_ERR_shift) & OMIT_ERR_MASK)
                if debug 
                    printf("...first error_type=29 error, this gets masked out \n")
                end
                error_found = true
            end
        elseif error_found == 30
            if debug
                printf("TBM error trailer (error_type 30) \n")
            end
            state_match_bits = 4  # Length is 4
            state_match_shift = 8 # Starts at the 9th bit of the 32 bit word
            state_match_mask = ~(~UInt32(0) << state_match_bits)
            state_match = (error_word >> state_match_shift) & state_match_mask
            
            if state_match != 1 && state_match != 8
                if debug
                    printf("FED error 30 with unexpected state bits (error_type = 30) \n")
                end
            end
            if state_match == 1
                error_type = 40 # 1 = overflow , 8 = number of ROCs -> 30
            end
            error_found = true ; 
        elseif error_found == 31
            if debug 
                printf("Event number error (error_type = 31)\n")
            end
            error_found = true
        else
            error_found = false
        end
        return error_found ? error_type : 0 
    end



    function get_err_raw_id(fed_id::UInt8 , err_word::UInt32 , error_type :: UInt32 , cabling_map :: SiPixelFedCablingMapGPU, debug::Bool = false)
        r_id :: UInt32 = 0xffffffff
        roc::UInt32 = 1
        link::UInt32 = 1
        r_id_temp::UInt32
        if(error_type == 40)
            # set dummy values for cabling just to get det_id from link
            # cabling.dcol = 0 
            # cabling.px_id = 2
            roc = 1
            link = (err_word >> LINK_SHIFT) & LINK_MASK
            r_id_temp = get_raw_id(cabling_map,fed_id,link,roc).raw_id
            if(r_id_temp != 9999)
                r_id = r_id_temp
            end
        elseif error_type == 29
            chan_nmbr = 0 
            db0_shift = 0 
            db1_shift = db0_shift + 1
            db2_shift = db1_shift + 1 
            db3_shift = db2_shift + 1 
            db4_shift = db3_shift + 1 
            data_bit_mask::UInt32 = ~(~UInt32(0) << 1)
            ch1 = (err_word >> db0_shift) & data_bit_mask
            ch2 = (err_word >> db1_shift) & data_bit_mask
            ch3 = (err_word >> db2_shift) & data_bit_mask
            ch4 = (err_word >> db3_shift) & data_bit_mask
            ch5 = (err_word >> db4_shift) & data_bit_mask
            block_bits = 3 # length of block is 3 bits
            block_shift = 8 # start bit is the 9th bit
            block_mask::UInt32 = ~(~UInt32(0) << block_bits)
            block = (err_word >> block_shift) & block_mask
            local_ch = 1*ch1 + 2*ch2 + 3*ch3 + 4*ch4 + 5*ch5
            if(block % 2 == 0 )
                chan_nmbr = (block ÷ 2) * 9 + local_ch
            else
                chan_nmbr = ((block - 1) ÷ 2) * 9 + 4 + local_ch
            end

            if !(chan_nmbr < 1 || chan_nmr > 36) # if it were to be the case it would signify an unexpected result
                # set dummy values for cabling just to get det_id from link if in barrel
                # cabling.dcol = 0
                # cabling.px_id = 2
                roc = 1
                link = chan_nmbr
                r_id_temp = get_raw_id(cabling_map,fed_id,link,roc).raw_id
                
                if(r_id_temp != 9999)
                    r_id = r_id_temp
                end
            end
        elseif error_type == 38
            #cabling.dcol = 0
            #cabling.px_id = 2
            roc = (err_word >> ROC_SHIFT) & ROC_MASK
            link = (err_word >> LINK_SHIFT) * LINK_MASK
            r_id_temp = get_raw_id(cabling_map,fed_id,link,roc).raw_id
            if(r_id_temp != 9999)
                r_id = r_id_temp
            end
        end
        return r_id
    end


    function raw_to_digi_kernal(cabling_map::SiPixelFedCablingMapGPU , mod_to_unp :: Vector{UInt8} , word_counter::UInt32 , 
                                word::Vector{UInt32} , fed_ids::Vector{UInt8} , xx::Vector{UInt16} , yy::Vector{UInt16} ,
                                adc::Vector{UInt16} , p_digi::Vector{UInt32} , raw_id_arr::Vector{UInt32} , module_id::Vector{UInt16},
                                err::Vector{PixelErrorCompact} , use_quality_info::Bool , include_errors::Bool , debug::Bool)
        first::UInt32 = 1
        n_end = word_counter
        
        for i_loop ∈ first:n_end
            g_index = i_loop
            xx[g_index] = 0 
            yy[g_index] = 0 
            adc[g_index] = 0
            skip_roc::Bool = false
            fed_id::UInt8 = fed_ids[cld(g_index,2)] # make sure to add +1200
            
            # initialize (too many continue below)
            pdigi[g_index] = 0 
            row_id_arr[g_index] = 0 
            module_id[g_index] = 9999

            ww::UInt32 = word[g_index]

            if ww == 0 # indication of noise or dead channel, skip this pixel during clusterization
                continue 
            end

            link::UInt32 = get_link(ww)
            roc::UInt32 = get_roc(ww)

            det_id::DetIdGPU = get_raw_id(cabling_map,fed_id,link,roc)

            error_type::UInt8 = check_roc(ww,fed_id,link,cabling_map,debug)

            skip_roc = (roc < MAX_ROC_INDEX) ? false : ( error_type != 0 )

            if include_errors && skip_roc
                r_id::UInt32 = get_err_raw_id(fed_id,ww,error_type,cabling_map,debug)
                push!(err,PixelErrorCompact(r_id,ww,error_type,fed_id))
                continue 
            end

            raw_id::UInt32 = det_id.raw_id
            roc_in_det_unit = det_id.roc_in_det
            barrel = is_barrel(raw_id)

            index::UInt32 = fed_id * MAX_LINK * MAX_ROC + (link - 1) * MAX_ROC + roc

            if(use_quality_info)
                skip_roc = cabling_map.bad_rocs[index]
                if skip_roc
                    continue 
                end
            end
            skip_roc = mod_to_unp[index]

            if(skip_roc)
                continue
            end

            layer::UInt32 = barrel ? ((raw_id >> LAYER_START_BIT) & LAYER_MASK) : 0 
            the_module::UInt32 = barrel ? ((raw_id >> MODULE_START_BIT) & MODULE_MASK) : 0
            side = barrel ? ((the_module < 5) ? -1 : 1) : ((panel == 1) ? -1 : 1)
            panel = barrel ? 0 : (raw_id >> PANEL_START_BIT) & PANEL_MASK
            local_pixel::Pixel
            row::UInt32
            col::UInt32
            error::UInt8
            if layer == 1 
                col = (ww >> COL_SHIFT) & COL_MASK
                row = (ww >> ROW_SHIFT) & ROW_MASK
                local_pixel.row = row 
                local_pixel.col = col

                if include_errors
                    if ! roc_row_col_is_valid(row,col)
                        error = conversion_error(fed_id,3,debug) # use the device function and fill the arrays
                        push!(err,PixelErrorCompact(raw_id,ww,error,fed_id))
                        if debug
                            printf("BPIX1 Error Status: %i\n", error)
                        end
                        continue ; 
                    end
                end
            else
                # Conversion Rules for dcol and px_id
                dcol::UInt32 = (ww >> DCOL_SHIFT) & DCOL_MASK
                """
                px_id range is from 2 to 161
                """
                px_id::UInt32 = (ww >> PXID_SHIFT) & PXID_MASK
                """
                I think in order for this to be consistent. The pixel_ids are numbered from 2 to 161 from the bottom of the strip (160x2)
                """
                row = NUM_ROWS_IN_ROC - px_id ÷ 2 
                
                col = dcol * 2 + px_id % 2
                local_pixel.row = row 
                local_pixel.col = col
                if include_errors && !(dcol_is_valid(dcol,px_id))
                    error = conversion_error(fed_id,3,debug)
                    push!(err,PixelErrorCompact(raw_id,ww,error,fed_id))
                    if debug
                        printf("Error status: %i %d %d %d %d\n", error, dcol, px_id, fed_id, roc)
                    end
                    continue 
                end
            end
                global_pix::Pixel = frame_conversion(barrel,side,layer,roc_id_in_det_unit, local_pix)
                xx[g_index] = global_pix.row
                yy[g_index] = global_pix.col
                adc[g_index] = get_adc(ww)
                p_digi[g_index] = pack(global_pix.row,global_pix.col,adc[g_index])
                module_id[g_index] = det_id.module_id
                raw_id_arr[g_index] = raw_id
        end
    end


    function make_clusters(is_run_2::Bool , cabling_map::SiPixelFedCablingMapGPU , mod_to_unp::Vector{UInt8} , gains::SiPixelGainForHLTonGPU ,
                  word_fed::WordFedAppender , errors:: PixelFormatterErrors , word_counter::UInt32 , fed_counter::UInt32 , use_quality_info::Bool,
                  include_errors::Bool , debug::Bool )
        printf("decoding %s digis. Max is %i ",word_counter,MAX_FED_WORDS)
        digis_d = SiPixelDigisSoA(pixelGPUDetails.MAX_FED_WORDS)
        if include_errors
            digi_errors_d = SiPixelDigiErrorsSoA(pixelGPUDetails.MAX_FED_WORDS,errors)
        end
        clusters_d = SiPixelClustersSoA(gpuClustering.mAX_NUM_MODULES)

        if word_counter != 0 # incase of empty event
            assert(0 == word_counter % 2)
            raw_to_digi_kernal(cabling_map,mod_to_unp,word_counter,get_word(word_fed),get_fed_id(word_fed),xx(digis_d),yy(digis_d),adc(digis_d),
            p_digi(digis_d), raw_id_arr(digis_d), module_ind(digis_d), error(digi_errors_d),use_quality_info,include_errors,debug)
        end # end for raw to digi
    end

    function fill_hits_module_start(clu_start::Vector{UInt32}, module_start::Vector{UInt32})
        @assert (gpuClustering.MAX_NUM_MODULES < 2048)

        for i in 1:gpuClustering.MAX_NUM_MODULES
            module_start[i + 1] = min(gpuClustering.max_hits_in_module(), clus_start[i])
        end
        
        ws = Vector{UInt32}(undef, 32)
        cms.cuda.block_prefix_scan(module_start[2:end], 10241)
        cms.cuda.block_prefix_scan(module_start[1026:end], gpuClustering.max_hits_in_module() - 1024)

        for i in 1026:gpuClustering.MAX_NUM_MODULES + 1
            module_start[i] += module_start[1025]
        end
    end



end