
//  Xilinx Simple Dual Port Single Clock RAM
//  This code implements a parameterizable SDP single clock memory.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.

//parameter RAM_PERFORMANCE = "LOW_LATENCY"; // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
//parameter INIT_FILE = "";                       // Specify name/location of RAM initialization file if using one (leave blank if not)

module BRAM #
(
    parameter RAM_WIDTH = 16*8,     // Specify RAM data width
    parameter RAM_DEPTH = 256,       // Specify RAM depth (number of entries)
    parameter IS_TESTBENCH = 0,
    parameter INIT_FILE = ""                       // Specify name/location of RAM initialization file if using one (leave blank if not)
)
(
    input clk,  // Clock
    input wea,  // Write enable
    input enb,  // Read Enable, for additional power savings, disable when not in use
    input [clogb2(RAM_DEPTH-1)-1:0] addra,   // Write address bus, width determined from RAM_DEPTH
    input [clogb2(RAM_DEPTH-1)-1:0] addrb,   // Read address bus, width determined from RAM_DEPTH
    input [RAM_WIDTH-1:0] dina,     // RAM input data
    output reg [RAM_WIDTH-1:0] doutb   // RAM output data
);

function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

reg [RAM_WIDTH-1:0] bram [RAM_DEPTH-1:0];

// The following code either initializes the memory values to a specified file or to all zeros to match hardware
//`define TB
`ifdef TB
generate
    if (INIT_FILE != "") begin: use_init_file
        initial begin
            //$display("BRAM Init with file.");
            $readmemh(INIT_FILE, bram, 0, RAM_DEPTH-1);
        end
    end else begin: init_bram_to_zero
        initial begin
        //$display("BRAM Init with index");
        for (integer ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
            bram[ram_index] = {RAM_WIDTH{1'b0}};
            //bram[ram_index] = ram_index;
        end
    end
endgenerate
`endif

always @ (negedge clk) begin : READ_WRITE_LOGIC
    if (wea) begin
        // Write input data
        bram[addra] <= dina;
    end
    if (enb) begin
        // Read data
        doutb <= bram[addrb];
    end
end
endmodule
// End of UNIFIED_BUFFER //
