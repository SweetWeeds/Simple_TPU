//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/04 14:52:20
// Design Name: 
// Module Name: Led
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


module Led(
    input wire [31:0]PS_2_PL_0_tri_o,
    input wire [31:0]PS_2_PL_1_tri_o, 
    
    output reg [31:0]PL_2_PS_0_tri_i,
    output reg [31:0]PL_2_PS_1_tri_i,
    output reg [1:0] led
    );

    always @ (*) begin
        led[0] <= PS_2_PL_0_tri_o[0];
        led[1] <= PS_2_PL_1_tri_o[0];

        PL_2_PS_0_tri_i <= PS_2_PL_0_tri_o + 4'b1000;
        PL_2_PS_1_tri_i <= PS_2_PL_1_tri_o + 4'b1000;
    end
    
endmodule
