`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/30 14:28:26
// Design Name: 
// Module Name: mmu_tb
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


module MMU_test;

// Parameters
parameter  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS / 1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;
integer i = 0, j = 0;

// regs & wires
reg reset_n = 1'b1, clk, wen = 1'b1;
reg [7:0] ain [0:15], win [0:15];
wire [19:0] aout [0:15];

// Instantiation
MMU MMU0 (
    .reset_n(reset_n),
    .clk(clk),
    .wen(wen),
    .ain({ain[15], ain[14], ain[13], ain[12], ain[11], ain[10], ain[9], ain[8],
        ain[7], ain[6], ain[5], ain[4], ain[3], ain[2], ain[1], ain[0]}),
    .win({win[15], win[14], win[13], win[12], win[11], win[10], win[9], win[8],
        win[7], win[6], win[5], win[4], win[3], win[2], win[1], win[0]}),
    .aout({aout[15], aout[14], aout[13], aout[12], aout[11], aout[10], aout[9], aout[8],
        aout[7], aout[6], aout[5], aout[4], aout[3], aout[2], aout[1], aout[0]})
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

    // Load weights and set activation
    for (i = 0; i < 16; i = i + 1) begin
        ain[i] = - (i + 1);
        for (j = 0; j < 16; j = j + 1) begin
            win[j] = j + 1;
        end
        # clock_period;
    end
    wen = 1'b0; // disable weight_load signal
    # clock_period;
end

endmodule
// End of MMU_test //
