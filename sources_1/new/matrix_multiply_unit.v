`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/30 13:00
// Design Name: Matrix Multiply Unit
// Module Name: MMU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 16x16 8-bit Matrix Multiply Unit
// 
// Dependencies: pe.v 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`include "pe.v"

module MMU (
    input reset_n,
    input clk,
    input wen,
    input [127:0] ain,  //input signed [7:0] ain [0:15],
    input [127:0] win,  //input signed [7:0] win [0:15],
    output signed [319:0] aout //output signed [19:0] aout [0:15]
);

wire signed [7:0] wout [0:15][0:15];  // Weight output
wire signed [15:0] mul_result_reg [0:15][0:15];
wire signed [19:0] aout_reg [0:15];

// Instantiation of PE modules.
generate
    for (genvar i = 15; i >= 0; i = i - 1) begin
        for (genvar j = 15; j >= 0; j = j - 1) begin
            if (i == 15) begin
                PE PE0 (
                    .reset_n(reset_n),
                    .clk(clk),
                    .wen(wen),
                    .ain(ain[(i + 1) * 8 - 1 : i * 8]),
                    .win(win[(j + 1) * 8 - 1 : j * 8]),
                    .wout(wout[i][j]),
                    .aout(mul_result_reg[i][j])
                );
            end else begin
                PE PE1 (
                    .reset_n(reset_n),
                    .clk(clk),
                    .wen(wen),
                    .ain(ain[(i + 1) * 8 - 1 : i * 8]),
                    .win(wout[i - 1][j]),
                    .wout(wout[i][j]),
                    .aout(mul_result_reg[i][j])
                );
            end
        end
    end
endgenerate

// Instantiation of ADDER_16b_20b modules.
generate
    for (genvar i = 15; i >= 0; i = i - 1) begin
        ADDER_16b_20b ADDER (
            .ain(
                {
                    mul_result_reg[i][15],
                    mul_result_reg[i][14],
                    mul_result_reg[i][13],
                    mul_result_reg[i][12],
                    mul_result_reg[i][11],
                    mul_result_reg[i][10],
                    mul_result_reg[i][9],
                    mul_result_reg[i][8],
                    mul_result_reg[i][7],
                    mul_result_reg[i][6],
                    mul_result_reg[i][5],
                    mul_result_reg[i][4],
                    mul_result_reg[i][3],
                    mul_result_reg[i][2],
                    mul_result_reg[i][1],
                    mul_result_reg[i][0]
                }
            ),
            .aout(aout_reg[i])
        );
    end
endgenerate

endmodule