// Instruction Set
localparam OPCODE_BITS  = 4,
           ADDR_BITS    = 8,
           OPERAND_BITS = 128,
           INST_BITS    = OPCODE_BITS + OPERAND_BITS + ADDR_BITS;

// Parsing range
localparam OPCODE_FROM  = INST_BITS-1,  // 140-1=139
           OPCODE_TO    = OPCODE_FROM-OPCODE_BITS+1,  // 139-4+1=136
           ADDR_FROM    = OPCODE_TO-1,  // 136-1=135
           ADDR_TO      = ADDR_FROM-ADDR_BITS+1, // 135-8+1=128
           OPERAND_FROM = ADDR_TO-1,    // 128-1=127
           OPERAND_TO   = OPERAND_FROM-OPERAND_BITS+1;  // 127-128+1=0

// State params
localparam [OPCODE_BITS-1:0]    IDLE_INST               = 4'h0,
                                LOAD_DATA_INST          = 4'h1,
                                LOAD_WEIGHT_INST        = 4'h2,
                                MAT_MUL_INST            = 4'h3,
                                MM_AND_LOAD_DATA_INST   = 4'h4,
                                WRITE_DATA_INST         = 4'h5,
                                WRITE_WEIGHT_INST       = 4'h6,
                                WRITE_RESULT_INST       = 4'h7,
                                ACCUMULATION_INST       = 4'h8;

// M1_MAT_MUL_STATE's minor mode (M2)
localparam MODE_BITS = 4;