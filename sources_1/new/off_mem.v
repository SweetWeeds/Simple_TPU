`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/15 16:14:48
// Design Name:
// Module Name: off_mem
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module OFF_MEM #
(
    parameter integer DATA_WIDTH = 4*8,
    parameter integer RAM_DEPTH = 256
)
(
    input wire  clk,
    input wire  reset_n,
    input wire [DATA_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [DATA_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

wire wea, enb;
wire [DATA_WIDTH-1 : 0] addra, addrb;
wire [DATA_WIDTH-1 : 0] dina, dinb;

BRAM #(.RAM_WIDTH(DATA_WIDTH), .RAM_DEPTH(RAM_DEPTH)) OFF_MEM_BRAM
(
    .clk(clk),
    .wea(wea),
    .enb(enb),
    .addra(addra[7:0]),
    .addrb(addrb[7:0]),
    .dina(dina),
    .doutb(doutb)
);

myip_AXI4_Lite_Slave_0 #(.C_S00_AXI_DATA_WIDTH(DATA_WIDTH), .C_S00_AXI_ADDR_WIDTH(DATA_WIDTH)) S00
(
    .c_s00_web(wea),
    .c_s00_douta(dina),
    .c_s00_addra(addra),
    .c_s00_reb(enb),
    .c_s00_dinb(doutb),
    .c_s00_addrb(addrb),
    .s00_axi_aclk(clk),
    .s00_axi_aresetn(reset_n),
    .s00_axi_awaddr(s00_axi_awaddr),
    .s00_axi_awprot(s00_axi_awprot),
    .s00_axi_awvalid(s00_axi_awvalid),
    .s00_axi_awready(s00_axi_awready),
    .s00_axi_wdata(s00_axi_wdata),
    .s00_axi_wstrb(s00_axi_wstrb),
    .s00_axi_wvalid(s00_axi_wvalid),
    .s00_axi_wready(s00_axi_wready),
    .s00_axi_bresp(s00_axi_bresp),
    .s00_axi_bvalid(s00_axi_bvalid),
    .s00_axi_bready(s00_axi_bready),
    .s00_axi_araddr(s00_axi_araddr),
    .s00_axi_arprot(s00_axi_arprot),
    .s00_axi_arvalid(s00_axi_arvalid),
    .s00_axi_arready(s00_axi_arready),
    .s00_axi_rdata(s00_axi_rdata),
    .s00_axi_rresp(s00_axi_rresp),
    .s00_axi_rvalid(s00_axi_rvalid),
    .s00_axi_rready(s00_axi_rready)
);

endmodule
