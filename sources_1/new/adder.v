`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:46
// Design Name: Adder for 16 x 16-bit to 20-bit
// Module Name: ADDER_16b_20b
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Processing Element
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ADDER_16b_20b (
    input [255:0] ain,
    output reg signed [19:0] aout
);

wire signed [15:0] activation [0:15];

generate
    // Assignments
    for (genvar i = 15; i >= 0; i = i - 1) begin
        assign activation[i] = ain[(i + 1) * 16 - 1 : i * 16];
    end
endgenerate

/**
 * Block name: ADDER_LOGIC
 * Type: Combinational Logic
 * Description: Add 16 16-bit input and return 20-bit output.
 */
always @ (ain) begin : ADDER_LOGIC
    aout = activation[15] + activation[14] + activation[13] + activation[12]
         + activation[11] + activation[10] + activation[9] + activation[8]
         + activation[7] + activation[6] + activation[5] + activation[4]
         + activation[3] + activation[2] + activation[1] + activation[0];
end

endmodule