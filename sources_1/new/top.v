`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/29 16:50:04
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module TOP(
    input reset_n,
    input clk
);

// Control signals
wire LOAD_WEIGHT, MAT_MUL, WRITE_EN, READ_EN, OUT_EN;
// Datapaths
wire [127:0] DATA_FIFO_MMU_PATH, WEIGHT_FIFO_MMU_PATH, UB_DATA_FIFO_PATH;
wire [319:0] MMU_ACC_PATH;

// Weight-FIFO
FIFO_256x16x8b WEIGHT_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(LOAD_WEIGHT),
    .din(),
    .dout(WEIGHT_FIFO_MMU_PATH)
);

// Unified Buffer
UNIFIED_BUFFER UB (
    .clk(clk),
    .wea(),
    .enb(READ_EN),
    .addra(),
    .addrb(),
    .dina(),
    .doutb(UB_DATA_FIFO_PATH),
    .rstb(),
    .regceb()
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
    .en(WRITE_EN),
    .din(MMU_ACC_PATH),
    .dout()
);

// Matrix-Multiplication Unit
MMU MMU0 (
    .reset_n(reset_n),
    .clk(clk),
    .wen(LOAD_WEIGHT),
    .ain(DATA_FIFO_MMU_PATH),
    .win(WEIGHT_FIFO_MMU_PATH),
    .aout(MMU_ACC_PATH)
);

endmodule
