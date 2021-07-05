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

module ACCUMULATOR (
    input clk,  // Clock
    input wea,  // Write enable
    input enb,  // Read Enable, for additional power savings, disable when not in use
    input acc_en,  // Enable accumulation.
    input [clogb2(RAM_DEPTH-1)-1:0] addra,   // Write address bus, width determined from RAM_DEPTH
    input [clogb2(RAM_DEPTH-1)-1:0] addrb,   // Read address bus, width determined from RAM_DEPTH
    input [RAM_WIDTH-1:0] dina,     // RAM input data
    output reg [RAM_WIDTH-1:0] doutb   // RAM output data
);

/** Functions **/
function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction
/** End of Functions **/

localparam DATA_SIZE = 20;
localparam DATA_NUM  = 16;
localparam RAM_WIDTH = DATA_NUM*DATA_SIZE;     // Specify RAM data width
localparam RAM_DEPTH = 16;      // Specify RAM depth (number of entries)
localparam RAM_PERFORMANCE = "LOW_LATENCY"; // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
localparam INIT_FILE = "";       // Specify name/location of RAM initialization file if using one (leave blank if not)

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

always @ (posedge clk) begin : READ_WRITE_LOGIC
    integer i;
    if (wea) begin
        // Write input data (accumulate or pass-through)
        if (acc_en == 1'b1) begin
            for (i = RAM_DEPTH - 1; i >= 0; i = i - 1) begin
                bram[addra][i * 20 + : 20] <= bram[addra][i * 20 + : 20] + dina[i * 20 + : 20];
            end
        end else begin
            bram[addra] <= dina;
        end
    end
    if (enb) begin
        // Read data
        doutb <= bram[addrb];
    end
end

endmodule
// End of UNIFIED_BUFFER //
