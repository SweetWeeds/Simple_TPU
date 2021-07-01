/*-------------------------------------------------------------------------
 *
 *  Copyright (c) 2021 by Han Kyul Kwon, All rights reserved.
 *
 *  File name  : sa_share.v
 *  Written by : Kwon, Han Kyul
 *               School of Electrical Engineering
 *               Sungkyunkwan University
 *  Written on : 2021.07.01  (version 1.0)
 *  Version    : 1.0
 *  Design     : Definitions shared by all design files and testbench files.
 *
 *  Modification History:
 *      * version 1.1, Oct 30, 2019  by Hyoung Bok Min
 *        - Macro "perr()" is newly introduced.
 *          This macro can be used instead of system task $error().
 *        - parameter STOP_ERRORS and integer err_count are used for the macros.
 *      * version 1.0, July 04, 2018  by Hyoung Bok Min
 *        version 1.0 released.
 *
 * Note:
 *     * This file is intended to be included by almost all design files
 *       and testbench files.
 *
 *-------------------------------------------------------------------------*/

// Functions and Parameters
function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

/** bram_256x16x8b.v **/
parameter RAM_WIDTH = 16*8;                  // Specify RAM data width
parameter RAM_DEPTH = 256;                  // Specify RAM depth (number of entries)
parameter RAM_PERFORMANCE = "LOW_LATENCY"; // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
parameter INIT_FILE = "";                       // Specify name/location of RAM initialization file if using one (leave blank if not)

// Clock parameters
parameter  CLOCK_PS          = 10000;      //  should be a multiple of 10
localparam clock_period      = CLOCK_PS / 1000.0;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = clock_period / 10;

/** controller.v **/
// Instruction Set
localparam ISA_BITS = 16;
localparam OPERAND_BITS = 8;
localparam [OPERAND_BITS-1:0] IDLE          = 8'h00,
                              LOAD_DATA     = 8'h01,
                              LOAD_WEIGHT   = 8'h02,
                              MAT_MUL       = 8'h03,
                              WRITE_DATA    = 8'h04,
                              WRITE_WEIGHT  = 8'h05,
                              WRITE_RESULT  = 8'h06;

// Major mode (M1)
localparam [OPERAND_BITS-1:0]   M1_IDLE_STATE           = 8'h0,
                                M1_LOAD_DATA_STATE      = 8'h1,
                                M1_LOAD_WEIGHT_STATE    = 8'h2,
                                M1_MAT_MUL_STATE        = 8'h3,
                                M1_WRITE_DATA_STATE     = 8'h4,
                                M1_WRITE_WEIGHT_STATE   = 8'h5;

// M1_MAT_MUL_STATE's minor mode (M2)
localparam MODE_BITS = 4;
