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

#include <stdio.h>
#include "platform.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps_hw.h"

#define XPAR_GPIO_0_DEVICE_ID XPAR_PL_2_PS_DEVICE_ID
#define XPAR_GPIO_1_DEVICE_ID XPAR_PS_2_PL_DEVICE_ID

#define UART_BASEADDR XPAR_PSU_UART_0_BASEADDR
#define UART_CLOCK_HZ XPAR_PSU_UART_0_UART_CLK_FREQ_HZ

XGpio output;
XGpio input;

int ExampleTest(u32 UartBaseAddress);


int main(void)
{
    init_platform();

    print("\r\nHello World\n\r");
    print("Successfully ran Hello World application");


    int Status;
	Status = ExampleTest(UART_BASEADDR);
	if (Status != XST_SUCCESS) {
		xil_printf("MAIN FAIL\r\n");
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


    /***************************************************************************/
	// INITIALIZE GPIO
int ExampleTest(u32 UartBaseAddress)
{
	int Status1, Status2;

	Status1 = XGpio_Initialize(&input, XPAR_GPIO_0_DEVICE_ID);
	Status2 = XGpio_Initialize(&output, XPAR_GPIO_1_DEVICE_ID);
	if ((Status1 != XST_SUCCESS)||(Status2 != XST_SUCCESS)) {
		xil_printf("INITIALIZE FAIL\r\n");
		return XST_FAILURE;
	}

	/***************************************************************************/
	// System START
	xil_printf("\r\n\r\nSYSTEM START\r\n");

	u32 CntrlRegister;
	CntrlRegister = XUartPs_ReadReg(UartBaseAddress, XUARTPS_CR_OFFSET);
	XUartPs_WriteReg(UartBaseAddress, XUARTPS_CR_OFFSET,
			  ((CntrlRegister & ~XUARTPS_CR_EN_DIS_MASK) |
			   XUARTPS_CR_TX_EN | XUARTPS_CR_RX_EN));

	/***************************************************************************/
	u32 data_in_0;
	u32 data_in_1;

	u32 data_out_0;
	u32 data_out_1;

	u32 uart_in;

	uart_in = 0;
	data_in_0 = 0;
	data_in_1 = 0;

	int count;
	count = 0;

	while(1) {
		if(XUartPs_IsReceiveData(UartBaseAddress)){
			uart_in = XUartPs_ReadReg(UartBaseAddress, XUARTPS_FIFO_OFFSET);
			data_in_0 += uart_in;
			count++;
		}
		if(count == 1){
			break;
		}
	}

	//xil_printf("\r\n\r\nRun1");

	XGpio_DiscreteWrite(&output, 1, data_in_0);
	XGpio_DiscreteWrite(&output, 2, data_in_1);

	//xil_printf("\r\n\r\nRun2");

	data_out_0 = XGpio_DiscreteRead(&input, 1);
	data_out_1 = XGpio_DiscreteRead(&input, 2);

	//xil_printf("\r\nData : %d, %d, %d, %d\r\n", data_in_0, data_in_1, data_out_0, data_out_1);

	int count_1;
	count_1 = 0;
	while (1){
			XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, data_in_0);
			XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, data_in_0);
			//xil_printf("\r\n\r\nRun3\r\n");
			XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, data_out_0);
			XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, data_out_0);
			count_1++;
		if(count_1){
			break;
		}
	};
	while(XUartPs_IsTransmitFull(UartBaseAddress));
	//xil_printf("\r\n\r\nRun3\r\n");
	/***************************************************************************/

    cleanup_platform();
    return 0;
}





















