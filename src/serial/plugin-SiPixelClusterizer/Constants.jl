module constants

    # Exported variables so that they are accessible from outside the module
    export CRC_bits, LINK_bits, ROC_bits, DCOL_bits, PXID_bits, ADC_bits, OMIT_ERR_bits
    export CRC_shift, ADC_shift, PXID_shift, DCOL_shift, ROC_shift, LINK_shift, OMIT_ERR_shift
    export dummyDetId, CRC_mask, ERROR_mask, LINK_mask, ROC_mask, OMIT_ERR_mask

    """
    Number of bits used for:
     CRC
     LINK
     ROC
     DCOL
     PXID
     ADC
     OMIT_ERR
    Type: Int
    """
    CRC_bits = 1
    LINK_bits = 6
    ROC_bits = 5
    DCOL_bits = 5
    PXID_bits = 8
    ADC_bits = 8
    OMIT_ERR_bits = 1

    """
    Bit shift for:
   CRC
     LINK
     ROC
     DCOL
     PXID
     ADC
     OMIT_ERR
    Type: Int
    """
    CRC_shift = 2
    ADC_shift = 0
    PXID_shift = ADC_shift + ADC_bits
    DCOL_shift = PXID_shift + PXID_bits
    ROC_shift = DCOL_shift + DCOL_bits
    LINK_shift = ROC_shift + ROC_bits
    OMIT_ERR_shift = 20

    """
    Dummy detector ID
    Type: UInt32
    """
    dummyDetId = 0xffffffff

    """
    Bit mask for:
     CRC
     ERROR
     LINK
     ROC
     OMIT_ERR
     
    Type: UInt32 or UInt64
    """
    CRC_mask = ~(~UInt64(0) << CRC_bits)
    ERROR_mask = ~(~UInt32(0) << ROC_bits)
    LINK_mask = ~(~UInt32(0) << LINK_bits)
    ROC_mask = ~(~UInt32(0) << ROC_bits)
    OMIT_ERR_mask = ~(~UInt32(0) << OMIT_ERR_bits)

end
