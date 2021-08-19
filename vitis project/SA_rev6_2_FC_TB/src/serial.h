#ifndef SERIAL_HEADER_H
#define SERIAL_HEADER_H

#include "user.h"
#include "xuartps_hw.h"

#define UART_BASEADDR XPAR_PSU_UART_1_BASEADDR
#define UART_CLOCK_HZ XPAR_PSU_UART_1_UART_CLK_FREQ_HZ

U32 ReceiveSerialData(U32 UartBaseAddress);
U32 TransmitSerialData();

#endif

// End of serial.h
