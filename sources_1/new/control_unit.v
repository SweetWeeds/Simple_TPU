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

`include "sa_share.v"

module CONTROL_UNIT (
    input reset_n;  // Asynchronous reset
    input clk;      // Input clock
    input [ISA_BITS-1:0] instruction;   // 16-bit instruction
    output reg flag;            // Flag which represents completion of instruction
    output reg load_data;       // Load input data from unified buffer
    output reg load_weight;     // Load weight to MMU
    output reg write_data;      // Write input data at unified buffer
    output reg write_weight;    // Write weight at weight buffer
    output reg write_result;    // Write results to accumulator
    output reg mat_mul;         // MMU execution
    output reg [OPERAND_BITS-1:0] addra;    // Unified Buffer Read Address
    output reg [OPERAND_BITS-1:0] addrb;    // Weight Buffer Write Address
);

reg [MODE_BITS-1:0] current_mode1;  // Current major mode
reg [MODE_BITS-1:0] current_mode2;  // Current minor mode
reg [MODE_BITS-1:0] next_mode1;     // Next major mode
reg [MODE_BITS-1:0] next_mode2;     // Next minor mode
reg [OPERAND_BITS-1:0] addr;
reg [127:0] data;

always @ (posedge clk or negedge reset_n) begin : NEXT_STATE
    if (reset_n == 1'b0) begin
        current_mode1 <= M1_IDLE_STATE;
        current_mode2 <= 4'h0;
    end else begin
        current_mode1 <= next_mode1;
        current_mode2 <= next_mode2;
    end
end

always @ (instruction) begin : INST_DECODE_LOGIC
    case (instruction[15:8])
        IDLE begin
            next_mode1 = M1_IDLE_STATE;
            next_mode2 = 4'h0;
        end
        LOAD_DATA begin
            // Load data values to data-fifo. (LOAD_DATA: 4-cycles)
            if (next_mode2 < 4'h3 && flag == 1'b0) begin
                // Go next minor state.
                next_mode1  = next_mode1;
                next_mode2  = next_mode2 + 1;
            end else begin
                // Init minor state.
                next_mode1  = next_mode1;
                next_mode2  = 4'h0;
            end
        end
        WRITE_DATA, WRITE_WEIGHT begin
            // Write data to unified buffer. (WRITE_DATA: 17-cycles)
            // Write weight to weight buffer. (WRITE_WEIGHT: 17-cycles)
            
        end
        LOAD_WEIGHT; MAT_MUL; WRITE_RESLUT begin
            // Load weight values to MMU. (LOAD_WEIGHT: 16-cycles)
            // Execute Matrix-Multiplication. (MAT_MUL: 16-cycles)
            // Write result to unified buffer. (WRITE_RESULT: 16-cycles)
            case (current_mode1)
                M1_LOAD_WEIGHT_STATE; M1_MAT_MUL_STATE; M1_WRITE_DATA_STATE begin
                    if (next_mode2 < 4'h15 && flag == 1'b0) begin
                        // Go next minor state.
                        next_mode1  = next_mode1;
                        next_mode2  = next_mode2 + 1;
                    end else begin
                        // Init minor state.
                        next_mode1  = next_mode1;
                        next_mode2  = 4'h0;
                    end
                end
                default begin
                    next_mode1      = next_mode1;
                    next_mode2      = 4'h0;
                end
            endcase
        default begin
            // NOP
            next_mode1 = next_mode1;
            next_mode2 = next_mode2;
        end
    endcase
end

always @ (current_mode1 or current_mode2) begin : OUTPUT_LOGIC
    case (current_mode1)
        M1_IDLE_STATE begin
            flag            = 1'b0;
            load_data       = 1'b0;
            load_weight     = 1'b0;
            write_data      = 1'b0;
            write_weight    = 1'b0;
            write_result    = 1'b0;
            mat_mul = 1'b0;
            addra   = 8'h00;
            addrb   = 8'h00;
        end
        M1_LOAD_DATA_STATE begin
            if (current_mode2 == 4'h0) begin
                addra = instruction[7:0];
            end else begin
                addra = instruction
            end
        end
        M1_LOAD_WEIGHT_STATE begin
            
        end
        M1_MAT_MUL_STATE begin
            
        end
        M1_WRITE_DATA_STATE begin
            
        end
        M1_WRITE_WEIGHT_STATE begin
            
        end
    endcase
end

endmodule
// End of CONTROL_UNIT //
