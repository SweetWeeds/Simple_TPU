/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include "user.h"

extern U32 INSTRUCTIONS[INST_NUM][4];
extern U32 OFF_MEM_RESULT[OFF_MEM_DEPTH][4];

UINTPTR SA_BASE_ADDR       = 0xA0020000;
UINTPTR OFF_MEM_BASE_ADDR  = 0xA0000000;
U32     SA_ADDR_LSB;
U32     OFF_MEM_ADDR_LSB;
U8   byte_buffer[BUFFER_SIZE] = { 0, };
U32  instruction_buffer;
//U32  off_mem_buffer[4];
U32  RESULT_BUF[4];

int main()
{
    init_platform();
    SA_ADDR_LSB      = clogb2(32/8) - 1;    // 2b
    OFF_MEM_ADDR_LSB = clogb2(128/8) - 1;   // 4b

    printf("[Log:main] Systolic Array test start...");

    // 0. Init PC's start/end address
    Xil_Out32(SA_BASE_ADDR + (6 << SA_ADDR_LSB), INST_START_ADDR);
    U32 t = Xil_In32(SA_BASE_ADDR + (6<<SA_ADDR_LSB));
    printf("S:%d",t);
    Xil_Out32(SA_BASE_ADDR + (7 << SA_ADDR_LSB), INST_END_ADDR);
    t = Xil_In32(SA_BASE_ADDR + (7<<SA_ADDR_LSB));
    printf("E:%d",t);

    // 1. Write data into Unified Buffer.
    for (int i=0; i < INST_NUM; i++) {
        Xil_Out32(SA_BASE_ADDR + (1 << SA_ADDR_LSB), INSTRUCTIONS[i][0]);
        Xil_Out32(SA_BASE_ADDR + (2 << SA_ADDR_LSB), INSTRUCTIONS[i][1]);
        Xil_Out32(SA_BASE_ADDR + (3 << SA_ADDR_LSB), INSTRUCTIONS[i][2]);
        Xil_Out32(SA_BASE_ADDR + (4 << SA_ADDR_LSB), INSTRUCTIONS[i][3]);
        Xil_Out32(SA_BASE_ADDR + (5 << SA_ADDR_LSB), i);
        Xil_Out32(SA_BASE_ADDR + (0 << SA_ADDR_LSB), C_S_WRITE);
    }

    // 2. Start systolic array operation
    printf("[Log:main] Starting calculation.\n\r");
    Xil_Out32(SA_BASE_ADDR + (0 << SA_ADDR_LSB), C_S_START);

    // 3. Wait for complete
    do {
        instruction_buffer = Xil_In32(SA_BASE_ADDR + 0);
        printf("[Log:main] ib=%x\n\r", instruction_buffer);
    } while(!(instruction_buffer & (0b1 << 6)));
    printf("[Log:main] Calculation Complete.\n\r");

    // 4. Check off-mem's data
    RESULT_BUF[0] = Xil_In32(OFF_MEM_BASE_ADDR + RESULT_BASE_ADDR + 12);
    RESULT_BUF[1] = Xil_In32(OFF_MEM_BASE_ADDR + RESULT_BASE_ADDR + 8);
    RESULT_BUF[2] = Xil_In32(OFF_MEM_BASE_ADDR + RESULT_BASE_ADDR + 4);
    RESULT_BUF[3] = Xil_In32(OFF_MEM_BASE_ADDR + RESULT_BASE_ADDR + 0);
    printf("Result:%08x%08x%08x%08x\n\r", RESULT_BUF[0], RESULT_BUF[1], RESULT_BUF[2], RESULT_BUF[3]);

    while (1) {
    	continue;
    }

    printf("[Log:main] Finished...\n\r");

    cleanup_platform();
    return 0;
}
