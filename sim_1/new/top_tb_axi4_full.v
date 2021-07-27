`define TESTBENCH

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

module TOP_TB_AXI4_FULL;

`include "../../sa_share.v"

// AXI Parameters
// Base address of targeted slave
localparam  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000;
localparam integer C_M00_AXI_BURST_LEN	= 16;
localparam integer C_M00_AXI_ID_WIDTH	= 1;
localparam integer C_M00_AXI_ADDR_WIDTH	= 32;
localparam integer C_M00_AXI_DATA_WIDTH	= 128;
localparam integer C_M00_AXI_AWUSER_WIDTH = 0;
localparam integer C_M00_AXI_ARUSER_WIDTH = 0;
localparam integer C_M00_AXI_WUSER_WIDTH	= 0;
localparam integer C_M00_AXI_RUSER_WIDTH	= 0;
localparam integer C_M00_AXI_BUSER_WIDTH	= 0;
localparam [1:0] M_IDLE = 2'b00,
                M_LOAD = 2'b01,
                M_STORE = 2'b10;
// End of AXI params

// Clock localparams
localparam  CLOCK_PS            = 10000;      //  should be a multiple of 10
localparam clock_period         = CLOCK_PS / 1000.0;
localparam half_clock_period    = clock_period / 2;
localparam minimum_period       = clock_period / 10;
localparam AXI_ADDR_WIDTH       = 32;
localparam AXI_DATA_WIDTH       = 32;
localparam AXI_TRANSACTIONS_NUM = 4;

// regs & wires
reg reset_n = 1'b1, clk, wen = 1'b1;
wire idle_flag;
wire flag;
wire [INST_BITS-1:0] instruction;
wire [319:0] dout;
wire [DIN_BITS-1:0] din;
// AXI Signals
reg  axi_init_axi_txn = 1'b0;
wire axi_txn_done;
wire m00_axi_error;
wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid;
wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr;
wire [7 : 0] m00_axi_awlen;
wire [2 : 0] m00_axi_awsize;
wire [1 : 0] m00_axi_awburst;
wire m00_axi_awlock;
wire [3 : 0] m00_axi_awcache;
wire [2 : 0] m00_axi_awprot;
wire [3 : 0] m00_axi_awqos;
wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser;
wire m00_axi_awvalid;
wire m00_axi_awready;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata;
wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb;
wire m00_axi_wlast;
wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser;
wire m00_axi_wvalid;
wire m00_axi_wready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid;
wire [1 : 0] m00_axi_bresp;
wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser;
wire m00_axi_bvalid;
wire m00_axi_bready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid;
wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr;
wire [7 : 0] m00_axi_arlen;
wire [2 : 0] m00_axi_arsize;
wire [1 : 0] m00_axi_arburst;
wire m00_axi_arlock;
wire [3 : 0] m00_axi_arcache;
wire [2 : 0] m00_axi_arprot;
wire [3 : 0] m00_axi_arqos;
wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] m00_axi_aruser;
wire m00_axi_arvalid;
wire m00_axi_arready;
wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata;
wire [1 : 0] m00_axi_rresp;
wire m00_axi_rlast;
wire [C_M00_AXI_RUSER_WIDTH-1 : 0] m00_axi_ruser;
wire m00_axi_rvalid;
wire m00_axi_rready;
// End of AXI Signals
reg [OPCODE_BITS-1:0] OPCODE = 'd0;
reg [OFFMEM_ADDRA_BITS-1:0] ADDRA = 'd0, ADDRB = 'd0;
reg [DIN_BITS-1:0] INPUT_DATA = 'd0;

assign instruction[OPCODE_FROM:OPCODE_TO]   = OPCODE;
assign instruction[ADDRA_FROM:ADDRA_TO]     = ADDRA;
assign instruction[ADDRB_FROM:ADDRB_TO]     = ADDRB;
//assign instruction[OPERAND_FROM:OPERAND_TO] = OPERAND;
assign din = INPUT_DATA;

// Instantiation
SYSTOLIC_ARRAY_AXI4_FULL # (
    .C_M00_AXI_ADDR_WIDTH(32),
    .C_M00_AXI_DATA_WIDTH(128)
) SA0 (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .idle_flag(idle_flag),
    .flag(flag),
    // Start of AXI4 Full Signals //
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
    // End of AXI4 Full Signals //
);

// Slave off memory
myip_SA_AXI4_Slave_0 # (
    .IS_TESTBENCH('d1),
    .INIT_FILE("/home/hankyulkwon/vivado_project/systolic_array/systolic_array.srcs/sim_1/new/hex_mem.mem")
) S00 (
    .s00_axi_aclk(clk),
    .s00_axi_aresetn(reset_n),
    .s00_axi_awid(m00_axi_awid),
    .s00_axi_awaddr(m00_axi_awaddr),
    .s00_axi_awlen(m00_axi_awlen),
    .s00_axi_awsize(m00_axi_awsize),
    .s00_axi_awburst(m00_axi_awburst),
    .s00_axi_awlock(m00_axi_awlock),
    .s00_axi_awcache(m00_axi_awcache),
    .s00_axi_awprot(m00_axi_awprot),
    .s00_axi_awqos(m00_axi_awqos),
    .s00_axi_awregion(m00_axi_awregion),
    .s00_axi_awuser(m00_axi_awuser),
    .s00_axi_awvalid(m00_axi_awvalid),
    .s00_axi_awready(m00_axi_awready),
    .s00_axi_wdata(m00_axi_wdata),
    .s00_axi_wstrb(m00_axi_wstrb),
    .s00_axi_wlast(m00_axi_wlast),
    .s00_axi_wuser(m00_axi_wuser),
    .s00_axi_wvalid(m00_axi_wvalid),
    .s00_axi_wready(m00_axi_wready),
    .s00_axi_bid(m00_axi_bid),
    .s00_axi_bresp(m00_axi_bresp),
    .s00_axi_buser(m00_axi_buser),
    .s00_axi_bvalid(m00_axi_bvalid),
    .s00_axi_bready(m00_axi_bready),
    .s00_axi_arid(m00_axi_arid),
    .s00_axi_araddr(m00_axi_araddr),
    .s00_axi_arlen(m00_axi_arlen),
    .s00_axi_arsize(m00_axi_arsize),
    .s00_axi_arburst(m00_axi_arburst),
    .s00_axi_arlock(m00_axi_arlock),
    .s00_axi_arcache(m00_axi_arcache),
    .s00_axi_arprot(m00_axi_arprot),
    .s00_axi_arqos(m00_axi_arqos),
    .s00_axi_arregion(m00_axi_arregion),
    .s00_axi_aruser(m00_axi_aruser),
    .s00_axi_arvalid(m00_axi_arvalid),
    .s00_axi_arready(m00_axi_arready),
    .s00_axi_rid(m00_axi_rid),
    .s00_axi_rdata(m00_axi_rdata),
    .s00_axi_rresp(m00_axi_rresp),
    .s00_axi_rlast(m00_axi_rlast),
    .s00_axi_ruser(m00_axi_ruser),
    .s00_axi_rvalid(m00_axi_rvalid),
    .s00_axi_rready(m00_axi_rready)
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
    # clock_period;
    reset_n = 1'b0;
    # clock_period;
    reset_n = 1'b1;
    # clock_period;

    @ (flag == 1'b1);
    @ (flag == 1'b0);

    // 1. Write data to UB
    $display("[%0t:TOP_TB:TEST_BENCH] 1. Write data to UB", $time);
    for (integer i = 0; i < 256; i = i + 16) begin
        $display("[%0t:TOP_TB:TEST_BENCH] Write data to UB(%d)", $time, i);
        OPCODE <= AXI_TO_UB_INST;
        ADDRA <= i/16;  // Write addr (UB)
        ADDRB <= i;  // Read addr (off-mem)
        @ (flag == 1'b1);
        @ (flag == 1'b0);
        // Synchronize instruction input in testbench.
        if (i == 0) wait (idle_flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 2. Write weight to WB
    $display("[%0t:TOP_TB:TEST_BENCH] 2. Write data to WB", $time);
    for (integer i = 0; i < 256; i = i + 16) begin
        $display("[%0t:TOP_TB:TEST_BENCH] Write data to WB(%d)", $time, i);
        OPCODE <= AXI_TO_WB_INST;
        ADDRA <= i/4;      // Write addr (WB)
        ADDRB <= (251-i);  // Read addr (off-mem)
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 3. IDLE
    $display("[%0t:TOP_TB:TEST_BENCH] 3. IDLE", $time);
    for (integer i = 0; i < 256; i = i + 1) begin
        $display("[%0t:TOP_TB:TEST_BENCH] IDLE(%d)", $time, i);
        OPCODE <= IDLE_INST;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 4. Load Data
    $display("[%0t:TOP_TB:TEST_BENCH] 4. Load data", $time);
    for (integer i = 0; i < 5; i = i + 1) begin
        $display("[%0t:TOP_TB:TEST_BENCH] Load data(%d)", $time, i);
        OPCODE <= UB_TO_DATA_FIFO_INST;
        ADDRB <= i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
        if (i == 0) wait (idle_flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 5. Load Weight
    $display("[%0t:TOP_TB:TEST_BENCH] 5. Load Weight", $time);
    for (integer i = 0; i < 21; i = i + 1) begin
        $display("[%0t:TOP_TB:TEST_BENCH] Load weight(%d)", $time, i);
        OPCODE <= UB_TO_WEIGHT_FIFO_INST;
        ADDRB <= i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 6. Matrix Multiplication
    $display("[%0t:TOP_TB:TEST_BENCH] 6. Matrix Multiplication", $time);
    for (integer i = 0; i < 16; i = i + 1) begin
        OPCODE <= MAT_MUL_INST;
        ADDRA <= i;
        ADDRB <= i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 7. Write result at UB
    $display("[%0t:TOP_TB:TEST_BENCH] 7. Write result at UB", $time);
    for (integer i = 0; i < 16; i = i + 1) begin
        OPCODE <= ACC_TO_UB_INST;
        ADDRA <= 64 + i;
        ADDRB <= i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 8. Write UB's results at OFF-MEM
    $display("[%0t:TOP_TB:TEST_BENCH] 8. Write UB's results at OFF-MEM", $time);
    for (integer i = 0; i < 16; i = i + 1) begin
        OPCODE <= UB_TO_AXI_INST;
        ADDRA  <= i * 4;
        ADDRB  <= 64 + i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 9. Matrix Multiplication with accumulation.
    $display("[%0t:TOP_TB:TEST_BENCH] 9. Matrix Multiplication with accumulation", $time);
    for (integer i = 0; i < 16; i = i + 1) begin
        OPCODE <= MAT_MUL_ACC_INST;
        ADDRA <= i;
        ADDRB <= 16 + i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 10. Write result at UB
    $display("[%0t:TOP_TB:TEST_BENCH] 10. Write result at UB", $time);
    for (integer i = 0; i < 16; i = i + 1) begin
        OPCODE <= ACC_TO_UB_INST;
        ADDRA <= 64 + 16 + i;
        ADDRB <= i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    @ (flag == 1'b1);
    @ (flag == 1'b0);
    $stop();

    // 11. Write UB's results at OFF-MEM
    $display("[%0t:TOP_TB:TEST_BENCH] 11. Write UB's results at OFF-MEM", $time);
    for (integer i = 16; i < 33; i = i + 1) begin
        OPCODE  <= UB_TO_AXI_INST;
        ADDRA   <= i * 4;
        ADDRB   <= 64 + i;
        @ (flag == 1'b1);
        @ (flag == 1'b0);
    end
    OPCODE <= IDLE_INST;
    $stop();

end

endmodule
// End of MMU_test //
