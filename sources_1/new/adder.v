`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:46
// Design Name: Adder for 16 x 16-bit to 20-bit
// Module Name: ADDER_4_16b_20b
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Processing Element
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ADDER_4_16b_20b (
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
always @ (activation[15] or activation[14] or activation[13] or activation[12]
         or activation[11] or activation[10] or activation[9] or activation[8]
         or activation[7] or activation[6] or activation[5] or activation[4]
         or activation[3] or activation[2] or activation[1] or activation[0]) begin : ADDER_LOGIC
    aout = activation[15] + activation[14] + activation[13] + activation[12]
         + activation[11] + activation[10] + activation[9] + activation[8]
         + activation[7] + activation[6] + activation[5] + activation[4]
         + activation[3] + activation[2] + activation[1] + activation[0];
end

endmodule

// End of ADDER_16b-20b //