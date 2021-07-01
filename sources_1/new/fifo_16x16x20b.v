`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:00
// Design Name: First-in First-out Memory
// Module Name: FIFO_16x16x20b
// Project Name: 
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

module FIFO_16x16x20b (
    input reset_n,
    input clk,
    input en,
    input [319:0] din,
    output [319:0] dout
);

integer i;

reg [319:0] fifo [0:15];

assign dout = fifo[15];

always @ (posedge clk) begin : FIFO_LOGIC
    if (reset_n == 1'b0) begin
        for (i = 0; i < 16; i = i + 1) begin
            fifo[i] <= 320'd0;
        end
    end else if (en) begin
        fifo[0] <= din;
        for (i = 0; i < 15; i = i + 1) begin
            fifo[i + 1] <= fifo[i];
        end
    end
end

endmodule
// End of FIFO_16x16x20b //
