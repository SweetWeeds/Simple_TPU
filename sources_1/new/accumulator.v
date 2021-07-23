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

module ACCUMULATOR #
(
    parameter DATA_SIZE = 20,
    parameter OUTPUT_DATA_SIZE = 8,
    parameter OUTPUT_DATA_MIN = - (2 ** (OUTPUT_DATA_SIZE - 1)),
    parameter OUTPUT_DATA_MAX = (2 ** (OUTPUT_DATA_SIZE - 1)) - 1,
    parameter DATA_NUM  = 16,
    parameter RAM_WIDTH = DATA_NUM*DATA_SIZE,     // Specify RAM data width
    parameter DOUT_WIDTH = DATA_NUM*OUTPUT_DATA_SIZE,
    parameter RAM_DEPTH = 64,      // Specify RAM depth (number of entries)
    parameter INIT_FILE = ""       // Specify name/location of RAM initialization file if using one (leave blank if not)
)
(
    input clk,  // Clock
    input wea,  // Write enable
    input enb,  // Read Enable, for additional power savings, disable when not in use
    input acc_en,  // Enable accumulation.
    input [clogb2(RAM_DEPTH-1)-1:0] addra,   // Write address bus, width determined from RAM_DEPTH
    input [clogb2(RAM_DEPTH-1)-1:0] addrb,   // Read address bus, width determined from RAM_DEPTH
    input [RAM_WIDTH-1:0] dina,     // RAM input data
    output [DOUT_WIDTH-1:0] doutb   // RAM output data
);

function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

reg [RAM_WIDTH-1:0] bram [RAM_DEPTH-1:0];

// The following code either initializes the memory values to a specified file or to all zeros to match hardware
//generate
//    begin: init_bram_to_zero
//        integer ram_index;
//        initial
//            for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
//                bram[ram_index] = {RAM_WIDTH{1'b0}};
//    end
//endgenerate

wire signed [DATA_SIZE-1:0] brama_parsed [DATA_NUM-1:0];
wire signed [DATA_SIZE-1:0] bramb_parsed [DATA_NUM-1:0];
wire signed [DATA_SIZE-1:0] dina_parsed [DATA_NUM-1:0];
reg signed [OUTPUT_DATA_SIZE-1:0] dout_parsed [DATA_NUM-1:0];

generate
    for (genvar i = DATA_NUM - 1; i >= 0; i = i - 1) begin
        assign brama_parsed[i] = bram[addra][i*DATA_SIZE+:DATA_SIZE];
        assign bramb_parsed[i] = bram[addrb][i*DATA_SIZE+:DATA_SIZE];
        assign dina_parsed[i] = dina[i*DATA_SIZE+:DATA_SIZE];
        assign doutb[i*OUTPUT_DATA_SIZE+:OUTPUT_DATA_SIZE] = dout_parsed[i];
    end
endgenerate

always @ (posedge clk) begin : READ_WRITE_LOGIC
    integer i;
    if (wea) begin
        // Write input data (accumulate or pass-through)
        if (acc_en == 1'b1) begin
            for (i = DATA_NUM - 1; i >= 0; i = i - 1) begin
                bram[addra][i*DATA_SIZE+:DATA_SIZE] <= brama_parsed[i] + dina_parsed[i];
            end
        end else begin
            bram[addra] <= dina;
        end
    end
    if (enb) begin
        // Read data with truncation
        for (i = DATA_NUM - 1; i >= 0; i = i - 1) begin
            if (bramb_parsed[i] < OUTPUT_DATA_MIN)
                dout_parsed[i] <= OUTPUT_DATA_MIN;
            else if (OUTPUT_DATA_MAX < bramb_parsed[i])
                dout_parsed[i] <= OUTPUT_DATA_MAX;
            else
                dout_parsed[i] <= bramb_parsed[i];
        end
    end
end

endmodule
// End of UNIFIED_BUFFER //
