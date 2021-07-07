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
           OPERAND_BITS = 128,
           INST_BITS    = OPCODE_BITS + ADDRA_BITS + ADDRB_BITS + OPERAND_BITS;   // 148-bit

// Parsing range
localparam OPCODE_FROM  = INST_BITS-1,                  // 148-1=147
           OPCODE_TO    = OPCODE_FROM-OPCODE_BITS+1,    // 147-4+1=144
           ADDRA_FROM   = OPCODE_TO-1,                  // 144-1=143
           ADDRA_TO     = ADDRA_FROM-ADDRA_BITS+1,      // 143-8+1=136
           ADDRB_FROM   = ADDRA_TO-1,                   // 136-1=135
           ADDRB_TO     = ADDRB_FROM-ADDRB_BITS+1,      // 135-8+1=128
           OPERAND_FROM = ADDRB_TO-1,                    // 128-1=127
           OPERAND_TO   = OPERAND_FROM-OPERAND_BITS+1;  // 127-128+1=0

// OPCODE
localparam [OPCODE_BITS-1:0]    // Do nothing (1-cycyle)
                                IDLE_INST               = 4'h0,
                                // Data-FIFO Enable (1-cycle)
                                DATA_FIFO_INST          = 4'h1,
                                // Weight-FIFO Enable (1-cycle)
                                WEIGHT_FIFO_INST        = 4'h2,
                                // Write result data from ACC to UB (1-cycle)
                                // ADDR: 
                                WRITE_DATA_INST         = 4'h3,
                                // Write data into UB (1-cycle)
                                WRITE_WEIGHT_INST       = 4'h4,
                                // Write weight into WB (1-cycle)
                                /*WRITE_RESULT_INST       = 4'h2,*/
                                // Load data from UB to data-FIFO (2-cycle)
                                // ADDR: Address of data in UB.
                                // OPERAND_BITS: X
                                LOAD_DATA_INST          = 4'h5,
                                // Load Weight from WB to weight-FIFO (2-cycle)
                                // ADDR: Address of data in WB.
                                // OPERAND_BITS: X
                                LOAD_WEIGHT_INST        = 4'h6,
                                // Execute Matrix Multiplication (2-cycle)
                                // ADDR: Address to store the result.
                                // OPERAND_BITS: X
                                MAT_MUL_INST            = 4'h7,
                                // Execute Matrix Multiplication with accumulation (2-cycle)
                                MAT_MUL_ACC_INST        = 4'h8;
                                


// Minor states
localparam [1:0]    IDLE_CYCLE          = 1,
                    DATA_FIFO_CYCLE     = 1,
                    WEIGHT_FIFO_CYCLE   = 1,
                    WRITE_DATA_CYCLE    = 1,
                    WRITE_WEIGHT_CYCLE  = 1,
                    WRITE_RESULT_CYCLE  = 2,
                    LOAD_DATA_CYCLE     = 1,
                    LOAD_WEIGHT_CYCLE   = 1,
                    MAT_MUL_CYCLE       = 1,
                    MAT_MUL_ACC_CYCLE   = 1;

// M1_MAT_MUL_STATE's minor mode (M2)
localparam MODE1_NUM = 7;
localparam MODE2_NUM = 4;

localparam  ADDR_READ  = 0,
            ADDR_WRITE = 1;