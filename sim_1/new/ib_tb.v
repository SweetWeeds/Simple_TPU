`timescale 1ns / 1ps

module IB_TB;

reg clk, reset_n;
reg flag, force_inst, wea;
reg ib_mode, ib_en, ib_incr, ib_jmp;
reg [ADDR_BITS-1:0] start_addr, end_addr, addra;
reg [INST_BITS-1:0] din;
wire [INST_BITS-1:0] instruction;
wire init_inst_pulse, complete_flag;

// Clock localparams
parameter CLOCK_PS             = 10000;      //  should be a multiple of 10
parameter clock_period         = CLOCK_PS / 1000.0;
parameter half_clock_period    = clock_period / 2;
parameter minimum_period       = clock_period / 10;
parameter integer ADDR_BITS = 10;
parameter integer INST_BITS = 128;
integer i = 0;

/**
 *  Clock signal generation.
 *  Clock is assumed to be initialized to 1'b0 at time 0.
 */
initial begin : CLOCK_GENERATOR
    clk = 1'b0;
    forever
        # half_clock_period clk = ~clk;
end

INSTRUCTION_BUFFER #(
    .INIT_FILE("/home/hankyulkwon/vivado_project/systolic_array/systolic_array.srcs/sim_1/new/python_tb/pc.mem")
) IB (
    .clk(clk),
    .reset_n(reset_n),
    .flag(flag),
    .force_inst(force_inst),
    .wea(wea),
    .ib_mode(ib_mode),
    .ib_en(ib_en),
    .ib_incr(ib_incr),
    .ib_jmp(ib_jmp),
    .start_addr(start_addr),
    .end_addr(end_addr),
    .complete_flag(complete_flag),
    .din(din),
    .addra(addra),
    .instruction(instruction),
    .init_inst_pulse(init_inst_pulse)
);

initial begin
    ib_en = 1'b1;
    start_addr = 0;
    end_addr = 10;
    // Initialization with 'reset_n' (0 ~ 10000 ns)
    # clock_period;
    reset_n = 1'b0;
    # clock_period;
    reset_n = 1'b1;

    flag    = 1;

    // IB_MODE (Procedural)
    while (complete_flag != 1) begin
        ib_mode = 0;
        ib_incr = 1;
        ib_jmp  = 0;
        @ (posedge init_inst_pulse) flag    = 0;
        @ (negedge init_inst_pulse) flag    = 1;
    end
    $stop();

end

endmodule