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
    output signed [19:0] aout
);

wire signed [15:0] stage1 [0:15];
wire signed [16:0] stage2 [0:7];
wire signed [17:0] stage3 [0:3];
wire signed [18:0] stage4 [0:1];

// Assignments
generate
    // Stage1
    for (genvar i = 15; i >= 0; i = i - 1) begin
        assign stage1[i] = ain[(i + 1) * 16 - 1 : i * 16];
    end
    // Stage2
    for (genvar i = 7; i >= 0; i = i - 1) begin
        assign stage2[i] = stage1[i * 2 + 1] + stage1[i * 2];
    end
    // Stage3
    for (genvar i = 3; i >= 0; i = i - 1) begin
        assign stage3[i] = stage2[i * 2 + 1] + stage2[i * 2];
    end
    // Stage 4
    assign stage4[1] = stage3[3] + stage3[2];
    assign stage4[0] = stage3[1] + stage3[0];
    // Activation out
    assign aout = stage4[1] + stage4[0];
endgenerate

endmodule

// End of ADDER_16b-20b //