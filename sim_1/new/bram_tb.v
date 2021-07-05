`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/01 12:47:00
// Design Name: BRAM test bench
// Module Name: bram_test
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Testbench for fifo module.
// 
// Dependencies: unified_buffer.v, weight_buffer.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bram_test;

`include "tb_share.v"

// Clock localparams
localparam  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS / 1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;
localparam RAM_WIDTH = 16*20;     // Specify RAM data width
localparam RAM_DEPTH = 256;      // Specify RAM depth (number of entries)

integer i = 0, j = 0;
reg signed [7:0] TEST_DATA [0:255][0:15];

// regs & wires
reg reset_n = 1'b1, clk, en = 1'b1;
reg acc_en = 1'b0;
reg wea;  // Write enable
reg enb;  // Read Enable; for additional power savings; disable when not in use
reg [clogb2(RAM_DEPTH-1)-1:0] addra;   // Write address bus; width determined from RAM_DEPTH
reg [clogb2(RAM_DEPTH-1)-1:0] addrb;   // Read address bus; width determined from RAM_DEPTH
reg [RAM_WIDTH-1:0] dina;     // RAM input data
wire [RAM_WIDTH-1:0] doutb;   // RAM output data
wire rstb;       // Output reset (does not affect memory contents)
wire regceb;      // Output register enable

// Instantiation
BRAM_256x16x8b UB (
    .clk(clk),
    .wea(wea),
    .enb(enb),
    .addra(addra),
    .addrb(addrb),
    .dina(dina),
    .doutb(doutb)
);

ACCUMULATOR ACC (
    .clk(clk),
    .wea(wea),
    .enb(enb),
    .acc_en(acc_en),
    .addra(addra),
    .addrb(addrb),
    .dina(dina),
    .doutb(doutb)
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
    # minimum_period;
    reset_n = 1'b0;
    # minimum_period;
    reset_n = 1'b1;

    // Generate test data
    for (i = 0; i < 256; i = i + 1) begin
       for (j = 0; j < 16; j = j + 1) begin
           TEST_DATA[i][j] = i / 2 - j;
       end 
    end


    // Write & Read test
    wea = 1'b1;
    enb = 1'b1;
    for (i = 1; i < 256; i = i + 1) begin
        dina = {
            TEST_DATA[i][15],
            TEST_DATA[i][14],
            TEST_DATA[i][13],
            TEST_DATA[i][12],
            TEST_DATA[i][11],
            TEST_DATA[i][10],
            TEST_DATA[i][9],
            TEST_DATA[i][8],
            TEST_DATA[i][7],
            TEST_DATA[i][6],
            TEST_DATA[i][5],
            TEST_DATA[i][4],
            TEST_DATA[i][3],
            TEST_DATA[i][2],
            TEST_DATA[i][1],
            TEST_DATA[i][0]
        };
        addra = i;
        # clock_period;
        addrb = i;
        # clock_period;
    end
end

endmodule
// End of MMU_test //
