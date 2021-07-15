`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
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


module axi_tb;

// Clock localparams
parameter  CLOCK_PS            = 10000;      //  should be a multiple of 10
parameter clock_period         = CLOCK_PS / 1000.0;
parameter half_clock_period    = clock_period / 2;
parameter minimum_period       = clock_period / 10;
parameter AXI_ADDR_WIDTH       = 32;
parameter AXI_DATA_WIDTH       = 32;
parameter AXI_TRANSACTIONS_NUM = 4;

// regs & wires
reg reset_n = 1'b1, clk, wen = 1'b1;

// AXI4 Lite Master
myip_AXI4_Lite_Master_0 M00 (
	// Users to add ports here
	.c_m00_mode(axi_sm_mode),
	.c_m00_off_mem_addra({24'h000000, ADDRA}),
    .c_m00_off_mem_addrb({24'h000000, ADDRB}),
	.c_m00_wdata(AXI_CU_WRITE_DATA_PATH),
	.c_m00_rdata(AXI_CU_LOAD_DATA_PATH),
    // End of user ports

    .m00_axi_init_axi_txn(init_axi_txn),
	.m00_axi_error(),
	.m00_axi_txn_done(TXN_DONE),
	.m00_axi_aclk(clk),
	.m00_axi_aresetn(reset_n),
	.m00_axi_awaddr(axi_awaddr),
	.m00_axi_awprot(axi_awprot),
	.m00_axi_awvalid(axi_awvalid),
	.m00_axi_awready(axi_awready),
	.m00_axi_wdata(axi_wdata),
	.m00_axi_wstrb(axi_wstrb),
    .m00_axi_wvalid(axi_wvalid),
	.m00_axi_wready(axi_wready),
	.m00_axi_bresp(axi_bresp),
	.m00_axi_bvalid(axi_bvalid),
    .m00_axi_bready(axi_bready),
	.m00_axi_araddr(axi_araddr),
	.m00_axi_arprot(axi_arprot),
	.m00_axi_arvalid(axi_arvalid),
	.m00_axi_arready(axi_arready),
	.m00_axi_rdata(axi_rdata),
	.m00_axi_rresp(axi_rresp),
	.m00_axi_rvalid(axi_rvalid),
	.m00_axi_rready(axi_rready)
);

// Slave off memory
OFF_MEM OM0 (
    .clk(clk),
    .reset_n(reset_n),
    .s00_axi_awaddr(axi_awaddr),
    .s00_axi_awprot(axi_awprot),
    .s00_axi_awvalid(axi_awvalid),
    .s00_axi_awready(axi_awready),
    .s00_axi_wdata(axi_wdata),
    .s00_axi_wstrb(axi_wstrb),
    .s00_axi_wvalid(axi_wvalid),
    .s00_axi_wready(axi_wready),
    .s00_axi_bresp(axi_bresp),
    .s00_axi_bvalid(axi_bvalid),
    .s00_axi_bready(axi_bready),
    .s00_axi_araddr(axi_araddr),
    .s00_axi_arprot(axi_arprot),
    .s00_axi_arvalid(axi_arvalid),
    .s00_axi_arready(axi_arready),
    .s00_axi_rdata(axi_rdata),
    .s00_axi_rresp(axi_rresp),
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

    // 
end


endmodule
