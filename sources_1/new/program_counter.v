`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/23 14:13:00
// Design Name: Program Counter
// Module Name: PROGRAM_COUNTER
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: 
// 
// Dependencies: bram.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PROGRAM_COUNTER # 
(
    parameter integer IS_TESTBENCH = 0,
    parameter integer PC_DEPTH = 1024,
    parameter integer INST_BITS = 128,
    parameter INIT_FILE = ""
)
(
    input  wire clk,
    input  wire reset_n,
    input  wire flag,
    input  wire force_inst,
    output wire [INST_BITS-1:0] instruction,
    output reg  init_inst_pulse
);

function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

reg  [clogb2(PC_DEPTH-1)-1:0] counter;
reg  flag_ff, force_inst_ff;
wire flag_pulse, force_inst_pulse;

assign flag_pulse = ~flag_ff && flag;
assign force_inst_pulse = ~force_inst_ff && force_inst;


BRAM # (
    .RAM_WIDTH(INST_BITS),
    .RAM_DEPTH(PC_DEPTH),
    .IS_TESTBENCH(IS_TESTBENCH),
    .INIT_FILE(INIT_FILE)
) ISA_MEMORY (
    .clk(clk),
    .wea(),
    .enb(flag_pulse || force_inst_pulse),
    .addra(),
    .addrb(counter),
    .dina(),
    .doutb(instruction)
);


always @ (posedge clk) begin : FLAG_PULSE
    if (reset_n == 1'b0) begin
        flag_ff <= 1'b0;
        force_inst_ff <= 1'b0;
    end else begin
        flag_ff <= flag;
        force_inst_ff <= force_inst;
    end
end


always @ (posedge clk) begin : PC_LOGIC
    if (reset_n == 1'b0) begin
        counter <= 0;
        init_inst_pulse <= 1'b0;
    end else if (flag_pulse) begin
        if (counter != PC_DEPTH-1) begin
            counter <= counter + 1;
            init_inst_pulse <= 1'b1;
        end
    end else begin
        init_inst_pulse <= 1'b0;
    end
end


endmodule
