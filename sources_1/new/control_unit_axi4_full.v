`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: POSTECH DICE Lab.
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/07/01 15:54:00
// Design Name: Control Unit for AXI-4 Full Spec
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

module CONTROL_UNIT_AXI4_FULL #
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
    //output reg  axi_txn_ff,
    input  wire init_inst_pulse,
    output reg  init_txn_pulse,
    input  wire txn_done ,  // is 'din' data is valid
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

localparam [1:0] IDLE = 2'b00,
                 LOAD_DATA   = 2'b01,
                 STORE_DATA  = 2'b10;
localparam ADDR_LSB = 4;

reg [OPCODE_BITS-1:0]   opcode;     // Operation Code
reg [2:0]               minor_state;
reg [1:0] minor_state_mode;         // 0: For exact-cycle inst, 1: For AXI write, 2: For AXI read
reg [OFFMEM_ADDRA_BITS-1:0] addra;  // Write address buffer
reg [OFFMEM_ADDRA_BITS-1:0] addrb;  // Read address buffer
//reg inst_pulse_ff1, inst_pulse_ff2;
reg inst_pulse_ff;
reg axi_flag, inst_flag;
wire inst_pulse;

// Flag which represents idling
// 1: Idling(Waiting for init_inst_pulse), 0: Working
assign idle_flag = (opcode == IDLE_INST || flag) ? 1'b1 : 1'b0;
// Pulse for init instruction
//assign inst_pulse = inst_pulse_ff1 && ~inst_pulse_ff2;
assign inst_pulse = init_inst_pulse && ~inst_pulse_ff;

always @ (posedge clk) begin : INST_PULSE
    if (reset_n == 1'b0) begin
        inst_pulse_ff <= 1'b0;
    end else begin
        inst_pulse_ff <= init_inst_pulse;
    end
end

always @ (posedge clk) begin : INPUT_LOGIC
    if (reset_n == 1'b0) begin
        // Asynchronous reset
        opcode      <= IDLE_INST;
        minor_state <= 0;
        minor_state_mode <= 0;
        flag        <= 1'b0;
    //end else if (flag == 1'b1) begin
    end else if (inst_pulse == 1'b1) begin
        // Get next instruction
        flag    <= 1'b0;
        opcode  <= instruction[OPCODE_FROM:OPCODE_TO];
        addra   <= instruction[ADDRA_FROM:ADDRA_TO];
        addrb   <= instruction[ADDRB_FROM:ADDRB_TO];
        minor_state <= 0;
        case (instruction[OPCODE_FROM:OPCODE_TO])
        UB_TO_AXI_INST : begin
            minor_state_mode <= 2;
        end
        AXI_TO_UB_INST, AXI_TO_WB_INST : begin
            minor_state_mode <= 1;
        end
        ACC_TO_UB_INST, MAT_MUL_INST, MAT_MUL_ACC_INST, IDLE_INST, 
        DATA_FIFO_INST, WEIGHT_FIFO_INST, UB_TO_DATA_FIFO_INST, UB_TO_WEIGHT_FIFO_INST : begin
            minor_state_mode <= 0;
        end
        default : begin
            // Exception: Do not change 'minor_state'
            minor_state_mode <= 3;
        end
        endcase
    end else begin
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
            if (axi_flag == 1'b1) begin
                $display("[%0t:CU:COMPLETE_FLAG] n-cycles instruction copmlete.", $time);
                flag <= 1'b1;
            end
        end
        endcase

        // Next-minor-state logic
        // Exception: AXI-Interface instructions -> These insts need n-cycles.
        // Therefore AXI insts use 'txn_done' flag for indicating that struction is done.
        if (opcode == IDLE_INST || flag == 1) begin
            // Idle instruction or Instruction done (waiting for 'inst_pulse' signal)
            minor_state <= minor_state;
        end else begin
            if (minor_state_mode == 0) begin
                // Non-AXI instructions
                minor_state <= minor_state + 1;
            end else if (minor_state_mode == 1) begin
                // AXI_TO_UB_INST, AXI_TO_WB_INST
                // 0 -> 1: Init
                // 1 -> 2: Waiting for transaction complete.
                //         If 'txn_done==1', write the data to UB/WB.
                if ((txn_done == 0 && minor_state == 0) || (txn_done == 1)) begin
                    minor_state <= minor_state + 1;
                end
            end else if (minor_state_mode == 2) begin
                // UB_TO_AXI_INST
                // 0 -> 1: Init
                // 1 -> 2: Waiting for transaction copmlete.
                if ((minor_state == 0) || (txn_done == 1)) begin
                    minor_state <= minor_state + 1;
                end
            end else begin
                minor_state <= minor_state;
            end
        end
    end
end


always @ (opcode or minor_state or addra or addrb or dout or txn_done  or din or uin or rin) begin : OUTPUT_LOGIC
    if (flag) begin
        $display("[%0t:CU:OUTPUT_LOGIC] IDLE", $time);
        axi_sm_mode     = IDLE;
        init_txn_pulse  = 1'b0;
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
        axi_flag        = 1'b0;
    end else begin
        case (opcode)

        // IDLE_INST (1-cycle)
        IDLE_INST : begin
            $display("[%0t:CU:OUTPUT_LOGIC] IDLE", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            axi_flag        = 1'b0;
        end


        // DATA_FIFO_INST (1-cycle)
        DATA_FIFO_INST : begin
            $display("[%0t:CU:OUTPUT_LOGIC] DATA_FIFO_INST", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            axi_flag        = 1'b0;
        end


        // WEIGHT_FIFO_INST (1-cycle)
        WEIGHT_FIFO_INST : begin
            $display("[%0t:CU:OUTPUT_LOGIC] WEIGHT_FIFO_INST", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            axi_flag        = 1'b0;
        end


        // AXI_TO_UB_INST (wait for data: n-cycles, write data to UB: 1-cycle)
        AXI_TO_UB_INST : begin
            if (txn_done  == 1'b0) begin
                if (minor_state == 0) begin
                    // Init (minor_state == 0)
                    $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_UB_INST(0)", $time);
                    axi_sm_mode     = LOAD_DATA;
                    init_txn_pulse  = 1'b1;
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
                    ub_addra        = addra[UB_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                    ub_addrb        = 8'h00;
                    wb_addra        = 8'h00;
                    wb_addrb        = 8'h00;
                    acc_addra       = 6'b0;
                    acc_addrb       = 6'b0;
                    offmem_addra    = 32'h00000000;
                    offmem_addrb    = addrb;
                    dout            = 128'd0;
                    axi_flag        = 1'b0;
                end else begin
                    // Wait for transaction complete.
                    $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_UB_INST(1)", $time);
                    axi_sm_mode     = LOAD_DATA;
                    init_txn_pulse  = 1'b0;
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
                    ub_addra        = addra[UB_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                    ub_addrb        = 8'h00;
                    wb_addra        = 8'h00;
                    wb_addrb        = 8'h00;
                    acc_addra       = 6'b0;
                    acc_addrb       = 6'b0;
                    offmem_addra    = 32'h00000000;
                    offmem_addrb    = addrb;
                    dout            = 128'd0;
                    axi_flag        = 1'b0;
                end
            end else begin
                // Transaction Complete: UB Data is ready
                $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_UB_INST(2)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                ub_addra        = addra[UB_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                ub_addrb        = 8'h0;
                wb_addra        = 8'h0;
                wb_addrb        = 8'h0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = addrb;
                dout            = din;
                axi_flag        = 1'b1;
            end
        end


        // AXI_TO_WB_INST (n-cycles)
        AXI_TO_WB_INST : begin
            if (txn_done  == 1'b0) begin
                if (minor_state == 0) begin
                    // Init (minor_state == 0)
                    $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_WB_INST(0)", $time);
                    axi_sm_mode     = LOAD_DATA;
                    init_txn_pulse  = 1'b1;
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
                    axi_flag        = 1'b0;
                end else begin
                    // Wait for transaction complete.
                    $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_WB_INST(1)", $time);
                    axi_sm_mode     = LOAD_DATA;
                    init_txn_pulse  = 1'b0;
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
                    axi_flag        = 1'b0;
                end
            end else begin
                // Transaction Complete: WB Data is ready
                $display("[%0t:CU:OUTPUT_LOGIC] AXI_TO_WB_INST(2)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                wb_addra        = addra[WB_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = din;
                axi_flag        = 1'b1;
            end
        end


        // UB_TO_DATA_FIFO_INST (1-cycle)
        UB_TO_DATA_FIFO_INST : begin
            $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_DATA_FIFO_INST", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            ub_addrb        = addrb[UB_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
            wb_addra        = 8'b0;
            wb_addrb        = 8'b0;
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
            axi_flag        = 1'b0;
        end


        // UB_TO_WEIGHT_FIFO_INST (1-cycle)
        UB_TO_WEIGHT_FIFO_INST : begin
            $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_WEIGHT_FIFO_INST", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            wb_addrb        = addrb[UB_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
            acc_addra       = 6'b0;
            acc_addrb       = 6'b0;
            offmem_addra    = 32'h00000000;
            offmem_addrb    = 32'h00000000;
            dout            = 128'd0;
            axi_flag        = 1'b0;
        end


        // MAT_MUL_INST (1-cycle)
        MAT_MUL_INST : begin
            if (minor_state == 0) begin
                $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_INST(0)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                ub_addrb        = addrb[UB_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end else begin
                $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_INST(1)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                acc_addra       = addra[ACC_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end
        end


        // MAT_MUL_INST_ACC (1-cycle)
        MAT_MUL_ACC_INST : begin
            if (minor_state == 0) begin
                $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_ACC_INST(0)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                ub_addrb        = addrb[UB_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end else begin
                $display("[%0t:CU:OUTPUT_LOGIC] MAT_MUL_ACC_INST(1)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                acc_addra       = addra[ACC_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end
        end


        // ACC_TO_UB_INST (n-cycles)
        ACC_TO_UB_INST : begin
            if (minor_state == 2'd0) begin
                $display("[%0t:CU:OUTPUT_LOGIC] ACC_TO_UB_INST(0)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                acc_addrb       = addrb[ACC_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end else begin
                $display("[%0t:CU:OUTPUT_LOGIC] ACC_TO_UB_INST(1)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                ub_addra        = addra[UB_ADDRA_BITS+ADDR_LSB-1:ADDR_LSB];
                ub_addrb        = 8'b0;
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = rin;
                axi_flag        = 1'b0;
            end
        end

        
        // UB_TO_AXI_INST (n-cycles) : Unsigned-Buffer's data to AXI I/F
        UB_TO_AXI_INST : begin
            if (minor_state == 0) begin
                // Init: Read UB data.
                $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(0)", $time);
                axi_sm_mode     = IDLE;
                init_txn_pulse  = 1'b0;
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
                ub_addrb        = addrb[UB_ADDRB_BITS+ADDR_LSB-1:ADDR_LSB];
                wb_addra        = 8'b0;
                wb_addrb        = 8'b0;
                acc_addra       = 6'b0;
                acc_addrb       = 6'b0;
                offmem_addra    = 32'h00000000;
                offmem_addrb    = 32'h00000000;
                dout            = 128'd0;
                axi_flag        = 1'b0;
            end else begin
                if (txn_done  == 1'b0) begin
                    // Write off-mem through AXI I/F.
                    $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(1)", $time);
                    axi_sm_mode     = STORE_DATA;
                    init_txn_pulse  = 1'b1;
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
                    axi_flag        = 1'b0;
                end else begin
                    $display("[%0t:CU:OUTPUT_LOGIC] UB_TO_AXI_INST(2)", $time);
                    axi_sm_mode     = IDLE;
                    init_txn_pulse  = 1'b0;
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
                    axi_flag        = 1'b1;
                end
            end
        end


        // Exception : No operation (1-cycle)
        default : begin
            $display("[%0t:CU:OUTPUT_LOGIC] Exception", $time);
            axi_sm_mode     = IDLE;
            init_txn_pulse  = 1'b0;
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
            axi_flag        = 1'b0;
        end
        endcase
    end
end

endmodule
// End of CONTROL_UNIT //
