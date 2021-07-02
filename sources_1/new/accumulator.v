`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:00
// Design Name: Accumulator
// Module Name: ACCUMULATOR
// Proiect Name: 
// Target Devices: 
// Tool Versions: 
// Description: FIFO (Width: 128-bit, depth: 256)
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ACCUMULATOR (
    input reset_n,      // Asynchronous reset (falling edge)
    input clk,          // Input clock
    input en,           // 0: pass-through, 1: accumulate
    input [319:0] din,  // 16x20b input data
    output reg [319:0] dout // 16x20b output data
);

always @ (posedge clk or negedge reset_n) begin : ACC_LOGIC
    if (reset_n == 1'b0) begin
        dout <= 320'd0;
    end else if (en) begin
        dout <= din;
    end
end

endmodule
// End of ACCUMULATOR //
