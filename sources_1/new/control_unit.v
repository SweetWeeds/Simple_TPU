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
    input reset_n,  // Asynchronous reset
    input clk,      // Input clock
    input [ISA_BITS-1:0] instruction,   // 16-bit instruction
    output reg flag,            // Flag which represents completion of instruction
    output reg load_data,       // Load input data from unified buffer
    output reg load_weight,     // Load weight to MMU
    output reg write_data,      // Write input data at unified buffer
    output reg write_weight,    // Write weight at weight buffer
    output reg write_result,    // Write results to accumulator
    output reg mat_mul,         // MMU execution
    output reg [OPERAND_BITS-1:0] addra,    // Unified/Weight Buffer Read Address
    output reg [OPERAND_BITS-1:0] addrb,    // Unfiied/Weight Buffer Write Address
    output [127:0] dout
);

reg [MODE_BITS-1:0] current_mode1;  // Current major mode
reg [MODE_BITS-1:0] current_mode2;  // Current minor mode
reg [OPERAND_BITS-1:0] addr;
reg [7:0] buffer [0:15];

always @ (posedge clk) begin : INST_DECODE_LOGIC
    case (instruction[15:8])
        IDLE begin
            current_mode1  <= M1_IDLE_STATE;
            current_mode2  <= 4'h0;
        end
        LOAD_DATA begin
            // Load data values to data-fifo. (LOAD_DATA: 4-cycles)
            case (current_mode1)
                M1_LOAD_DATA_STATE begin
                    if (current_mode2 < 4'h3 && flag == 1'b0) begin
                        // Go next minor state.
                        current_mode1  <= current_mode1;
                        current_mode2  <= current_mode2 + 1;
                    end else begin
                        // Init minor state.
                        current_mode1  <= current_mode1;
                        current_mode2  <= 4'h0;
                    end
                default begin
                    current_mode1  <= M1_LOAD_DATA_STATE;
                    current_mode2  <= 4'h0;
                end
            endcase
        end
        WRITE_DATA, WRITE_WEIGHT begin
            // Write data to unified buffer. (WRITE_DATA: 17-cycles)
            // Write weight to weight buffer. (WRITE_WEIGHT: 17-cycles)
            case (current_mode1)
                M1_WRITE_DATA_STATE, M1_WRITE_WEIGHT_STATE begin
                    
                end
            endcase
        end
        LOAD_WEIGHT, MAT_MUL, WRITE_RESLUT begin
            // Load weight values to MMU. (LOAD_WEIGHT: 16-cycles)
            // Execute Matrix-Multiplication. (MAT_MUL: 16-cycles)
            // Write result to unified buffer. (WRITE_RESULT: 16-cycles)
            case (current_mode1)
                M1_LOAD_WEIGHT_STATE; M1_MAT_MUL_STATE; M1_WRITE_DATA_STATE begin
                    if (current_mode2 < 4'h15 && flag == 1'b0) begin
                        // Go next minor state.
                        current_mode1  <= current_mode1;
                        current_mode2  <= current_mode2 + 1;
                    end else begin
                        // Init minor state.
                        current_mode1  <= current_mode1;
                        current_mode2  <= 4'h0;
                    end
                end
                default begin
                    current_mode1      <= current_mode1;
                    current_mode2      <= 4'h0;
                end
            endcase
        default begin
            // NOP
            current_mode1 <= current_mode1;
            current_mode2 <= current_mode2;
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
            mat_mul         = 1'b0;
            addra   = 8'h00;
            addrb   = 8'h00;
            dout    = 128'h0;
        end
        M1_LOAD_DATA_STATE begin
            if (current_mode2 < 4'h3) begin
                load_data   = 1'b1;
                flag        = 1'b0;
            end else if (current_mode2 == 4'h3) begin
                load_data   = 1'b1;
                flag        = 1'b1;
            end else begin
                load_data   = 1'b0;
                flag        = 1'b1;
            end
            load_weight     = 1'b0;
            write_data      = 1'b0;
            write_weight    = 1'b0;
            write_result    = 1'b0;
            mat_mul         = 1'b0;
            addra   = instruction[7:0];
            addrb   = 8'h00;
        end
        M1_LOAD_WEIGHT_STATE begin
            if (current_mode2 < 4'h15) begin
                load_weight     = 1'b1;
                flag            = 1'b0;
            end else if (current_mode2 == 4'h15) begin
                load_weight     = 1'b1;
                flag            = 1'b1;
            end else begin
                load_weight     = 1'b0;
                flag            = 1'b1;
            end
            load_data       = 1'b0;
            write_data      = 1'b0;
            write_weight    = 1'b0;
            write_result    = 1'b0;
            mat_mul         = 1'b0;
            addra   = instruction[7:0];
            addrb   = 8'h00;
        end
        M1_MAT_MUL_STATE begin
            if (current_mode2 < 4'h15) begin
                mat_mul         = 1'b1;
                flag            = 1'b0;
            end else if (current_mode2 == 4'h15) begin
                mat_mul         = 1'b1;
                flag            = 1'b1;
            end else begin
                mat_mul         = 1'b0;
                flag            = 1'b1;
            end
            load_data       = 1'b0;
            load_weight     = 1'b0;
            write_data      = 1'b0;
            write_weight    = 1'b0;
            write_result    = 1'b0;
            addra   = 8'h00;
            addrb   = 8'h00;
        end
        M1_WRITE_DATA_STATE begin
            if (current_mode2 < 4'h16) begin
                // cycle 1 ~ cycle 16: Write 8-bit data to buffer.
                mat_mul         = 1'b0;
                flag            = 1'b0;
                addrb           = 8'h0;
                buffer[current_mode2] = instruction[7:0];
            end else if (current_mode2 == 4'h16) begin
                // cycle 17: Write 128-bit data to memory.
                write_data  = 1'b1;
                flag        = 1'b1;
                addrb       = instruction[7:0];
                dout        = {
                                buffer[15], buffer[14], buffer[13], buffer[12],
                                buffer[11], buffer[10], buffer[9],  buffer[8],
                                buffer[7],  buffer[6],  buffer[5],  buffer[4],
                                buffer[3],  buffer[2],  buffer[1],  buffer[0]
                            }
            end else begin
                mat_mul         = 1'b0;
                flag            = 1'b1;
                addrb           = 8'h0;
            end
            flag            = 1'b0;
            load_data       = 1'b0;
            load_weight     = 1'b0;
            write_weight    = 1'b0;
            write_result    = 1'b0;
            mat_mul         = 1'b0;
            addra   = 8'h00;
        end
        M1_WRITE_WEIGHT_STATE begin
            flag            = 1'b0;
            load_data       = 1'b0;
            load_weight     = 1'b0;
            write_data      = 1'b0;
            write_weight    = 1'b1;
            write_result    = 1'b0;
            mat_mul         = 1'b0;
            addra   = 8'h00;
            addrb   = instruction[7:0];
        end
    endcase
end

endmodule
// End of CONTROL_UNIT //
