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

module SYSTOLIC_ARRAY # 
(
    parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
	parameter integer C_M00_AXI_DATA_WIDTH	= 32,
	parameter integer C_M00_AXI_TRANSACTIONS_NUM	= 4
)
(
    input  wire reset_n,
    input  wire clk,
    input  wire [INST_BITS-1:0] instruction,
    output wire flag,
    // AXI4 Lite Master Signals
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
	output wire [2 : 0] m00_axi_awprot,
	output wire  m00_axi_awvalid,
	input  wire  m00_axi_awready,
	output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
	output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
    output wire  m00_axi_wvalid,
	input  wire  m00_axi_wready,
	input  wire [1 : 0] m00_axi_bresp,
	input  wire  m00_axi_bvalid,
    output wire  m00_axi_bready,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
	output wire [2 : 0] m00_axi_arprot,
	output wire  m00_axi_arvalid,
	input  wire  m00_axi_arready,
	input  wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
	input  wire [1 : 0] m00_axi_rresp,
	input  wire  m00_axi_rvalid,
	output wire  m00_axi_rready
    // End of AXI4 Lite Master Signals
);

`include "sa_share.v"

// Control signals
wire READ_UB_SIG, WRITE_UB_SIG, READ_WB_SIG, WRITE_WB_SIG, READ_ACC_SIG,
    WRITE_ACC_SIG, DATA_FIFO_EN_SIG, MMU_UB_TO_WEIGHT_FIFO_SIG, WEIGHT_FIFO_EN_SIG,
    MM_EN_SIG, ACC_EN_SIG, INST_DONE;
// Datapaths
wire [127:0] DATA_FIFO_MMU_PATH, WEIGHT_FIFO_MMU_PATH,
            UB_DATA_PATH, WB_WEIGHT_FIFO_PATH, CTRL_DOUT, RESLUT_DOUT,
            AXI_CU_LOAD_DATA_PATH, AXI_CU_WRITE_DATA_PATH;
wire [319:0] MMU_ACC_PATH;
wire [7:0] ADDRA, ADDRB;
wire [1:0] axi_sm_mode;
wire axi_txn_en;


// AXI4 Lite Master
myip_AXI4_Lite_Master_0 M00 (
	// Users to add ports here
	.c_m00_mode(axi_sm_mode),
	.c_m00_off_mem_addra({24'h000000, ADDRA}),
    .c_m00_off_mem_addrb({24'h000000, ADDRB}),
	.c_m00_wdata(CTRL_DOUT),
	.c_m00_rdata(AXI_CU_LOAD_DATA_PATH),
    // End of user ports
    .m00_axi_txn_en(axi_txn_en),
	.m00_axi_error(),
	.m00_axi_inst_done(INST_DONE),
	.m00_axi_aclk(clk),
	.m00_axi_aresetn(reset_n),
	.m00_axi_awaddr(m00_axi_awaddr),
	.m00_axi_awprot(m00_axi_awprot),
	.m00_axi_awvalid(m00_axi_awvalid),
	.m00_axi_awready(m00_axi_awready),
	.m00_axi_wdata(m00_axi_wdata),
	.m00_axi_wstrb(m00_axi_wstrb),
    .m00_axi_wvalid(m00_axi_wvalid),
	.m00_axi_wready(m00_axi_wready),
	.m00_axi_bresp(m00_axi_bresp),
	.m00_axi_bvalid(m00_axi_bvalid),
    .m00_axi_bready(m00_axi_bready),
	.m00_axi_araddr(m00_axi_araddr),
	.m00_axi_arprot(m00_axi_arprot),
	.m00_axi_arvalid(m00_axi_arvalid),
	.m00_axi_arready(m00_axi_arready),
	.m00_axi_rdata(m00_axi_rdata),
	.m00_axi_rresp(m00_axi_rresp),
	.m00_axi_rvalid(m00_axi_rvalid),
	.m00_axi_rready(m00_axi_rready)
);

// Controller
CONTROL_UNIT CU (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .axi_sm_mode(axi_sm_mode),
    .axi_txn_en(axi_txn_en),
    .inst_done(INST_DONE),
    .din(AXI_CU_LOAD_DATA_PATH),
    .rin(RESLUT_DOUT),
    .uin(UB_DATA_PATH),
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
FIFO #(.FIFO_WIDTH(16*8), .FIFO_DEPTH(4)) WEIGHT_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(WEIGHT_FIFO_EN_SIG),
    .din(WB_WEIGHT_FIFO_PATH),
    .dout(WEIGHT_FIFO_MMU_PATH)
);

// Unified Buffer
BRAM #(.RAM_WIDTH(16*8), .RAM_DEPTH(256)) UB (
    .clk(clk),
    .wea(WRITE_UB_SIG),
    .enb(READ_UB_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(UB_DATA_PATH)
);

// Weight Buffer
BRAM #(.RAM_WIDTH(16*8), .RAM_DEPTH(256)) WB (
    .clk(clk),
    .wea(WRITE_WB_SIG),
    .enb(READ_WB_SIG),
    .addra(ADDRA),
    .addrb(ADDRB),
    .dina(CTRL_DOUT),
    .doutb(WB_WEIGHT_FIFO_PATH)
);

// Data-FIFO
FIFO #(.FIFO_WIDTH(16*8), .FIFO_DEPTH(4)) DATA_FIFO (
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
