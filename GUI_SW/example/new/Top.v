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


module TOP(
    //input wire clk, resetn,

    output reg [2:0] led
    );

    wire [31:0]PL_2_PS_0_tri_i;
    wire [31:0]PL_2_PS_1_tri_i;
    wire [31:0]PS_2_PL_0_tri_o;
    wire [31:0]PS_2_PL_1_tri_o;

    wire [1:0] led_in;

    tutorial_wrapper wrapper(
        .PL_2_PS_0_tri_i(PL_2_PS_0_tri_i),
        .PL_2_PS_1_tri_i(PL_2_PS_1_tri_i),
        .PS_2_PL_0_tri_o(PS_2_PL_0_tri_o),
        .PS_2_PL_1_tri_o(PS_2_PL_1_tri_o)
    );

    Led PL_led(
        .PL_2_PS_0_tri_i(PL_2_PS_0_tri_i),
        .PL_2_PS_1_tri_i(PL_2_PS_1_tri_i),
        .PS_2_PL_0_tri_o(PS_2_PL_0_tri_o),
        .PS_2_PL_1_tri_o(PS_2_PL_1_tri_o),
        .led(led_in)
    );


    always @ (*)begin
        led[2] <= 1'b1;
        led[1:0] <= led_in;
    end

endmodule
