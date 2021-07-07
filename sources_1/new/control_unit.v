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
    input reset_n,
    input clk,
    input [INST_BITS-1:0] instruction,   // 16-bit instruction
    output reg flag,            // flag to indicate whether the command is executed
    output reg read_ub,
    output reg write_ub,
    output reg read_wb,
    output reg write_wb,
    output reg read_acc,
    output reg write_acc,
    output reg data_fifo_en,
    output reg mmu_load_weight_en,
    output reg weight_fifo_en,
    output reg mm_en,
    output reg acc_en,
    output reg [ADDRA_BITS-1:0] addra,    // Unified/Weight Buffer Read Address
    output reg [ADDRB_BITS-1:0] addrb,    // Unfiied/Weight Buffer Write Address
    output reg [OPERAND_BITS-1:0] dout
);

`include "sa_share.v"

reg [OPCODE_BITS-1:0]   opcode;     // Operation Code
reg [1:0]               minor_state;

always @ (posedge clk or negedge reset_n) begin : INPUT_LOGIC
    if (reset_n == 1'b0) begin
        // Asynchronous reset
        opcode      <= IDLE_INST;
        minor_state <= 0;
    end else if (flag == 1'b1) begin
        // Get next instruction
        opcode  <= instruction[OPCODE_FROM:OPCODE_TO];
        addra   <= instruction[ADDRA_FROM:ADDRA_TO];
        addrb   <= instruction[ADDRB_FROM:ADDRB_TO];
        dout    <= instruction[OPERAND_FROM:OPERAND_TO];
        minor_state <= 0;
    end else begin
        // Next-state logic
        minor_state <= minor_state + 1;
    end
end

always @ (opcode or minor_state or addra or addrb or dout) begin : OUTPUT_LOGIC
    case (opcode)
    // IDLE_INST (1-cycle)
    IDLE_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // DATA_FIFO_INST (1-cycle)
    DATA_FIFO_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b1;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // WEIGHT_FIFO_INST (1-cycle)
    WEIGHT_FIFO_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b1;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // WRITE_DATA_INST (1-cycle)
    WRITE_DATA_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b1;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // WRITE_WEIGHT_INST (1-cycle)
    WRITE_WEIGHT_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b1;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // WRITE_RESULT_INST (2-cycle)
    //WRITE_RESULT_INST : begin
    //    if (minor_state == 2'd0) begin
    //        // 1. Read result data from accumulator.
    //        flag            = 1'b0;
    //        read_ub         = 1'b0;
    //        write_ub        = 1'b0;
    //        read_wb         = 1'b0;
    //        write_wb        = 1'b0;
    //        read_acc        = 1'b1;
    //        write_acc       = 1'b0;
    //        data_fifo_en    = 1'b0;
    //        weight_fifo_en  = 1'b0;
    //    end else begin
    //        // 2. Write result data to UB.
    //        flag            = 1'b1;
    //        read_ub         = 1'b0;
    //        write_ub        = 1'b0;
    //        read_wb         = 1'b0;
    //        write_wb        = 1'b0;
    //        read_acc        = 1'b0;
    //        write_acc       = 1'b0;
    //        data_fifo_en    = 1'b0;
    //        weight_fifo_en  = 1'b0;
    //        dout            = 
    //    end
    //end
    // LOAD_DATA_INST (1-cycle)
    LOAD_DATA_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b1;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b1;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // LOAD_WEIGHT_INST (1-cycle)
    LOAD_WEIGHT_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b1;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b1;
        weight_fifo_en  = 1'b1;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    // MAT_MUL_INST (1-cycle)
    MAT_MUL_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b1;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b1;
        acc_en          = 1'b0;
    end
    // MAT_MUL_INST_ACC (1-cycle)
    MAT_MUL_ACC_INST : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b1;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b1;
        acc_en          = 1'b1;
    end
    default : begin
        flag            = 1'b1;
        read_ub         = 1'b0;
        write_ub        = 1'b0;
        read_wb         = 1'b0;
        write_wb        = 1'b0;
        read_acc        = 1'b0;
        write_acc       = 1'b0;
        data_fifo_en    = 1'b0;
        mmu_load_weight_en = 1'b0;
        weight_fifo_en  = 1'b0;
        mm_en           = 1'b0;
        acc_en          = 1'b0;
    end
    endcase
end

endmodule
// End of CONTROL_UNIT //
