`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/01 15:54:00
// Design Name: Control Unit
// Module Name: CONTROL_UNIT
// Project Name: Systolic Array
// Target Devices: ZCU102
// Tool Versions: Vivado 2020.2
// Description: Control unit of systolic array.
// 
// Dependencies: sa_share.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CONTROL_UNIT #
(
    parameter OPCODE_BITS          = 4,
    parameter UB_ADDRA_BITS        = 8,
    parameter UB_ADDRB_BITS        = 8,
    parameter WB_ADDRA_BITS        = 8,
    parameter WB_ADDRB_BITS        = 8,
    parameter ACC_ADDRA_BITS       = 6,
    parameter ACC_ADDRB_BITS       = 6,
    parameter OFFMEM_ADDRA_BITS    = 32,
    parameter OFFMEM_ADDRB_BITS    = 32,
    parameter INST_BITS    = OPCODE_BITS + OFFMEM_ADDRA_BITS + OFFMEM_ADDRB_BITS,
    parameter DIN_BITS     = 128,

    parameter OPCODE_FROM  = INST_BITS-1,                          // 148-1=147
    parameter OPCODE_TO    = OPCODE_FROM-OPCODE_BITS+1,            // 147-4+1=144
    parameter ADDRA_FROM   = OPCODE_TO-1,                          // 144-1=143
    parameter ADDRA_TO     = ADDRA_FROM-OFFMEM_ADDRA_BITS+1,       // 143-8+1=136
    parameter ADDRB_FROM   = ADDRA_TO-1,                   // 136-1=135
    parameter ADDRB_TO     = ADDRB_FROM-OFFMEM_ADDRB_BITS+1,      // 135-8+1=128

    parameter IDLE_INST               = 4'h0,
    parameter DATA_FIFO_INST          = 4'h1,
    parameter WEIGHT_FIFO_INST        = 4'h2,
    parameter AXI_TO_UB_INST          = 4'h3,
    parameter AXI_TO_WB_INST          = 4'h4,
    parameter UB_TO_DATA_FIFO_INST    = 4'h5,
    parameter UB_TO_WEIGHT_FIFO_INST  = 4'h6,
    parameter MAT_MUL_INST            = 4'h7,
    parameter MAT_MUL_ACC_INST        = 4'h8,
    parameter ACC_TO_UB_INST          = 4'h9,
    parameter UB_TO_AXI_INST          = 4'ha
)
(
    input  wire reset_n,
    input  wire clk,
    input  wire [INST_BITS-1:0] instruction,    // 68-bit instruction
    output reg  [1:0] axi_sm_mode,  // axi state machine mode
    output reg  axi_txn_en,
    input  wire inst_done,  // is 'din' data is valid
    input  wire [DIN_BITS-1:0] din, // 128-bit data input pin
    input  wire [DIN_BITS-1:0] rin, // 128-bit result data input pin
    input  wire [DIN_BITS-1:0] uin, // 128-bit UB's data input pin
    output wire idle_flag,  // flag for idle status (0: Working, 1: Idling)
    output reg  flag,   // flag to indicate whether the command is executed
    output reg  read_ub,
    output reg  write_ub,
    output reg  read_wb,
    output reg  write_wb,
    output reg  read_acc,
    output reg  write_acc,
    output reg  data_fifo_en,
    output reg  mmu_load_weight_en,
    output reg  weight_fifo_en,
    output reg  mm_en,
    output reg  acc_en,
    output reg  [UB_ADDRA_BITS-1:0]     ub_addra,   // Unified Buffer Write Address
    output reg  [UB_ADDRB_BITS-1:0]     ub_addrb,   // Unfiied Buffer Read Address
    output reg  [WB_ADDRA_BITS-1:0]     wb_addra,   // Weight Buffer Write Address
    output reg  [WB_ADDRB_BITS-1:0]     wb_addrb,   // Weight Buffer Read Address
    output reg  [ACC_ADDRA_BITS-1:0]    acc_addra,  // Accumulator Write Address
    output reg  [ACC_ADDRB_BITS-1:0]    acc_addrb,  // Accumulator Read Address
    output reg  [OFFMEM_ADDRA_BITS-1:0] offmem_addra,   // OFF-RAM Write Address
    output reg  [OFFMEM_ADDRB_BITS-1:0] offmem_addrb,   // OFF-RAM Read Address
    output reg  [DIN_BITS-1:0] dout
);

reg [OPCODE_BITS-1:0]   opcode;     // Operation Code
reg [1:0]               minor_state;
reg minor_state_mode;               // 0: For exact-cycle inst, 1: For n-cycle inst
reg [OFFMEM_ADDRA_BITS-1:0] addra;  // Write address buffer
reg [OFFMEM_ADDRA_BITS-1:0] addrb;  // Read address buffer
reg flag_buffer;

localparam [1:0] IDLE = 2'b00,
                 LOAD_DATA   = 2'b01,
                 STORE_DATA  = 2'b10;

assign idle_flag = (opcode == IDLE_INST) ? 1'b1 : 1'b0;

always @ (posedge clk) begin : INPUT_LOGIC
    if (reset_n == 1'b0) begin
        // Asynchronous reset
        opcode      <= IDLE_INST;
        minor_state <= 0;
        minor_state_mode <= 1'b0;
        flag    <= 1'b0;
    end else if (flag == 1'b1) begin
        // Get next instruction
        flag    <= 1'b0;
        opcode  <= instruction[OPCODE_FROM:OPCODE_TO];
        addra   <= instruction[ADDRA_FROM:ADDRA_TO];
        addrb   <= instruction[ADDRB_FROM:ADDRB_TO];
        minor_state <= 0;
        case (instruction[OPCODE_FROM:OPCODE_TO])
        AXI_TO_UB_INST, AXI_TO_WB_INST, UB_TO_AXI_INST : begin
            minor_state_mode <= 1'b1;
        end
        default : begin
            minor_state_mode <= 1'b0;
        end
        endcase
    end else begin
        // Next-state logic
        // Exception: AXI-Interface instructions -> These insts need n-cycles.
        // Therefore AXI insts use 'inst_done' flag for indicating that struction is done.
        if ((!minor_state_mode) || (minor_state_mode && minor_state == 'd0))
            minor_state <= minor_state + 1;
    end
end

always @ (negedge clk) begin : COMPLETE_FLAG
    case (opcode)
    ACC_TO_UB_INST, MAT_MUL_INST, MAT_MUL_ACC_INST : begin
        // 2-cycles
        if (minor_state == 1) begin
            $display("[%0t:CU:COMPLETE_FLAG] 2-cycles instruction copmlete.", $time);
            flag <= 1'b1;
        end
    end
    IDLE_INST, DATA_FIFO_INST, WEIGHT_FIFO_INST, UB_TO_DATA_FIFO_INST,
    UB_TO_WEIGHT_FIFO_INST : begin
        // 1-cycle
        if (minor_state == 0) begin
            $display("[%0t:CU:COMPLETE_FLAG] 1-cycles instruction copmlete.", $time);
            flag <= 1'b1;
        end
    end
    AXI_TO_UB_INST, AXI_TO_WB_INST, UB_TO_AXI_INST : begin
        // n-cycles
        if (inst_done == 1'b1) begin
            $display("[%0t:CU:COMPLETE_FLAG] n-cycles instruction copmlete.", $time);
            flag <= 1'b1;
        end
    end
    endcase
end


always @ (opcode or minor_state or addra or addrb or dout or inst_done or din or uin or rin) begin : OUTPUT_LOGIC
    case (opcode)
    // IDLE_INST (1-cycle)
    IDLE_INST : begin
        $display("[%0t:CU:OUTPUT_LOGIC] IDLE", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = 8'b0;
        wb_addra        = 8'b0;
        wb_addrb        = 8'b0;
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    // DATA_FIFO_INST (1-cycle)
    DATA_FIFO_INST : begin
        $display("[%0t:CU:OUTPUT_LOGIC] DATA_FIFO_INST", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = 8'b0;
        wb_addra        = 8'b0;
        wb_addrb        = 8'b0;
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    // WEIGHT_FIFO_INST (1-cycle)
    WEIGHT_FIFO_INST : begin
        $display("[%0t:CU:OUTPUT_LOGIC] WEIGHT_FIFO_INST", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = 8'b0;
        wb_addra        = 8'b0;
        wb_addrb        = 8'b0;
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    // AXI_TO_UB_INST (wait for data: n-cycles, write data to UB: 1-cycle)
    AXI_TO_UB_INST : begin
        if (inst_done == 1'b0) begin
            $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_UB_INST(0)", $time);
            axi_sm_mode     = LOAD_DATA;
            axi_txn_en      = 1'b1;
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
            ub_addra        = 8'h00;
            ub_addrb        = 8'h00;
            wb_addra        = 8'h00;
            wb_addrb        = 8'h00;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = addrb;
            dout            = 128'd0;
        end else begin
            $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_UB_INST(1)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
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
            ub_addra        = addra[UB_ADDRA_BITS-1:0];
            ub_addrb        = 8'h0;
            wb_addra        = 8'h0;
            wb_addrb        = 8'h0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = din;
        end
    end
    // AXI_TO_WB_INST (n-cycles)
    AXI_TO_WB_INST : begin
        if (inst_done == 1'b0) begin
            $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_WB_INST(0)", $time);
            axi_sm_mode     = LOAD_DATA;
            axi_txn_en      = 1'b1;
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
            ub_addra        = 8'h00;
            ub_addrb        = 8'h00;
            wb_addra        = 8'h00;
            wb_addrb        = 8'h00;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = addrb;
            dout            = 128'd0;
        end else begin
            $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_WB_INST(1)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
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
            ub_addra        = 8'b0;
            ub_addrb        = 8'b0;
            wb_addra        = addra[WB_ADDRA_BITS-1:0];
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = din;
        end
    end
    // UB_TO_DATA_FIFO_INST (1-cycle)
    UB_TO_DATA_FIFO_INST : begin
        $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_DATA_FIFO_INST", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = addrb[UB_ADDRB_BITS-1:0];
        wb_addra        = 8'b0;
        wb_addrb        = 8'b0;
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    // UB_TO_WEIGHT_FIFO_INST (1-cycle)
    UB_TO_WEIGHT_FIFO_INST : begin
        $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_WEIGHT_FIFO_INST", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = 8'b0;
        wb_addra        = 8'b0;
        wb_addrb        = addrb[UB_ADDRB_BITS-1:0];
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    // MAT_MUL_INST (1-cycle)
    MAT_MUL_INST : begin
        if (minor_state == 0) begin
            $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_INST(0)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b1;
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
            ub_addra        = 8'b0;
            ub_addrb        = addrb[UB_ADDRB_BITS-1:0];
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end else begin
            $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_INST(1)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b0;
            write_ub        = 1'b0;
            read_wb         = 1'b0;
            write_wb        = 1'b0;
            read_acc        = 1'b0;
            write_acc       = 1'b1;
            data_fifo_en    = 1'b1;
            mmu_load_weight_en = 1'b0;
            weight_fifo_en  = 1'b0;
            mm_en           = 1'b1;
            acc_en          = 1'b0;
            ub_addra        = 8'b0;
            ub_addrb        = 8'b0;
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = addra[ACC_ADDRA_BITS-1:0];
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end
    end
    // MAT_MUL_INST_ACC (1-cycle)
    MAT_MUL_ACC_INST : begin
        if (minor_state == 0) begin
            $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_ACC_INST(0)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b1;
            write_ub        = 1'b0;
            read_wb         = 1'b0;
            write_wb        = 1'b0;
            read_acc        = 1'b0;
            write_acc       = 1'b0;
            data_fifo_en    = 1'b0;
            mmu_load_weight_en = 1'b0;
            weight_fifo_en  = 1'b0;
            mm_en           = 1'b0;
            acc_en          = 1'b1;
            ub_addra        = 8'b0;
            ub_addrb        = addrb[UB_ADDRB_BITS-1:0];
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end else begin
            $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_ACC_INST(1)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b0;
            write_ub        = 1'b0;
            read_wb         = 1'b0;
            write_wb        = 1'b0;
            read_acc        = 1'b0;
            write_acc       = 1'b1;
            data_fifo_en    = 1'b1;
            mmu_load_weight_en = 1'b0;
            weight_fifo_en  = 1'b0;
            mm_en           = 1'b1;
            acc_en          = 1'b1;
            ub_addra        = 8'b0;
            ub_addrb        = 8'b0;
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = addra[ACC_ADDRA_BITS-1:0];
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end
    end
    // ACC_TO_UB_INST (n-cycles)
    ACC_TO_UB_INST : begin
        if (minor_state == 2'd0) begin
            $display("[%0t:CU:OUTPUT_LOGIC] ACC_TO_UB_INST(0)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b0;
            write_ub        = 1'b0;
            read_wb         = 1'b0;
            write_wb        = 1'b0;
            read_acc        = 1'b1;
            write_acc       = 1'b0;
            data_fifo_en    = 1'b0;
            mmu_load_weight_en = 1'b0;
            weight_fifo_en  = 1'b0;
            mm_en           = 1'b0;
            acc_en          = 1'b0;
            ub_addra        = 8'b0;
            ub_addrb        = 8'b0;
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = addrb[ACC_ADDRB_BITS-1:0];
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end else begin
            $display("[%0t:CU:OUTPUT_LOGIC] ACC_TO_UB_INST(1)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
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
            ub_addra        = addra[UB_ADDRA_BITS-1:0];
            ub_addrb        = 8'b0;
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = rin;
        end
    end
    // UB_TO_AXI_INST (n-cycles) : Unsigned-Buffer's data to AXI I/F
    UB_TO_AXI_INST : begin
        if (minor_state == 1'b0) begin
            // Read UB data.
            $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(0)", $time);
            axi_sm_mode     = IDLE;
            axi_txn_en      = 1'b0;
            read_ub         = 1'b1;
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
            ub_addra        = 8'b0;
            ub_addrb        = addrb[UB_ADDRB_BITS-1:0];
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
        end else begin
            if (inst_done == 1'b0) begin
                // Write off-mem through AXI I/F.
                $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(1)", $time);
                axi_sm_mode     = STORE_DATA;
                axi_txn_en      = 1'b1;
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
                ub_addra        = 8'b0;
                ub_addrb        = 8'b0;
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = addra;
                offmem_addrb    = 32'h00000000;
                dout            = uin;
            end else begin
                // Write off-mem done.
                $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(2)", $time);
                axi_sm_mode     = IDLE;
                axi_txn_en      = 1'b0;
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
                ub_addra        = 8'b0;
                ub_addrb        = 8'b0;
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
            end
        end
    end
    // Exception : Not operation (1-cycle)
    default : begin
        $display("[%0t:CU:OUTPUT_LOGIC] Exception", $time);
        axi_sm_mode     = IDLE;
        axi_txn_en      = 1'b0;
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
        ub_addra        = 8'b0;
        ub_addrb        = 8'b0;
        wb_addra        = 8'b0;
        wb_addrb        = 8'b0;
        acc_addra       = 6'b0;
        acc_addrb       = 6'b0;
        offmem_addra    = 32'h00000000;
        offmem_addrb    = 32'h00000000;
        dout            = 128'd0;
    end
    endcase
end

endmodule
// End of CONTROL_UNIT //
