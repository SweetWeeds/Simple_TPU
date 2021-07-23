`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/01 12:20:19
// Design Name: First-in First-out test bench
// Module Name: fifo_tb.v
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Testbench for fifo module.
// 
// Dependencies: fifo_16x16x20b.v, fifo_256x16x8b.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_test;

`include "../../sa_share.v"

// Parameters
integer i = 0, j = 0;

// regs & wires
reg reset_n = 1'b1, clk, en = 1'b1;
reg [19:0] din0 [0:15];
reg [7:0]  din1 [0:15];
wire [19:0] dout0 [0:15];
wire [7:0]  dout1 [0:15];

// Instantiation
FIFO_16x16x20b FIFO0 (
    .reset_n(reset_n),
    .clk(clk),
    .en(en),
    .din(
        {
            din0[0],
            din0[1],
            din0[2],
            din0[3],
            din0[4],
            din0[5],
            din0[6],
            din0[7],
            din0[8],
            din0[9],
            din0[10],
            din0[11],
            din0[12],
            din0[13],
            din0[14],
            din0[15]
        }
    ),
    .dout(
        {
            dout0[0],
            dout0[1],
            dout0[2],
            dout0[3],
            dout0[4],
            dout0[5],
            dout0[6],
            dout0[7],
            dout0[8],
            dout0[9],
            dout0[10],
            dout0[11],
            dout0[12],
            dout0[13],
            dout0[14],
            dout0[15]
        }
    )
);

FIFO_256x16x8b FIFO1 (
    .reset_n(reset_n),
    .clk(clk),
    .en(en),
    .din(
        {
            din1[0],
            din1[1],
            din1[2],
            din1[3],
            din1[4],
            din1[5],
            din1[6],
            din1[7],
            din1[8],
            din1[9],
            din1[10],
            din1[11],
            din1[12],
            din1[13],
            din1[14],
            din1[15]
        }
    ),
    .dout(
        {
            dout1[0],
            dout1[1],
            dout1[2],
            dout1[3],
            dout1[4],
            dout1[5],
            dout1[6],
            dout1[7],
            dout1[8],
            dout1[9],
            dout1[10],
            dout1[11],
            dout1[12],
            dout1[13],
            dout1[14],
            dout1[15]
        }
    )
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

    // Test FIFO_16x16x20b
    for (j = 0; j < 30; j = j + 1) begin
        for (i = 0; i < 16; i = i + 1) begin
            din0[i] = - (i + 1) * (j + 1);
        end
        # clock_period;
    end
    en = 1'b0; // disable weight_load signal
    for (j = 0; j < 30; j = j + 1) begin
        for (i = 0; i < 16; i = i + 1) begin
            din0[i] = - (i + 1) * (j + 1);
        end
        # clock_period;
    end
end

endmodule
// End of MMU_test //
