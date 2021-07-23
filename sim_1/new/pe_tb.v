`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/29 16:50:39
// Design Name: Processing Element Testbench
// Module Name: PE_test
// Project Name: Systolic Array
// Target Devices: 
// Tool Versions: Vivado 2020.2
// Description: 
// 
// Dependencies: pe.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PE_test;

`include "../../sa_share.v"

parameter i = 0;

reg reset_n = 1'b1, clk, wen = 1'b1;
reg [7:0] ain[3:0], win;
wire [19:0] wout[3:0], aout[3:0];

PE PE1 (.reset_n(reset_n), .clk(clk), .wen(wen), .ain(ain[0]), .win(win),     .wout(wout[1]));
PE PE2 (.reset_n(reset_n), .clk(clk), .wen(wen), .ain(ain[1]), .win(wout[1]), .wout(wout[2]));
PE PE3 (.reset_n(reset_n), .clk(clk), .wen(wen), .ain(ain[2]), .win(wout[2]), .wout(wout[3]));
PE PE4 (.reset_n(reset_n), .clk(clk), .wen(wen), .ain(ain[3]), .win(wout[3]), .wout());

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
    
    // Load weight
    wen = 1'b1;
    win = 8'sd1;
    # clock_period;
    win = 8'sd2;
    # clock_period;
    win = 8'sd3;
    # clock_period;
    win = 8'sd4;
    # clock_period;
    wen = 1'b0;

    // Input activation values
    ain[0] = 8'sd9;
    ain[1] = 8'sd8;
    ain[2] = 8'sd7;
    ain[3] = 8'sd6;
end

endmodule
// End of PE_test //
