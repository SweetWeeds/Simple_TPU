`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/29 16:50:39
// Design Name: 
// Module Name: pe_tb
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


module PE_test;

parameter  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS/1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;

reg reset_n, clk, load_weight;
reg [7:0] ain, win, weight_out;
reg [19:0] out;

/**
 *  Clock signal generation.
 *  Clock is assumed to be initialized to 1'b0 at time 0.
 */
initial
begin : CLOCK_GENERATOR
    clk = 1'b0;
    forever
        # half_clock_period clk = ~clk;
end

PE PE1 (
    .reset_n(reset_n),          // Asynchronous reset signal
    .clk(clk),              // Input clock
    .load_weight(load_weight),      // control signal for load weight
    .ain(ain),        // First Input-data (8-bit) 
    .win(win)        // Input Weight (8-bit)
);

endmodule
