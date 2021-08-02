

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

import axi_vip_pkg::*;
//import design_1_axi_vip_0_0_pkg::*;
import SYSTOLIC_ARRAY_axi_vip_0_0_pkg::*;

module sa_bd_tb;

  //======================================================================================
  //                                simulation traffic generator
  //======================================================================================
  xil_axi_uint                            mtestID;
  // ADDR value for WRITE/READ_BURST transaction
  xil_axi_ulong                           mtestADDR;
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

  reg [127:0] input_data[2047:0];
  reg [127:0] weight_data[143840:0];
  reg [127:0] bias_data[61:0];
  reg [127:0] batch_norm_data[24:0];

  SYSTOLIC_ARRAY_axi_vip_0_0_mst_t master_agent;


  reg clk;
  reg resetn;
    
    SYSTOLIC_ARRAY_wrapper
    DUT
    (
        clk,
        resetn
    );

  //===============================================================================================
  //                                                instruction format
  //===============================================================================================

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    resetn = 1'b0;
    #10;
    resetn = 1'b1;
    #100;
    resetn = 1'b0;
  end

  initial begin
    master_agent = new("master", DUT.SYSTOLIC_ARRAY_i.axi_vip_0.inst.IF);
    master_agent.set_agent_tag("master vip");
    master_agent.set_verbosity(0);
    master_agent.start_master();

    //ineterrupt enable
    mtestID = 0;
    mtestADDR = 'h44A0_0001;
    mtestBurstLength = 0;
    //mtestDataSize = xil_axi_size_t'(xil_clog2(128/8));
    mtestDataSize = XIL_AXI_SIZE_4BYTE;
    mtestBurstType = XIL_AXI_BURST_TYPE_INCR;
    mtestLOCK = XIL_AXI_ALOCK_NOLOCK;
    mtestProtectionType = 0;
    mtestRegion = 0;
    mtestQOS = 0;
    
    mtestWData = 32'b1;
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
   
    #1000;
    $finish;

  end

endmodule
