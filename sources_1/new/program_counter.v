`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/23 14:13:00
// Design Name: Program Counter
// Module Name: PROGRAM_COUNTER
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PROGRAM_COUNTER # 
(
    parameter INSTRUCTION_SIZE
)
(
    input clk,
    input reset_n,
    output wire [] instruction,

)

`include "../../sa_share.v"


endmodule
