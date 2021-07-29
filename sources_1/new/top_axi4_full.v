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

module SYSTOLIC_ARRAY_AXI4_FULL # 
(
    // AXI Parameters
    // Base address of targeted slave
    parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
    parameter integer C_M00_AXI_BURST_LEN	= 16,
    parameter integer C_M00_AXI_ID_WIDTH	= 1,
    parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
    parameter integer C_M00_AXI_DATA_WIDTH	= 128,
    parameter integer C_M00_AXI_AWUSER_WIDTH	= 0,
    parameter integer C_M00_AXI_ARUSER_WIDTH	= 0,
    parameter integer C_M00_AXI_WUSER_WIDTH	= 0,
    parameter integer C_M00_AXI_RUSER_WIDTH	= 0,
    parameter integer C_M00_AXI_BUSER_WIDTH	= 0,
    parameter [1:0] M_IDLE = 2'b00,
                    M_LOAD = 2'b01,
                    M_STORE = 2'b10
    // End of AXI params
)
(
    input  wire reset_n,
    input  wire clk,
    input  wire init_inst_pulse,
    input  wire [67:0] instruction,
    output wire idle_flag,
    output wire flag,
    // AXI4 Lite Master Signals
	// Ports of Axi Master Bus Interface M00_AXI
	output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
	output wire [7 : 0] m00_axi_awlen,
	output wire [2 : 0] m00_axi_awsize,
	output wire [1 : 0] m00_axi_awburst,
	output wire  m00_axi_awlock,
	output wire [3 : 0] m00_axi_awcache,
	output wire [2 : 0] m00_axi_awprot,
	output wire [3 : 0] m00_axi_awqos,
	output wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser,
	output wire  m00_axi_awvalid,
	input wire  m00_axi_awready,
	output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
	output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
	output wire  m00_axi_wlast,
	output wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser,
	output wire  m00_axi_wvalid,
	input wire  m00_axi_wready,
	input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
	input wire [1 : 0] m00_axi_bresp,
	input wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser,
	input wire  m00_axi_bvalid,
	output wire  m00_axi_bready,
	output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
	output wire [7 : 0] m00_axi_arlen,
	output wire [2 : 0] m00_axi_arsize,
	output wire [1 : 0] m00_axi_arburst,
	output wire  m00_axi_arlock,
	output wire [3 : 0] m00_axi_arcache,
	output wire [2 : 0] m00_axi_arprot,
	output wire [3 : 0] m00_axi_arqos,
	output wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] m00_axi_aruser,
	output wire  m00_axi_arvalid,
	input wire  m00_axi_arready,
	input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
	input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
	input wire [1 : 0] m00_axi_rresp,
	input wire  m00_axi_rlast,
	input wire [C_M00_AXI_RUSER_WIDTH-1 : 0] m00_axi_ruser,
	input wire  m00_axi_rvalid,
	output wire  m00_axi_rready
    // End of AXI4 Lite Master Signals
);

`ifndef TESTBENCH
`include "../../sa_share.v"
`endif

// Control signals
wire READ_UB_SIG, WRITE_UB_SIG, READ_WB_SIG, WRITE_WB_SIG, READ_ACC_SIG,
    WRITE_ACC_SIG, DATA_FIFO_EN_SIG, MMU_UB_TO_WEIGHT_FIFO_SIG, WEIGHT_FIFO_EN_SIG,
    MM_EN_SIG, ACC_EN_SIG, TXN_DONE;
// Datapaths
wire [127:0] DATA_FIFO_MMU_PATH, WEIGHT_FIFO_MMU_PATH,
            UB_DATA_PATH, WB_WEIGHT_FIFO_PATH, CTRL_DOUT, RESLUT_DOUT,
            AXI_CU_LOAD_DATA_PATH, AXI_CU_WRITE_DATA_PATH;
wire [319:0] MMU_ACC_PATH;
wire [UB_ADDRA_BITS-1:0]     UB_ADDRA;
wire [UB_ADDRB_BITS-1:0]     UB_ADDRB;
wire [WB_ADDRA_BITS-1:0]     WB_ADDRA;
wire [WB_ADDRB_BITS-1:0]     WB_ADDRB;
wire [ACC_ADDRA_BITS-1:0]    ACC_ADDRA;
wire [ACC_ADDRB_BITS-1:0]    ACC_ADDRB;
wire [OFFMEM_ADDRA_BITS-1:0] OFFMEM_ADDRA;
wire [OFFMEM_ADDRB_BITS-1:0] OFFMEM_ADDRB;
wire [1:0] axi_sm_mode;
//wire axi_txn_en;
wire init_txn_pulse;

// AXI4 Full Master
myip_SA_AXI4_Master_0 M00
(
	// Users to add ports here
	.c_m00_mode(axi_sm_mode),
	.c_m00_off_mem_addra(OFFMEM_ADDRA),
    .c_m00_off_mem_addrb(OFFMEM_ADDRB),
	.c_m00_wdata(CTRL_DOUT),
	.c_m00_rdata(AXI_CU_LOAD_DATA_PATH),
    // End of user ports

    .m00_axi_init_axi_txn(init_txn_pulse),
    .m00_axi_txn_done(TXN_DONE),
    .m00_axi_error(axi_error),
    .m00_axi_aclk(clk),
    .m00_axi_aresetn(reset_n),
    .m00_axi_awid(m00_axi_awid),
    .m00_axi_awaddr(m00_axi_awaddr),
    .m00_axi_awlen(m00_axi_awlen),
    .m00_axi_awsize(m00_axi_awsize),
    .m00_axi_awburst(m00_axi_awburst),
    .m00_axi_awlock(m00_axi_awlock),
    .m00_axi_awcache(m00_axi_awcache),
    .m00_axi_awprot(m00_axi_awprot),
    .m00_axi_awqos(m00_axi_awqos),
    .m00_axi_awuser(m00_axi_awuser),
    .m00_axi_awvalid(m00_axi_awvalid),
    .m00_axi_awready(m00_axi_awready),
    .m00_axi_wdata(m00_axi_wdata),
    .m00_axi_wstrb(m00_axi_wstrb),
    .m00_axi_wlast(m00_axi_wlast),
    .m00_axi_wuser(m00_axi_wuser),
    .m00_axi_wvalid(m00_axi_wvalid),
    .m00_axi_wready(m00_axi_wready),
    .m00_axi_bid(m00_axi_bid),
    .m00_axi_bresp(m00_axi_bresp),
    .m00_axi_buser(m00_axi_buser),
    .m00_axi_bvalid(m00_axi_bvalid),
    .m00_axi_bready(m00_axi_bready),
    .m00_axi_arid(m00_axi_arid),
    .m00_axi_araddr(m00_axi_araddr),
    .m00_axi_arlen(m00_axi_arlen),
    .m00_axi_arsize(m00_axi_arsize),
    .m00_axi_arburst(m00_axi_arburst),
    .m00_axi_arlock(m00_axi_arlock),
    .m00_axi_arcache(m00_axi_arcache),
    .m00_axi_arprot(m00_axi_arprot),
    .m00_axi_arqos(m00_axi_arqos),
    .m00_axi_aruser(m00_axi_aruser),
    .m00_axi_arvalid(m00_axi_arvalid),
    .m00_axi_arready(m00_axi_arready),
    .m00_axi_rid(m00_axi_rid),
    .m00_axi_rdata(m00_axi_rdata),
    .m00_axi_rresp(m00_axi_rresp),
    .m00_axi_rlast(m00_axi_rlast),
    .m00_axi_ruser(m00_axi_ruser),
    .m00_axi_rvalid(m00_axi_rvalid),
    .m00_axi_rready(m00_axi_rready)
);

// Controller
CONTROL_UNIT_AXI4_FULL # (
    .OPCODE_BITS(OPCODE_BITS),
    .UB_ADDRA_BITS(UB_ADDRA_BITS),
    .UB_ADDRB_BITS(UB_ADDRB_BITS),
    .WB_ADDRA_BITS(WB_ADDRA_BITS),
    .WB_ADDRB_BITS(WB_ADDRB_BITS),
    .ACC_ADDRA_BITS(ACC_ADDRA_BITS),
    .ACC_ADDRB_BITS(ACC_ADDRB_BITS),
    .OFFMEM_ADDRA_BITS(OFFMEM_ADDRA_BITS),
    .OFFMEM_ADDRB_BITS(OFFMEM_ADDRB_BITS),
    .INST_BITS(INST_BITS),
    .DIN_BITS(DIN_BITS),

    .OPCODE_FROM(OPCODE_FROM),
    .OPCODE_TO(OPCODE_TO),
    .ADDRA_FROM(ADDRA_FROM),
    .ADDRA_TO(ADDRA_TO),
    .ADDRB_FROM(ADDRB_FROM),
    .ADDRB_TO(ADDRB_TO),

    .IDLE_INST(IDLE_INST),
    .DATA_FIFO_INST(DATA_FIFO_INST),
    .WEIGHT_FIFO_INST(WEIGHT_FIFO_INST),
    .AXI_TO_UB_INST(AXI_TO_UB_INST),
    .AXI_TO_WB_INST(AXI_TO_WB_INST),
    .UB_TO_DATA_FIFO_INST(UB_TO_DATA_FIFO_INST),
    .UB_TO_WEIGHT_FIFO_INST(UB_TO_WEIGHT_FIFO_INST),
    .MAT_MUL_INST(MAT_MUL_INST),
    .MAT_MUL_ACC_INST(MAT_MUL_ACC_INST),
    .ACC_TO_UB_INST(ACC_TO_UB_INST),
    .UB_TO_AXI_INST(UB_TO_AXI_INST)
) CU (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .axi_sm_mode(axi_sm_mode),
    //.axi_txn_en(axi_txn_en),
    .init_inst_pulse(init_inst_pulse),
    .init_txn_pulse(init_txn_pulse),
    .txn_done(TXN_DONE),
    .din(AXI_CU_LOAD_DATA_PATH),
    .rin(RESLUT_DOUT),
    .uin(UB_DATA_PATH),
    .idle_flag(idle_flag),
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
    .ub_addra(UB_ADDRA),
    .ub_addrb(UB_ADDRB),
    .wb_addra(WB_ADDRA),
    .wb_addrb(WB_ADDRB),
    .acc_addra(ACC_ADDRA),
    .acc_addrb(ACC_ADDRB),
    .offmem_addra(OFFMEM_ADDRA),
    .offmem_addrb(OFFMEM_ADDRB),
    .dout(CTRL_DOUT)
);

// Weight-FIFO
FIFO # (
    .FIFO_WIDTH(16*8),
    .FIFO_DEPTH(4)
) WEIGHT_FIFO (
    .reset_n(reset_n),
    .clk(clk),
    .en(WEIGHT_FIFO_EN_SIG),
    .din(WB_WEIGHT_FIFO_PATH),
    .dout(WEIGHT_FIFO_MMU_PATH)
);

// Unified Buffer
BRAM # (
    .RAM_WIDTH(16*8),
    .RAM_DEPTH(256)
) UB (
    .clk(clk),
    .wea(WRITE_UB_SIG),
    .enb(READ_UB_SIG),
    .addra(UB_ADDRA),
    .addrb(UB_ADDRB),
    .dina(CTRL_DOUT),
    .doutb(UB_DATA_PATH)
);

// Weight Buffer
BRAM # (
    .RAM_WIDTH(16*8),
    .RAM_DEPTH(256)
) WB (
    .clk(clk),
    .wea(WRITE_WB_SIG),
    .enb(READ_WB_SIG),
    .addra(WB_ADDRA),
    .addrb(WB_ADDRB),
    .dina(CTRL_DOUT),
    .doutb(WB_WEIGHT_FIFO_PATH)
);

// Data-FIFO
FIFO #(
    .FIFO_WIDTH(16*8),
    .FIFO_DEPTH(4)
) DATA_FIFO (
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
ACCUMULATOR # (
    .DATA_SIZE(20),
    .OUTPUT_DATA_SIZE(8),
    .DATA_NUM(16),
    .RAM_DEPTH(64)
) ACC (
    .clk(clk),
    .wea(WRITE_ACC_SIG),
    .enb(READ_ACC_SIG),
    .acc_en(ACC_EN_SIG),
    .addra(ACC_ADDRA),
    .addrb(ACC_ADDRB),
    .dina(MMU_ACC_PATH),
    .doutb(RESLUT_DOUT)
);

endmodule
// End of Systolic Array's TOP module //
