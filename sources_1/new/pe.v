`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Postech DICE
// Engineer: Hankyul Kwon
// 
// Create Date: 2021/06/29 16:51:15
// Design Name: Processing Element
// Module Name: PE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Processing Element
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
 * MODULE: PE
 * Description:
 *  'PE' is processing element, which calculate 8-bit signed-integer multiplication.
 *  
 */
module PE (
    input  reset_n,    // Asynchronous reset signal
    input  clk,        // Input clock
    input  wen,             // control signal for load weight
    input  signed [7:0] ain,          // First Input-data (8-bit) 
    input  signed [7:0] win,          // Input Weight (8-bit)
    output signed [7:0] wout,         // 
    output reg signed [15:0] aout           // Output data (16-bit)
);

reg signed [7:0] weight;         // Weight value (weight <= win)

assign wout = weight;

/**
 * Block name: PE_LOGIC
 * Type: Sequential Logic
 * Description:
 */
always @ (posedge clk or negedge reset_n) begin: PE_LOGIC
    if (reset_n == 1'b0) begin
        // Reset (Active low, async)
        weight  <= 8'sd0;
        aout    <= 16'sd0;
    end else if (wen) begin
        // Load weight value
        weight  <= win;
        aout    <= 16'sd0;
    end else begin
        // Keep weight value
        weight  <= weight;
        aout    <= ain * weight;
    end
end

endmodule

// End of PE //
