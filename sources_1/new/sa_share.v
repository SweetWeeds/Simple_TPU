/** Functions **/
function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

// Instruction Set
// ISA(140-bit) = OPCODE_BITS(4-bit) + ADDRA_BITS(8-bit) + ADDRB_BITS(8-bit) + OPERAND_BITS(128-bit)
localparam OPCODE_BITS  = 4,
           ADDRA_BITS   = 8,
           ADDRB_BITS   = 8,
           //OPERAND_BITS = 128,
           INST_BITS    = OPCODE_BITS + ADDRA_BITS + ADDRB_BITS,   // 20-bit
           DIN_BITS     = 128;

// Parsing range
localparam OPCODE_FROM  = INST_BITS-1,                  // 148-1=147
           OPCODE_TO    = OPCODE_FROM-OPCODE_BITS+1,    // 147-4+1=144
           ADDRA_FROM   = OPCODE_TO-1,                  // 144-1=143
           ADDRA_TO     = ADDRA_FROM-ADDRA_BITS+1,      // 143-8+1=136
           ADDRB_FROM   = ADDRA_TO-1,                   // 136-1=135
           ADDRB_TO     = ADDRB_FROM-ADDRB_BITS+1;      // 135-8+1=128

// OPCODE
localparam [OPCODE_BITS-1:0]    // Do nothing (1-cycyle)
                                IDLE_INST               = 4'h0,
                                // Data-FIFO Enable (1-cycle)
                                DATA_FIFO_INST          = 4'h1,
                                // Weight-FIFO Enable (1-cycle)
                                WEIGHT_FIFO_INST        = 4'h2,
                                // Write data into UB (1-cycle)
                                AXI_TO_UB_INST          = 4'h3,
                                // Write weight into WB (1-cycle)
                                AXI_TO_WB_INST          = 4'h4,
                                // Load data from UB to data-FIFO (1-cycle)
                                UB_TO_DATA_FIFO_INST    = 4'h5,
                                // Load Weight from WB to weight-FIFO (1-cycle)
                                UB_TO_WEIGHT_FIFO_INST  = 4'h6,
                                // Execute Matrix Multiplication (1-cycle)
                                MAT_MUL_INST            = 4'h7,
                                // Execute Matrix Multiplication with accumulation (1-cycle)
                                MAT_MUL_ACC_INST        = 4'h8,
                                // Write result data from ACC to UB (1-cycle)
                                ACC_TO_UB_INST          = 4'h9,
                                // Write unsigned-Buffer's data to AXI (n-cycles)
                                UB_TO_AXI_INST          = 4'ha;



// Minor states' num of cycles ('0' means n-cycles)
localparam [1:0]    IDLE_CYCLE              = 1,
                    DATA_FIFO_CYCLE         = 1,
                    WEIGHT_FIFO_CYCLE       = 1,
                    AXI_TO_UB_CYCLE         = 0,
                    AXI_TO_WB_CYCLE         = 0,
                    UB_TO_DATA_FIFO_CYCLE   = 1,
                    UB_TO_WEIGHT_FIFO_CYCLE = 1,
                    MAT_MUL_CYCLE           = 1,
                    MAT_MUL_ACC_CYCLE       = 1,
                    ACC_TO_UB_CYCLE         = 2,
                    UB_TO_AXI_INST_CYCLE    = 0;

// M1_MAT_MUL_STATE's minor mode (M2)
localparam MODE1_NUM = 7;
localparam MODE2_NUM = 4;

localparam  ADDR_READ  = 0,
            ADDR_WRITE = 1;