`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:00
// Design Name: First-in First-out Memory
// Module Name: FIFO_4x16x8b
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: FIFO (Width: 128-bit, depth: 4)
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FIFO_4x16x8b (
    input reset_n,
    input clk,
    input en,
    input [127:0] din,
    output [127:0] dout
);

integer i;

reg [127:0] fifo [0:3];

assign dout = fifo[3];

always @ (posedge clk or negedge reset_n) begin : FIFO_LOGIC
    if (reset_n == 1'b0) begin
        for (i = 0; i < 4; i = i + 1) begin
            fifo[i] <= 128'd0;
        end
    end else if (en) begin
        fifo[0] <= din;
        for (i = 0; i < 3; i = i + 1) begin
            fifo[i + 1] <= fifo[i];
        end
    end
end

endmodule
// End of FIFO_4x16x8b //
