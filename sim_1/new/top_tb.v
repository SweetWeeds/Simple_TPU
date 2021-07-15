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

module TOP_test;

`include "tb_share.v"

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
wire [INST_BITS-1:0] instruction;
wire [319:0] dout;
wire [DIN_BITS-1:0] din;
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
// End of AXI Signals
reg [OPCODE_BITS-1:0] OPCODE;
reg [ADDRA_BITS-1:0] ADDRA, ADDRB;
reg [DIN_BITS-1:0] INPUT_DATA;

assign instruction[OPCODE_FROM:OPCODE_TO]   = OPCODE;
assign instruction[ADDRA_FROM:ADDRA_TO]     = ADDRA;
assign instruction[ADDRB_FROM:ADDRB_TO]     = ADDRB;
//assign instruction[OPERAND_FROM:OPERAND_TO] = OPERAND;
assign din = INPUT_DATA;

// Instantiation
SYSTOLIC_ARRAY SA0 (
    .reset_n(reset_n),
    .clk(clk),
    .instruction(instruction),
    .flag(),
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

initial begin: TEST_BENCH
    // Initialization with 'reset_n' (0 ~ 10000 ns)
    # minimum_period;
    reset_n = 1'b0;
    # minimum_period;
    reset_n = 1'b1;

    // 1. Write data to UB (10000 * 256 ns = 2560000 ns)
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = WRITE_DATA_INST;
        ADDRA = i;
        # (IDLE_CYCLE * clock_period);
    end

`ifdef 0
    // 2. Write weight to WB (2560000 + 10000 * 256 ns = 5120000 ns)
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = WRITE_WEIGHT_INST;
        ADDRA = i;
        for (integer j = 15; j >= 0; j = j - 1) begin
            INPUT_DATA[j * 8 + : 8] = - i + j;
        end
        # (WRITE_WEIGHT_CYCLE * clock_period);
    end
    
    // 3. IDLE
    for (integer i = 0; i < 256; i = i + 1) begin
        OPCODE = IDLE_INST;
        # (IDLE_CYCLE * clock_period);
    end

    // 4. Load Data
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = LOAD_DATA_INST;
        ADDRB = i;
        # (LOAD_DATA_CYCLE * clock_period);
    end

    // 5. Load Weight
    for (integer i = 0; i < 21; i = i + 1) begin
        OPCODE = LOAD_WEIGHT_INST;
        ADDRB = i;
        # (LOAD_WEIGHT_CYCLE * clock_period);
    end

    // 6. Matrix Multiplication
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = MAT_MUL_INST;
        ADDRA = i;
        ADDRB = i;
        # (MAT_MUL_CYCLE * clock_period);
    end

    // 7. Write result at UB
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = WRITE_RESULT_INST;
        ADDRA = i;
        ADDRB = i;
        # (WRITE_RESULT_CYCLE * clock_period);
    end

    // 8. Matrix Multiplication with accumulation.
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = MAT_MUL_ACC_INST;
        ADDRA = i;
        ADDRB = i;
        # (MAT_MUL_CYCLE * clock_period);
    end

    // 9. Write result at UB
    for (integer i = 0; i < 5; i = i + 1) begin
        OPCODE = WRITE_RESULT_INST;
        ADDRA = i + 5;
        ADDRB = i;
        # (WRITE_RESULT_CYCLE * clock_period);
    end

    // 10. Read result at UB
    for (integer i = 0; i < 10; i = i + 1) begin
        OPCODE = READ_UB_INST;
        ADDRB = i;
        # (READ_UB_CYCLE * clock_period);
    end
`endif
end

endmodule
// End of MMU_test //
