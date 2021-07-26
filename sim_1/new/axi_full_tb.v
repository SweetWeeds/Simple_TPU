`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: 
// 
// Create Date: 2021/07/15 15:11:56
// Design Name: 
// Module Name: axi_tb
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

`define READ_TB
`define WRITE_TB

module axi_full_tb;

// AXI Parameters
// Base address of targeted slave
parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000;
parameter integer C_M00_AXI_BURST_LEN	= 16;
parameter integer C_M00_AXI_ID_WIDTH	= 1;
parameter integer C_M00_AXI_ADDR_WIDTH	= 32;
parameter integer C_M00_AXI_DATA_WIDTH	= 128;
parameter integer C_M00_AXI_AWUSER_WIDTH	= 0;
parameter integer C_M00_AXI_ARUSER_WIDTH	= 0;
parameter integer C_M00_AXI_WUSER_WIDTH	= 0;
parameter integer C_M00_AXI_RUSER_WIDTH	= 0;
parameter integer C_M00_AXI_BUSER_WIDTH	= 0;
parameter [1:0] M_IDLE = 2'b00,
                M_LOAD = 2'b01,
                M_STORE = 2'b10;
// End of AXI params

// Clock localparams
parameter CLOCK_PS             = 10000;      //  should be a multiple of 10
parameter clock_period         = CLOCK_PS / 1000.0;
parameter half_clock_period    = clock_period / 2;
parameter minimum_period       = clock_period / 10;

// regs & wires
reg reset_n = 1'b1, clk;
reg [1:0] axi_sm_mode;  // 0: M_IDLE, 1: M_LOAD, 2: M_STORE
reg [C_M00_AXI_DATA_WIDTH-1 : 0] C_M_WDATA;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] C_M_RDATA;
reg [C_M00_AXI_ADDR_WIDTH-1 : 0] C_M_ADDRA;
reg [C_M00_AXI_ADDR_WIDTH-1 : 0] C_M_ADDRB;
//reg axi_txn_en = 1'b0;
// AXI Signals
reg  axi_init_axi_txn = 1'b0;
wire axi_txn_done;
wire axi_error;
wire axi_aclk;
wire axi_aresetn;
wire [C_M00_AXI_ID_WIDTH-1 : 0] axi_awid;
wire [C_M00_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
wire [7 : 0] axi_awlen;
wire [2 : 0] axi_awsize;
wire [1 : 0] axi_awburst;
wire axi_awlock;
wire [3 : 0] axi_awcache;
wire [2 : 0] axi_awprot;
wire [3 : 0] axi_awqos;
wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] axi_awuser;
wire axi_awvalid;
wire axi_awready;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] axi_wdata;
wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] axi_wstrb;
wire axi_wlast;
wire [C_M00_AXI_WUSER_WIDTH-1 : 0] axi_wuser;
wire axi_wvalid;
wire axi_wready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] axi_bid;
wire [1 : 0] axi_bresp;
wire [C_M00_AXI_BUSER_WIDTH-1 : 0] axi_buser;
wire axi_bvalid;
wire axi_bready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] axi_arid;
wire [C_M00_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
wire [7 : 0] axi_arlen;
wire [2 : 0] axi_arsize;
wire [1 : 0] axi_arburst;
wire axi_arlock;
wire [3 : 0] axi_arcache;
wire [2 : 0] axi_arprot;
wire [3 : 0] axi_arqos;
wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] axi_aruser;
wire axi_arvalid;
wire axi_arready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] axi_rid;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] axi_rdata;
wire [1 : 0] axi_rresp;
wire axi_rlast;
wire [C_M00_AXI_RUSER_WIDTH-1 : 0] axi_ruser;
wire axi_rvalid;
wire axi_rready;
// End of AXI Signals

assign axi_aclk = clk;
assign axi_aresetn = reset_n;

// AXI4 Full Master
myip_SA_AXI4_Master_0 M00
(
	// Users to add ports here
	.c_m00_mode(axi_sm_mode),
	.c_m00_off_mem_addra(C_M_ADDRA),
    .c_m00_off_mem_addrb(C_M_ADDRB),
	.c_m00_wdata(C_M_WDATA),
	.c_m00_rdata(C_M_RDATA),
    // End of user ports

    .m00_axi_init_axi_txn(axi_init_axi_txn),
    .m00_axi_txn_done(axi_txn_done),
    .m00_axi_error(axi_error),
    .m00_axi_aclk(axi_aclk),
    .m00_axi_aresetn(axi_aresetn),
    .m00_axi_awid(axi_awid),
    .m00_axi_awaddr(axi_awaddr),
    .m00_axi_awlen(axi_awlen),
    .m00_axi_awsize(axi_awsize),
    .m00_axi_awburst(axi_awburst),
    .m00_axi_awlock(axi_awlock),
    .m00_axi_awcache(axi_awcache),
    .m00_axi_awprot(axi_awprot),
    .m00_axi_awqos(axi_awqos),
    .m00_axi_awuser(axi_awuser),
    .m00_axi_awvalid(axi_awvalid),
    .m00_axi_awready(axi_awready),
    .m00_axi_wdata(axi_wdata),
    .m00_axi_wstrb(axi_wstrb),
    .m00_axi_wlast(axi_wlast),
    .m00_axi_wuser(axi_wuser),
    .m00_axi_wvalid(axi_wvalid),
    .m00_axi_wready(axi_wready),
    .m00_axi_bid(axi_bid),
    .m00_axi_bresp(axi_bresp),
    .m00_axi_buser(axi_buser),
    .m00_axi_bvalid(axi_bvalid),
    .m00_axi_bready(axi_bready),
    .m00_axi_arid(axi_arid),
    .m00_axi_araddr(axi_araddr),
    .m00_axi_arlen(axi_arlen),
    .m00_axi_arsize(axi_arsize),
    .m00_axi_arburst(axi_arburst),
    .m00_axi_arlock(axi_arlock),
    .m00_axi_arcache(axi_arcache),
    .m00_axi_arprot(axi_arprot),
    .m00_axi_arqos(axi_arqos),
    .m00_axi_aruser(axi_aruser),
    .m00_axi_arvalid(axi_arvalid),
    .m00_axi_arready(axi_arready),
    .m00_axi_rid(axi_rid),
    .m00_axi_rdata(axi_rdata),
    .m00_axi_rresp(axi_rresp),
    .m00_axi_rlast(axi_rlast),
    .m00_axi_ruser(axi_ruser),
    .m00_axi_rvalid(axi_rvalid),
    .m00_axi_rready(axi_rready)
);


// Slave off memory
myip_SA_AXI4_Slave_0 S00
(
    .s00_axi_aclk(axi_aclk),
    .s00_axi_aresetn(axi_aresetn),
    .s00_axi_awid(axi_awid),
    .s00_axi_awaddr(axi_awaddr),
    .s00_axi_awlen(axi_awlen),
    .s00_axi_awsize(axi_awsize),
    .s00_axi_awburst(axi_awburst),
    .s00_axi_awlock(axi_awlock),
    .s00_axi_awcache(axi_awcache),
    .s00_axi_awprot(axi_awprot),
    .s00_axi_awqos(axi_awqos),
    .s00_axi_awregion(axi_awregion),
    .s00_axi_awuser(axi_awuser),
    .s00_axi_awvalid(axi_awvalid),
    .s00_axi_awready(axi_awready),
    .s00_axi_wdata(axi_wdata),
    .s00_axi_wstrb(axi_wstrb),
    .s00_axi_wlast(axi_wlast),
    .s00_axi_wuser(axi_wuser),
    .s00_axi_wvalid(axi_wvalid),
    .s00_axi_wready(axi_wready),
    .s00_axi_bid(axi_bid),
    .s00_axi_bresp(axi_bresp),
    .s00_axi_buser(axi_buser),
    .s00_axi_bvalid(axi_bvalid),
    .s00_axi_bready(axi_bready),
    .s00_axi_arid(axi_arid),
    .s00_axi_araddr(axi_araddr),
    .s00_axi_arlen(axi_arlen),
    .s00_axi_arsize(axi_arsize),
    .s00_axi_arburst(axi_arburst),
    .s00_axi_arlock(axi_arlock),
    .s00_axi_arcache(axi_arcache),
    .s00_axi_arprot(axi_arprot),
    .s00_axi_arqos(axi_arqos),
    .s00_axi_arregion(axi_arregion),
    .s00_axi_aruser(axi_aruser),
    .s00_axi_arvalid(axi_arvalid),
    .s00_axi_arready(axi_arready),
    .s00_axi_rid(axi_rid),
    .s00_axi_rdata(axi_rdata),
    .s00_axi_rresp(axi_rresp),
    .s00_axi_rlast(axi_rlast),
    .s00_axi_ruser(axi_ruser),
    .s00_axi_rvalid(axi_rvalid),
    .s00_axi_rready(axi_rready)
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


initial begin : TEST_BENCH
    // Initialization with 'reset_n' (0 ~ 10000 ns)
    # clock_period;
    reset_n = 1'b0;
    # clock_period;
    reset_n = 1'b1;

    // 1. Write data to slave's BRAM //
    `ifdef WRITE_TB
    for (integer i = 256-16; i >= 0; i = i - 16) begin
        wait(axi_txn_done == 1'b0);
        $display("[Testbench:WRITE_TB:%d] Instruction start.", i);
        C_M_WDATA <= i * i;
        axi_init_axi_txn  <= 1'b1;
        axi_sm_mode <= M_STORE;
        C_M_ADDRA <= i;
        wait (axi_txn_done == 1'b1);
        $display("[Testbench:WRITE_TB:%d] Instruction done.", i);
        axi_init_axi_txn <= 1'b0;
    end
    `endif

    // 2. Read BRAM data from slave //
    `ifdef READ_TB
    for (integer i = 0; i < 256; i = i + 16) begin
        wait(axi_txn_done == 1'b0);
        $display("[Testbench:READ_TB:%d] Instruction start.", i);
        axi_init_axi_txn  <= 1'b1;
        axi_sm_mode <= M_LOAD;
        C_M_ADDRB <= i;
        wait (axi_txn_done == 1'b1);
        $display("[Testbench:READ_TB:%d] Instruction done.", i);
        axi_init_axi_txn <= 1'b0;
    end
    `endif
end


endmodule
