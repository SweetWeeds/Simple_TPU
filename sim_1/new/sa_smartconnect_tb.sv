

/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : sim_tb_top.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR4_SDRAM
// Purpose          :
//                   Top-level testbench for testing Memory interface.
//                   Instantiates:
//                     1. IP_TOP (top-level representing FPGA, contains core,
//                        clocking, built-in testbench/memory checker and other
//                        support structures)
//                     2. Memory Model
//                     3. Miscellaneous clock generation and reset logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ns/1ps
`define TB

import axi_vip_pkg::*;
//import design_1_axi_vip_0_0_pkg::*;
import SA_smartconnect_TB_axi_vip_0_0_pkg::*;

//parameter IB_MEM_FILE = "/home/hankyulkwon/vivado_project/systolic_array/systolic_array.srcs/sim_1/new/python_tb/pc.mem";
parameter IB_MEM_FILE = "D:/workspace/210805_1710/systolic_array/systolic_array.srcs/sim_1/new/python_tb/pc.mem";

module sa_smc_tb;

    //======================================================================================
    //                                simulation traffic generator
    //======================================================================================
    xil_axi_uint                            mtestID;
    // ADDR value for WRITE/READ_BURST transaction
    xil_axi_ulong                           mtestADDR;
    xil_axi_ulong                           mtestBaseADDR;
    // Burst Length value for WRITE/READ_BURST transaction
    xil_axi_len_t                           mtestBurstLength;
    // SIZE value for WRITE/READ_BURST transaction
    xil_axi_size_t                          mtestDataSize;
    // Burst Type value for WRITE/READ_BURST transaction
    xil_axi_burst_t                         mtestBurstType;
    // LOCK value for WRITE/READ_BURST transaction
    xil_axi_lock_t                          mtestLOCK;
    // Cache Type value for WRITE/READ_BURST transaction
    xil_axi_cache_t                         mtestCacheType = 3;
    // Protection Type value for WRITE/READ_BURST transaction
    xil_axi_prot_t                          mtestProtectionType = 3'b000;
    // Region value for WRITE/READ_BURST transaction
    xil_axi_region_t                        mtestRegion = 4'b000;
    // QOS value for WRITE/READ_BURST transaction
    xil_axi_qos_t                           mtestQOS = 4'b000;
    // Data beat value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       dbeat;
    // User beat value for WRITE/READ_BURST transaction
    xil_axi_user_beat                       usrbeat;
    // Wuser value for WRITE/READ_BURST transaction
    xil_axi_data_beat [255:0]               mtestWUSER;
    // Awuser value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       mtestAWUSER = 'h0;
    // Aruser value for WRITE/READ_BURST transaction
    xil_axi_data_beat                       mtestARUSER = 0;
    // Ruser value for WRITE/READ_BURST transaction
    xil_axi_data_beat [255:0]               mtestRUSER;
    // Buser value for WRITE/READ_BURST transaction
    xil_axi_uint                            mtestBUSER = 0;
    // Bresp value for WRITE/READ_BURST transaction
    xil_axi_resp_t                          mtestBresp;
    // Rresp value for WRITE/READ_BURST transaction
    xil_axi_resp_t[255:0]                   mtestRresp;
    bit [32767:0]                           mtestWData;
    bit [32767:0]                           mtestRData;

    reg [127:0] instruction[0:65535];
    reg [31:0]  slv_reg0;    // Logic control
    reg [31:0]  slv_reg1;    // C_S_DOUTA[0]
    reg [31:0]  slv_reg2;    // C_S_DOUTA[1]
    reg [31:0]  slv_reg3;    // C_S_DOUTA[2]
    reg [31:0]  slv_reg4;    // C_S_DOUTA[3]
    reg [31:0]  slv_reg5;    // addr
    reg [31:0]  slv_reg6;    // Start addr
    reg [31:0]  slv_reg7;    // End addr
    
    SA_smartconnect_TB_axi_vip_0_0_mst_t master_agent;

    reg clk;
    reg resetn;
    
    SA_smartconnect_TB_wrapper DUT (
        clk,
        resetn
    );

    //===============================================================================================
    //                                                instruction format
    //===============================================================================================

    always #5 clk = ~clk;

    initial begin : RESET_LOGIC
        // Reset logics
        clk = 1'b0;
        resetn = 1'b1;
        #10;
        resetn = 1'b0;
        #100;
        resetn = 1'b1;
    end

    initial begin : TESTBENCH_LOGIC
        //$readmemh(IB_MEM_FILE, instruction);
        $readmemh(IB_MEM_FILE, DUT.SA_smartconnect_TB_i.SYSTOLIC_ARRAY_AXI4_0.inst.IB.ISA_MEMORY.bram);
        # 110;  // Wait for reset
        master_agent = new("master", DUT.SA_smartconnect_TB_i.axi_vip_0.inst.IF);
        master_agent.set_agent_tag("master vip");
        master_agent.set_verbosity(0);
        master_agent.start_master();

        // Set VIP's params
        mtestID = 0;
        mtestBurstLength = 0;
        mtestBaseADDR = 'hA002_0000;
        //mtestDataSize = xil_axi_size_t'(xil_clog2(128/8));
        mtestDataSize = XIL_AXI_SIZE_4BYTE; // 32-bit

        mtestBurstType = XIL_AXI_BURST_TYPE_INCR;
        mtestLOCK = XIL_AXI_ALOCK_NOLOCK;
        mtestProtectionType = 0;
        mtestRegion = 0;
        mtestQOS = 0;

        // 1. Define range of PC address
        slv_reg6 = 32'd0;
        slv_reg7 = 32'd13998;

        mtestWData = slv_reg6;
        mtestADDR = mtestBaseADDR + 6*4;
        master_agent.AXI4_WRITE_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestAWUSER,
            mtestWData,
            mtestWUSER,
            mtestBresp
        );

        mtestWData = slv_reg7;
        mtestADDR = mtestBaseADDR + 7*4;
        master_agent.AXI4_WRITE_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestAWUSER,
            mtestWData,
            mtestWUSER,
            mtestBresp
        );

        // 2. Fill data in instruction buffer
        /*
        for (integer pc_addr=0; pc_addr < 13997; pc_addr=pc_addr+1) begin
            // Prepare data
            slv_reg0 = 32'b0010010;
            slv_reg1 = instruction[pc_addr][127:96];
            slv_reg2 = instruction[pc_addr][95:64];
            slv_reg3 = instruction[pc_addr][63:32];
            slv_reg4 = instruction[pc_addr][31:0];
            slv_reg5 = pc_addr;

            // slv_reg1 (C_S_DOUTA[0])
            mtestWData = slv_reg1;
            mtestADDR = mtestBaseADDR + 1*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            // slv_reg2 (C_S_DOUTA[1])
            mtestWData = slv_reg2;
            mtestADDR = mtestBaseADDR + 2*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            // slv_reg3 (C_S_DOUTA[2])
            mtestWData = slv_reg3;
            mtestADDR = mtestBaseADDR + 3*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            // slv_reg4 (C_S_DOUTA[3])
            mtestWData = slv_reg4;
            mtestADDR = mtestBaseADDR + 4*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            // slv_reg5 (C_S_ADDRA)
            mtestWData = slv_reg5;
            mtestADDR = mtestBaseADDR + 5*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );

            // slv_reg0 (SA's slave control inst)
            mtestWData = slv_reg0;
            mtestADDR = mtestBaseADDR + 0*4;
            master_agent.AXI4_WRITE_BURST(
                mtestID,
                mtestADDR,
                mtestBurstLength,
                mtestDataSize,
                mtestBurstType,
                mtestLOCK,
                mtestCacheType,
                mtestProtectionType,
                mtestRegion,
                mtestQOS,
                mtestAWUSER,
                mtestWData,
                mtestWUSER,
                mtestBresp
            );
        end*/

        // 3. Generate force instruction pulse signal
        slv_reg0 = 32'b0000000000_1001111011_00000_0111001;
        mtestWData = slv_reg0;
        mtestADDR = mtestBaseADDR + 0*4;
        master_agent.AXI4_WRITE_BURST(
            mtestID,
            mtestADDR,
            mtestBurstLength,
            mtestDataSize,
            mtestBurstType,
            mtestLOCK,
            mtestCacheType,
            mtestProtectionType,
            mtestRegion,
            mtestQOS,
            mtestAWUSER,
            mtestWData,
            mtestWUSER,
            mtestBresp
        );
        # 5000;
        $finish;
    end

endmodule
