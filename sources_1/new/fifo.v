`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:00
// Design Name: First-in First-out Memory
// Module Name: FIFO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: FIFO
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FIFO #
(
    parameter FIFO_WIDTH = 16*8,
    parameter FIFO_DEPTH = 4
)
(
    input  reset_n,
    input  clk,
    input  en,
    input  [FIFO_WIDTH-1:0] din,
    output [FIFO_WIDTH-1:0] dout
);

integer i;

reg [FIFO_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

assign dout = fifo[FIFO_DEPTH-1];

always @ (posedge clk or negedge reset_n) begin : FIFO_LOGIC
    if (reset_n == 1'b0) begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo[i] <= 'd0;
        end
    end else if (en) begin
        fifo[0] <= din;
        for (i = 0; i < FIFO_DEPTH-1; i = i + 1) begin
            fifo[i + 1] <= fifo[i];
        end
    end
end

endmodule
// End of FIFO //
