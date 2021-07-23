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

//`define READ_TB
`define WRITE_TB

module axi_tb;

// Clock localparams
parameter CLOCK_PS             = 10000;      //  should be a multiple of 10
parameter clock_period         = CLOCK_PS / 1000.0;
parameter half_clock_period    = clock_period / 2;
parameter minimum_period       = clock_period / 10;
parameter AXI_ADDR_WIDTH       = 32;
parameter AXI_DATA_WIDTH       = 32;
parameter AXI_TRANSACTIONS_NUM = 4;
parameter [1:0] IDLE = 2'b00,
                LOAD_DATA   = 2'b01,
                WRITE_DATA  = 2'b10;

// regs & wires
reg reset_n = 1'b1, clk;
reg [1:0] axi_sm_mode;  // 0: IDLE, 1: LOAD_DATA, 2: WRITE_DATA
//reg [AXI_DATA_WIDTH-1 : 0] C_M_OFF_MEM_ADDRA = 'd0;
//reg [AXI_DATA_WIDTH-1 : 0] C_M_OFF_MEM_ADDRB = 'd0;
reg [AXI_DATA_WIDTH*AXI_TRANSACTIONS_NUM-1 : 0] C_M_WDATA;
reg axi_txn_en = 1'b0;
wire INST_DONE;
// AXI Signals
wire [AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
wire [2 : 0] axi_awprot;
wire axi_awvalid;
wire axi_awready;
wire [AXI_DATA_WIDTH-1 : 0] axi_wdata;
wire [AXI_DATA_WIDTH/8-1 : 0] axi_wstrb;
wire axi_wvalid;
wire axi_wready;
wire [1 : 0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [AXI_ADDR_WIDTH-1 : 0] axi_araddr;
wire [2 : 0] axi_arprot;
wire axi_arvalid;
wire axi_arready;
wire [AXI_DATA_WIDTH-1 : 0] axi_rdata;
wire [1 : 0] axi_rresp;
wire axi_rvalid;
wire axi_rready;
reg [7:0] ADDRA = 8'h00, ADDRB = 8'h00;
reg [AXI_DATA_WIDTH*AXI_TRANSACTIONS_NUM-1 : 0] AXI_CU_AXI_TO_UB_PATH;
wire [AXI_DATA_WIDTH*AXI_TRANSACTIONS_NUM-1 : 0] AXI_CU_UB_TO_DATA_FIFO_PATH;
// End of AXI Signals

// AXI4 Lite Master
myip_AXI4_Lite_Master_0 M00 (
	// Users to add ports here
	.c_m00_mode(axi_sm_mode),
	.c_m00_off_mem_addra({24'h000000, ADDRA}),
    .c_m00_off_mem_addrb({24'h000000, ADDRB}),
	.c_m00_wdata(AXI_CU_AXI_TO_UB_PATH),
	.c_m00_rdata(AXI_CU_UB_TO_DATA_FIFO_PATH),
    // End of user ports

    .m00_axi_txn_en(axi_txn_en),
	.m00_axi_error(),
	.m00_axi_inst_done(INST_DONE),
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
OFF_MEM #(.INIT_FILE("C:\\Users\\DICE\\systolic_array\\systolic_array.srcs\\sim_1\\new\\hex_mem.mem")) OM0 (
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

    // 1. Read BRAM data from slave //
    `ifdef READ_TB
    for (integer i = 0; i < 256; i = i + 4) begin
        wait(INST_DONE == 1'b0);
        //$display("[Testbench:READ_TB:%d] Instruction start.", i);
        axi_txn_en  <= 1'b1;
        axi_sm_mode <= LOAD_DATA;
        ADDRB <= i;
        wait (INST_DONE == 1'b1);
        //$display("[Testbench:READ_TB:%d] Instruction done.", i);
        axi_txn_en = 1'b0;
    end
    `endif

    // 2. Write data to slave's BRAM //
    `ifdef WRITE_TB
    for (integer i = 0; i < 256; i = i + 4) begin
        wait(INST_DONE == 1'b0);
        //$display("[Testbench:WRITE_TB:%d] Instruction start.", i);
        AXI_CU_AXI_TO_UB_PATH <= i * i;
        axi_txn_en  <= 1'b1;
        axi_sm_mode <= WRITE_DATA;
        ADDRA <= i;
        wait (INST_DONE == 1'b1);
        //$display("[Testbench:WRITE_TB:%d] Instruction done.", i);
        axi_txn_en = 1'b0;
    end
    `endif
end


endmodule
