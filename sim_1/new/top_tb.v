`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 14:28:26
// Design Name: Matrix-Multiply Unit Test Bench
// Module Name: mmu_tb
// Proiect Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Testbench for MMU module.
// 
// Dependencies: matrix_multiply_unit.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module TOP_test;

// Clock localparams
localparam  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS / 1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;

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

// regs & wires
reg reset_n = 1'b1, clk, wen = 1'b1;
wire [INST_BITS-1:0] instruction;
wire [319:0] dout;
reg [OPCODE_BITS-1:0] OPCODE;
reg [ADDR_BITS-1:0] ADDR;
reg [OPERAND_BITS-1:0] OPERAND;

assign instruction[OPCODE_FROM:OPCODE_TO]   = OPCODE;
assign instruction[ADDR_FROM:ADDR_TO]       = ADDR;
assign instruction[OPERAND_FROM:OPERAND_TO] = OPERAND;

// Instantiation
SYSTOLIC_ARRAY SA0 (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .dout(dout)
);

/**
 *  Clock signal generation.
 *  Clock is assumed to be initialized to 1'b0 at time 0.
 */
initial begin : CLOCK_GENERATOR
    clk = 1'b0;
    forever
        # half_clock_period clk = ~clk;
end

initial begin: TEST_BENCH
    // Initialization with 'reset_n'
    # minimum_period;
    reset_n = 1'b0;
    # minimum_period;
    reset_n = 1'b1;

    // 1. Write data to UB
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = WRITE_DATA_INST;
        ADDR = i;
        for (integer j = 15; j >= 0; j = j - 1) begin
            OPERAND[j * 8 + : 8] = i - j;
        end
        # clock_period;
    end

    // 2. Write weight to WB
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = WRITE_WEIGHT_INST;
        ADDR = i;
        for (integer j = 15; j >= 0; j = j - 1) begin
            OPERAND[j * 8 + : 8] = - i + j;
        end
        # clock_period;
    end
    
    // 3. IDLE
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = IDLE_INST;
        # clock_period;
    end

    // 4. Load Data
    for (integer i = 0; i < 4; i = i + 1) begin
        OPCODE = LOAD_DATA_INST;
        ADDR = i;
        # clock_period;
    end

    // 5. Load Weight
    for (integer i = 0; i < 4; i = i + 1) begin
        OPCODE = LOAD_WEIGHT_INST;
        ADDR = i;
        # clock_period;
    end

    // 6. Matrix Multiplication
    for (integer i = 0; i < 4; i = i + 1) begin
        OPCODE = LOAD_WEIGHT_INST;
        ADDR = i;
        # clock_period;
    end

    // 7. Matrix Multiplication and load data


end

endmodule
// End of MMU_test //
