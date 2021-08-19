#include "serial.h"

extern U32 SA_ADDR_LSB;
extern U32 OFF_MEM_ADDR_LSB;
extern char uart_write_buffer[DATA_BATCH_SIZE*2 + 1];

char uart_read_buffer[DATA_BATCH_SIZE*2 + 1] = { 0, };
U64 data_buffer[2];

U32 ReceiveSerialData(U32 UartBaseAddress)
{
    int Status1, Status2;

    /***************************************************************************/
    // System START
    xil_printf("\r\n\r\nSYSTEM START\r\n");

    U32 CntrlRegister;
    CntrlRegister = XUartPs_ReadReg(UartBaseAddress, XUARTPS_CR_OFFSET);
    XUartPs_WriteReg(UartBaseAddress, XUARTPS_CR_OFFSET,
              ((CntrlRegister & ~XUARTPS_CR_EN_DIS_MASK) |
               XUARTPS_CR_TX_EN | XUARTPS_CR_RX_EN));

    /***************************************************************************/
    int batch_cnt = 0;
    int cnt = 0;

    // Receving Data
    while(1) {
        if(XUartPs_IsReceiveData(UartBaseAddress)){
            uart_read_buffer[cnt++] = XUartPs_ReadReg(UartBaseAddress, XUARTPS_FIFO_OFFSET);
            if ( cnt == (DATA_BATCH_SIZE*2) ) {
                uart_read_buffer[cnt] = '\0';
                sscanf(uart_read_buffer, "%16llx%16llx\n\r", &data_buffer[0], &data_buffer[1]);
                Xil_Out64(DATA_BASE_ADDR + (batch_cnt << OFF_MEM_ADDR_LSB), data_buffer[1]);
                Xil_Out64(DATA_BASE_ADDR + (batch_cnt << OFF_MEM_ADDR_LSB) + 8, data_buffer[0]);
                cnt = 0;
                batch_cnt++;
                XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, 1);
            }
        }
        if(batch_cnt >= INPUT_DATA_BATCH_NUM){
            break;
        }
    }
    printf("\n\r");
    

    /***************************************************************************/

    return 0;
}

U32 TransmitSerialData(U32 UartBaseAddress) {
    int idx = 0;
    // Transmit Data
    while (1){
        XUartPs_WriteReg(UartBaseAddress, XUARTPS_FIFO_OFFSET, uart_write_buffer[idx]);
        idx++;
        if(idx >= (DATA_BATCH_SIZE*2)){
            break;
        }
    };

    //while(XUartPs_IsTransmitFull(UartBaseAddress));
    return 0;
}