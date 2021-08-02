`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/23 14:13:00
// Design Name: Instruction Buffer
// Module Name: INSTRUCTION_BUFFER
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

module INSTRUCTION_BUFFER # 
(
    parameter integer PC_DEPTH = 1024,
    parameter integer ADDR_BITS = 10,
    parameter integer INST_BITS = 128,
    parameter INIT_FILE = ""
)
(
    input  wire clk,
    input  wire reset_n,
    input  wire flag,
    input  wire force_inst,
    input  wire wea,
    // Start of IB Control signals
    input  wire ib_mode,    // IB Mode (1: Wrap, 0: Procedural)
    input  wire ib_en,      // IB Enable (1: Enable, 0: Disable)
    input  wire ib_incr,    // Counter increment (1: Increase, 0: Decrease)
    input  wire ib_jmp,     // Jump (Go to start address('start_addr'))
    input  wire [ADDR_BITS-1:0] start_addr, // Start address of IB
    input  wire [ADDR_BITS-1:0] end_addr,   // End address of IB
    output reg  complete_flag,
    // End of IB Cotnrol signals
    input  wire [INST_BITS-1:0] din,
    input  wire [ADDR_BITS-1:0] addra,
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
wire [INST_BITS-1:0] doutb;

assign flag_pulse = ~flag_ff && flag;
assign force_inst_pulse = ~force_inst_ff && force_inst;
assign instruction = ib_en ? doutb : 0;

BRAM # (
    .RAM_WIDTH(INST_BITS),
    .RAM_DEPTH(PC_DEPTH),
    .INIT_FILE(INIT_FILE)
) ISA_MEMORY (
    .clk(clk),
    .wea(wea),
    .enb(flag_pulse || force_inst_pulse),
    .addra(addra),
    .addrb(counter),
    .dina(din),
    .doutb(doutb)
);

always @ (posedge clk) begin : FLAG_PULSE
    if (reset_n == 1'b0) begin
        flag_ff <= 1'b0;
        force_inst_ff <= 1'b0;
    end else if (ib_en) begin
        flag_ff <= flag;
        force_inst_ff <= force_inst;
    end
end

always @ (posedge clk) begin : PC_LOGIC
    if (reset_n == 1'b0) begin
        counter <= start_addr;
        init_inst_pulse <= 1'b0;
        complete_flag <= 1'b0;
    end else if (ib_en) begin
        if (flag_pulse || force_inst_pulse) begin
            // Determine next 'counter' value
            if (ib_jmp) begin
                // Jump counter
                //  Go to 'start_addr' when increasing.
                //  Go to 'end_addr' when decreasing.
                if (ib_incr)
                    counter <= start_addr;
                else
                    counter <= end_addr;
                complete_flag <= 1'b0;
            end else begin
                if (ib_incr) begin
                    // Counter increase
                    if (counter != end_addr) begin
                        // Less than 'end_addr'
                        counter <= counter + 1;
                        complete_flag <= 1'b0;
                    end else begin
                        // Reach boundary
                        if (ib_mode) begin
                            // Wrap
                            counter <= start_addr;
                            complete_flag <= 1'b0;
                        end else begin
                            // Procedural
                            counter <= counter;
                            complete_flag <= 1'b1;
                        end
                    end
                end else begin
                    // Counter decrease
                    if (counter != start_addr) begin
                        // Larger than 'start_addr'
                        counter <= counter - 1;
                        complete_flag <= 1'b0;
                    end else begin
                        // Reach boundary
                        if (ib_mode) begin
                            // Wrap
                            counter <= end_addr;
                            complete_flag <= 1'b0;
                        end else begin
                            // Procedural
                            counter <= counter;
                            complete_flag <= 1'b1;
                        end
                    end
                end
            end
            init_inst_pulse <= 1'b1;
        end else begin
            init_inst_pulse <= 1'b0;
        end
    end
end


endmodule
