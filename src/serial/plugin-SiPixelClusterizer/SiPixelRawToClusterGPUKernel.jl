struct SiPixelFedCablingMapGPU
end
struct SiPixelGainForHLTonGPU
end
"""
Phase 1 Geometry Constants
"""
module pixelgpudetails
    const layerStartBit::UInt32 = 20 # 4 layers
    const ladderStartBit::UInt32 = 12 # 148 ladders
    const moduleStartBit::UInt32 = 2 # 1856 silicon modules each with 160 x 416 pixels connected to 16 ReadOut Chips (ROC)

    const panelStartBit::UInt32 = 10 # Group of ladders
    const diskStartBit::UInt32 = 18  
    const bladeStartBit::UInt32 = 12 # For FPIX, One half disk has 28 Blades (11 inner) and (17 outer). One module mounts each side of a blade

    const layerMask::UInt32 = 0xF # 4 bits
    const ladderMask::UInt32 = 0xFF # 8 bits
    const moduleMask::UInt32 = 0x3FF # 11 bits
    const panelMask::UInt32 = 0x3 # 3 bits
    const diskMask::UInt32 = 0xF # 4 bits
    const bladeMask::UInt32 = 0x3F # 7 bits


    const LINK_bits::UInt32 = 6 
    const ROC_bits::UInt32 = 5  
    const DCOL_bits::UInt32 = 5 
    const PXID_bits::UInt32 = 8
    const ADC_bits::UInt32 = 8

    """
    [  6 bits  | 5 bits | 5 bits |  8 bits  |8 bits  ]
    [  Link    |  ROC   |  DCOL  |  PXID    |  ADC   ]
    Special For Layer 1
    """
    const LINK_bits_l1::UInt32 = 6
    const ROC_bits_l1::UInt32 = 5
    const COL_bits_l1::UInt32 = 6
    const ROW_bits_l1::UInt32 = 7
    const OMIT_ERR_bits::UInt32 = 1 
    """
    Each ROC is an 80x52 pixel unit cell 
    They are grouping columns by 2 : 26 DCOL
    """
    const maxROCIndex::UInt32 = 8 
    const numRowsInRoc::UInt32 = 80 
    const numColsInRoc::UInt32 = 52 

    const MAX_WORD::UInt32 = 2000 # maxword in what ?

    const ADC_shift::UInt32 = 0
    const PXID_shift::UInt32 = ADC_shift + ADC_bits
    const DCOL_shift::UInt32 = PXID_shift + PXID_bits
    const ROC_shift::UInt32 = DCOL_shift + DCOL_bits
    const LINK_shift::UInt32 = ROC_shift + ROC_bits
    """
    Special For Layer 1 ROC
    """
    const ROW_shift::UInt32 = ADC_shift + ADC_bits
    const COL_shift::UInt32 = ROW_shift + ROW_bits_l1
    const OMIT_ERR_shift::UInt32 = 20 # ?

    const LINK_mask::UInt32 = ~(~UInt32(0) << LINK_bits_l1)
    const ROC_mask::UInt32 = ~(~UInt32(0) << ROC_bits_l1)
    const COL_mask::UInt32 = ~(~UInt32(0) << COL_bits_l1)
    const ROW_mask::UInt32 = ~(~UInt32(0) << ROW_bits_l1)
    const DCOL_mask::UInt32 = ~(~UInt32(0) << DCOL_bits) # ?
    const PXID_mask::UInt32 = ~(~UInt32(0) << PXID_bits) # ?
    const ADC_mask::UInt32 = ~(~UInt32(0) << ADC_bits)
    const ERROR_mask::UInt32 = ~(~UInt32(0) << ROC_bits_l1) # ?
    const OMIT_ERR_mask::UInt32 = ~(~UInt32(0) << OMIT_ERR_bits) # ?

    struct DetIdGPU
        RawId::UInt32
        rocInDet::UInt32
        moduleId::UInt32
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
        thePacking::Packing = Packing()
        adc = min(adc,thePacking.max_adc)
        return (row << thePacking.row_shift) | (col << thePacking.column_shift) | (adc << thePacking.adc_shift);
    end

    function pixelToChannel(row::UInt32,col::UInt32)::UInt32
        thePacking::Packing = Packing()
        return (row << thePacking.column_width) | col
    end

    struct WordFedAppender
        _word::Vector{UInt32}
        _fedId::Vector{UInt8}
    end

    getWord(self::WordFedAppender) = return self._word

    getFedId(self::WordFedAppender) = return self._fedId
    
    initializeWordFed
    

    struct SiPixelRawToClusterGPUKernel

    end

end