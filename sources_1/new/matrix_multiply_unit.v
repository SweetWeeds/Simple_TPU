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
// Dependencies: pe.v, adder.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module MMU (
    input reset_n,
    input clk,
    input wen,
    input [127:0] ain,  //input signed [7:0] ain [0:15],
    input [127:0] win,  //input signed [7:0] win [0:15],
    output signed [319:0] aout //output signed [19:0] aout [0:15]
);

wire signed [7:0] wout [0:15][0:15];            // Weight output
wire signed [15:0] mul_result_reg [0:15][0:15]; // Multiplication results

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
                PE PE0 (
                    .reset_n(reset_n),
                    .clk(clk),
                    .wen(wen),
                    .ain(ain[(i + 1) * 8 - 1 : i * 8]),
                    .win(wout[i + 1][j]),
                    .wout(wout[i][j]),
                    .aout(mul_result_reg[i][j])
                );
            end
        end
    end
endgenerate

// Instantiation of ADDER_4_16b_20b modules.
generate
    for (genvar j = 15; j >= 0; j = j - 1) begin
        ADDER_4_16b_20b ADDER0 (
            .ain(
                {
                    mul_result_reg[15][j],
                    mul_result_reg[14][j],
                    mul_result_reg[13][j],
                    mul_result_reg[12][j],
                    mul_result_reg[11][j],
                    mul_result_reg[10][j],
                    mul_result_reg[9][j],
                    mul_result_reg[8][j],
                    mul_result_reg[7][j],
                    mul_result_reg[6][j],
                    mul_result_reg[5][j],
                    mul_result_reg[4][j],
                    mul_result_reg[3][j],
                    mul_result_reg[2][j],
                    mul_result_reg[1][j],
                    mul_result_reg[0][j]
                }
            ),
            .aout(aout[(j + 1) * 20 - 1 : j * 20])
        );
    end
endgenerate

endmodule
// End of MMU //
