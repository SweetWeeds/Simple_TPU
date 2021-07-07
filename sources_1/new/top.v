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
    input [INST_BITS-1:0] instruction,
    input [DIN_BITS-1:0] din,
    output [DIN_BITS-1:0] dout
);

`include "sa_share.v"

// Control signals
wire READ_UB_SIG, WRITE_UB_SIG, READ_WB_SIG, WRITE_WB_SIG, READ_ACC_SIG,
    WRITE_ACC_SIG, DATA_FIFO_EN_SIG, MMU_LOAD_WEIGHT_SIG, WEIGHT_FIFO_EN_SIG, MM_EN_SIG, ACC_EN_SIG;
// Datapaths
wire [127:0] DATA_FIFO_MMU_PATH, WEIGHT_FIFO_MMU_PATH,
            UB_DATA_PATH, WB_WEIGHT_FIFO_PATH, CTRL_DOUT, RESLUT_DOUT;
wire [319:0] MMU_ACC_PATH;
wire [7:0] ADDRA, ADDRB;
wire flag;

assign dout = UB_DATA_PATH;

// Controller
CONTROL_UNIT CU (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .din(din),
    .rin(RESLUT_DOUT),
    .flag(flag),
    .read_ub(READ_UB_SIG),
    .write_ub(WRITE_UB_SIG),
    .read_wb(READ_WB_SIG),
    .write_wb(WRITE_WB_SIG),
    .read_acc(READ_ACC_SIG),
    .write_acc(WRITE_ACC_SIG),
    .data_fifo_en(DATA_FIFO_EN_SIG),
    .mmu_load_weight_en(MMU_LOAD_WEIGHT_SIG),
    .weight_fifo_en(WEIGHT_FIFO_EN_SIG),
    .mm_en(MM_EN_SIG),
    .acc_en(ACC_EN_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dout(CTRL_DOUT)
);

// Weight-FIFO
FIFO_4x16x8b WEIGHT_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(WEIGHT_FIFO_EN_SIG),
    .din(WB_WEIGHT_FIFO_PATH),
    .dout(WEIGHT_FIFO_MMU_PATH)
);

// Unified Buffer
BRAM_256x16x8b UB (
    .clk(clk),
    .wea(WRITE_UB_SIG),
    .enb(READ_UB_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(UB_DATA_PATH)
);

// Weight Buffer
BRAM_256x16x8b WB (
    .clk(clk),
    .wea(WRITE_WB_SIG),
    .enb(READ_WB_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(WB_WEIGHT_FIFO_PATH)
);

// Data-FIFO
FIFO_4x16x8b DATA_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(DATA_FIFO_EN_SIG),
    .din(UB_DATA_PATH),
    .dout(DATA_FIFO_MMU_PATH)
);

// Matrix-Multiplication Unit
MATRIX_MULTIPLY_UNIT MMU (
    .reset_n(reset_n),
    .clk(clk),
    .wen(MMU_LOAD_WEIGHT_SIG),
    .mm_en(MM_EN_SIG),
    .ain(DATA_FIFO_MMU_PATH),
    .win(WEIGHT_FIFO_MMU_PATH),
    .aout(MMU_ACC_PATH)
);

// Accumulator
//FIFO_16x16x20b ACC (
//    .reset_n(reset_n),
//    .clk(clk),
//    .en(ACC_SIG),
//    .din(MMU_ACC_PATH),
//    .dout(dout)
//);

ACCUMULATOR ACC (
    .clk(clk),
    .wea(WRITE_ACC_SIG),
    .enb(READ_ACC_SIG),
    .acc_en(ACC_EN_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(MMU_ACC_PATH),
    .doutb(RESLUT_DOUT)
);

endmodule
