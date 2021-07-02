`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/01 15:54:00
// Design Name: 
// Module Name: controller
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

module CONTROL_UNIT (
    input [INST_BITS-1:0] instruction,   // 16-bit instruction
    output reg load_data,       // Load input data from unified buffer
    output reg load_weight,     // Load weight to MMU
    output reg write_data,      // Write input data at unified buffer
    output reg write_weight,    // Write weight at weight buffer
    output reg write_result,    // Write results to accumulator
    output reg mat_mul,         // MMU execution
    output reg acc,             // Accumulation execution
    output reg [ADDR_BITS-1:0] addra,    // Unified/Weight Buffer Read Address
    output reg [ADDR_BITS-1:0] addrb,    // Unfiied/Weight Buffer Write Address
    output reg [OPERAND_BITS-1:0] dout
);

`include "sa_share.v"

wire [OPCODE_BITS-1:0]   opcode;     // Operation Code
wire [OPERAND_BITS-1:0]  operand;    // 16x8b datas
wire [ADDR_BITS-1:0]     addr;       // Address of RAM(Unified/Weight Buffer)

// Continuous-Assignments
assign opcode = instruction[OPCODE_FROM:OPCODE_TO];
assign operand = instruction[OPERAND_FROM:OPERAND_TO];
assign addr = instruction[ADDR_FROM:ADDR_TO];

always @ (instruction) begin : OUTPUT_LOGIC
    case (opcode)
    IDLE_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = 8'h00;
        dout        = 128'd0;
    end
    LOAD_DATA_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b1;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = addr;
        dout        = 128'd0;
    end
    LOAD_WEIGHT_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b1;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = addr;
        dout        = 128'd0;
    end
    MAT_MUL_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b1;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = 8'h00;
        dout        = 128'd0;
    end
    MM_AND_LOAD_DATA_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b1;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b1;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = addr;
        dout        = 128'd0;
    end
    WRITE_DATA_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b1;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = addr;
        addrb       = 8'h0;
        dout        = operand;
    end
    WRITE_WEIGHT_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b1;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = addr;
        addrb       = 8'h0;
        dout        = operand;
    end
    ACCUMULATION_INST : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b1;
        addra       = 8'h00;
        addrb       = 8'h00;
        dout        = 128'd0;        
    end
    default : begin
        //flag        = 1'b0;
        load_data   = 1'b0;
        load_weight = 1'b0;
        write_data  = 1'b0;
        write_weight    = 1'b0;
        write_result    = 1'b0;
        mat_mul     = 1'b0;
        acc         = 1'b0;
        addra       = 8'h00;
        addrb       = 8'h00;
        dout        = 128'd0;
    end
    endcase
end

endmodule
// End of CONTROL_UNIT //
