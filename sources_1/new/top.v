`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/29 16:50:04
// Design Name: Systolic Array
// Module Name: SYSTOLIC_ARRAY
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Top module of systolic array.
// 
// Dependencies: matrix_multiply_unit.v, fifo_16x16x20b.v, fifo_256x16x8b.v,
//               unified_buffer.v, weight_buffer.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SYSTOLIC_ARRAY (
    input reset_n,
    input clk,
    input [31:0] instruction
);

// Control signals
wire LOAD_DATA_SIG, LOAD_WEIGHT_SIG, WRITE_DATA_SIG, WRITE_WEIGHT_SIG,
     WRITE_RESULT_SIG, MAT_MUL_SIG;
// Datapaths
wire [127:0] DATA_FIFO_MMU_PATH, WEIGHT_FIFO_MMU_PATH,
            UB_DATA_FIFO_PATH, WB_WEIGHT_FIFO_PATH, CTRL_DOUT;
wire [319:0] MMU_ACC_PATH;
wire [7:0] ADDRA, ADDRB;

// Controller
/*
CONTROLLER CTRL (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .load_data(LOAD_DATA_SIG),
    .load_weight(LOAD_WEIGHT_SIG),
    .write_data(WRITE_DATA_SIG),
    .write_weight(WRITE_WEIGHT_SIG),
    .write_result(WRITE_RESULT_SIG),
    .mat_mul(MAT_MUL_SIG),
    .addra(ADDRA),
    .addrb(ADDRB)
    .dout(CTRL_DOUT)
);
*/

// Weight-FIFO
FIFO_256x16x8b WEIGHT_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(LOAD_WEIGHT_SIG),
    .din(WB_WEIGHT_FIFO_PATH),
    .dout(WEIGHT_FIFO_MMU_PATH)
);

// Unified Buffer
BRAM_256x16x8b UB (
    .clk(clk),
    .wea(WRITE_DATA_SIG),
    .enb(READ_EN),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(UB_DATA_FIFO_PATH)
);

// Weight Buffer
BRAM_256x16x8b WB (
    .clk(clk),
    .wea(WRITE_WEIGHT_SIG),
    .enb(READ_EN),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(WB_WEIGHT_FIFO_PATH)
);

// Data-FIFO
FIFO_256x16x8b DATA_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(READ_EN),
    .din(UB_DATA_FIFO_PATH),
    .dout(DATA_FIFO_MMU_PATH)
);

// Accumulator
FIFO_16x16x20b ACC (
    .reset_n(reset_n),
    .clk(clk),
    .en(MAT_MUL_SIG),
    .din(MMU_ACC_PATH),
    .dout()
);

// Matrix-Multiplication Unit
MATRIX_MULTIPLY_UNIT MMU (
    .reset_n(reset_n),
    .clk(clk),
    .wen(LOAD_WEIGHT_SIG),
    .ain(DATA_FIFO_MMU_PATH),
    .win(WEIGHT_FIFO_MMU_PATH),
    .aout(MMU_ACC_PATH)
);

endmodule
