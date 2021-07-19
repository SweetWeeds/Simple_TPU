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

module CU_test;

`include "tb_share.v"

// Clock localparams
localparam  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS / 1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;

// regs & wires
reg reset_n = 1'b1, clk, wen = 1'b1;
wire [INST_BITS-1:0] instruction;
wire [319:0] dout;
reg [OPCODE_BITS-1:0] OPCODE;
reg [ADDRA_BITS-1:0] ADDRA, ADDRB;
reg [DIN_BITS-1:0] INPUT_DATA;

assign instruction[OPCODE_FROM:OPCODE_TO]   = OPCODE;
assign instruction[ADDRA_FROM:ADDRA_TO]     = ADDRA;
assign instruction[ADDRB_FROM:ADDRB_TO]     = ADDRB;
//assign instruction[OPERAND_FROM:OPERAND_TO] = OPERAND;

// Instantiation
CONTROL_UNIT CU0 (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .flag(flag),
    .read_ub(),
    .write_ub(),
    .read_wb(),
    .write_wb(),
    .read_acc(),
    .write_acc(),
    .data_fifo_en(),
    .weight_fifo_en(weight_fifo_en),
    .mm_en(mm_en),
    .acc_en(acc_en),
    .addra(addra),
    .addrb(addrb),
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
    // Initialization with 'reset_n' (0 ~ 10000 ns)
    # half_clock_period;
    reset_n = 1'b0;
    # half_clock_period;
    reset_n = 1'b1;

    // 1. Write data to UB (10000 * 256 ns = 2560000 ns)
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = AXI_TO_UB_INST;
        ADDRA = i;
        for (integer j = 15; j >= 0; j = j - 1) begin
            OPERAND[j * 8 + : 8] = i - j;
        end
        # (IDLE_CYCLE * clock_period);
    end

    // 2. Write weight to WB (2560000 + 10000 * 256 ns = 5120000 ns)
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = AXI_TO_WB_INST;
        ADDRA = i;
        for (integer j = 15; j >= 0; j = j - 1) begin
            OPERAND[j * 8 + : 8] = - i + j;
        end
        # (AXI_TO_WB_CYCLE * clock_period);
    end
    
    // 3. IDLE
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = IDLE_INST;
        # (IDLE_CYCLE * clock_period);
    end

    // 4. Load Data
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = UB_TO_DATA_FIFO_INST;
        ADDRB = i;
        # (UB_TO_DATA_FIFO_CYCLE * clock_period);
    end

    // 5. Load Weight
    for (integer i = 0; i < 21; i = i + 1) begin
        OPCODE = UB_TO_WEIGHT_FIFO_INST;
        ADDRB = i;
        # (UB_TO_WEIGHT_FIFO_CYCLE * clock_period);
    end

    // 6. Matrix Multiplication
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = MAT_MUL_INST;
        ADDRA = i;
        # (MAT_MUL_CYCLE * clock_period);

        OPCODE = UB_TO_DATA_FIFO_INST;
        ADDRB = i;
        # (UB_TO_DATA_FIFO_CYCLE * clock_period);
    end

    // 7. Matrix Multiplication with accumulation.
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = MAT_MUL_ACC_INST;
        ADDRA = i;
        # (MAT_MUL_CYCLE * clock_period);

        OPCODE = UB_TO_DATA_FIFO_INST;
        ADDRB = i;
        # (UB_TO_DATA_FIFO_CYCLE * clock_period);
    end

end

endmodule
// End of MMU_test //
