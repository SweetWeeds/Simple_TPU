`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
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


module PE (
    input   reset_n,            // Asynchronous reset signal
    input   clk,                // Input clock
    input   load_weight,        // control signal for load weight
    input   [7:0]   ain,        // First Input-data (8-bit) 
    input   [7:0]   win,        // Input Weight (8-bit)
    output  [7:0]   weight_out, // 
    output  [15:0]  out         // Output data (16-bit)
);

reg [7:0]   weight;         // Weight value (weight <= win)
reg [7:0]   weight_out_reg; // Weight value (weight_out_reg <= weight)
reg [15:0]  out_reg;        // Output value (output = activation * weight)

assign out = out_reg;
assign weight_out = weight_out_reg;

/**
 * Block name: LOAD_VALUE_LOGIC
 * Type: Ssequential Logic
 * Description: Load weight or activation values.
 */
always @ (posedge clk) begin: LOAD_VALUE_LOGIC
    if (load_weight) begin
        // Load weight value
        weight <= win;
        weight_out_reg <= weight;
    end else begin
        // Keep weight value
        weight <= weight;
        weight_out_reg <= weight_out_reg;
    end
end

/**
 * Block name: MULTIPLY_LOGIC
 * Type: Combinational Logic
 * Description: Calculate Multiplication. (o = a * w)
 */
always @ (ain or weight) begin: MULTIPLY_LOGIC
    if (ain[7] ^ weight[7]) begin
        out_reg[15] = 1'b0;
        out_reg[14:0] = ain[6:0] * weight[6:0];
        out_reg = (~out_reg) + 1'b1;
    end else begin
        out_reg[15:0] = ain * weight;
    end
end

endmodule

// PE