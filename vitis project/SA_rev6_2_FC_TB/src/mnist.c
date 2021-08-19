#include "mnist.h"

extern U32 INSTRUCTIONS[INST_NUM][4];
extern U32 OFF_MEM_RESULT[OFF_MEM_DEPTH][4];

char uart_write_buffer[DATA_BATCH_SIZE*2 + 1] = { 0, };

U32  SA_ADDR_LSB;
U32  OFF_MEM_ADDR_LSB;
U32  instruction_buffer;
U32  RESULT_BUF[4];

int InitInstBuf(void) {
    printf("[Log:InitInstBuf] Init IB...\n\r");

    SA_ADDR_LSB      = clogb2(32/8) - 1;    // 2b
    OFF_MEM_ADDR_LSB = clogb2(128/8) - 1;   // 4b

    // Init PC's start/end address
    Xil_Out32(SA_BASE_ADDR + (6 << SA_ADDR_LSB), INST_START_ADDR);
    U32 t = Xil_In32(SA_BASE_ADDR + (6 << SA_ADDR_LSB));
    Xil_Out32(SA_BASE_ADDR + (7 << SA_ADDR_LSB), INST_END_ADDR);
    t = Xil_In32(SA_BASE_ADDR + (7 << SA_ADDR_LSB));

    // Write instructions into IB
    for (int i=0; i < INST_NUM; i++) {
        Xil_Out32(SA_BASE_ADDR + (1 << SA_ADDR_LSB), INSTRUCTIONS[i][0]);
        Xil_Out32(SA_BASE_ADDR + (2 << SA_ADDR_LSB), INSTRUCTIONS[i][1]);
        Xil_Out32(SA_BASE_ADDR + (3 << SA_ADDR_LSB), INSTRUCTIONS[i][2]);
        Xil_Out32(SA_BASE_ADDR + (4 << SA_ADDR_LSB), INSTRUCTIONS[i][3]);
        Xil_Out32(SA_BASE_ADDR + (5 << SA_ADDR_LSB), i);
        Xil_Out32(SA_BASE_ADDR + (0 << SA_ADDR_LSB), C_S_WRITE);
    }
    printf("[Log:InitInstBuf] Init IB Complete\n\r");
}

int MNIST_Infer(void) {
    printf("[Log:MNIST_INFER] Inferrence start...");

    // 1. Start systolic array operation
    Xil_Out32(SA_BASE_ADDR + (0 << SA_ADDR_LSB), C_S_START);

    // 2. Wait for complete
    do {
        instruction_buffer = Xil_In32(SA_BASE_ADDR + 0);
        printf("[Log:MNIST_INFER] ib=%x\n\r", instruction_buffer);
    } while(!(instruction_buffer & (0b1 << 6)));
    printf("[Log:MNIST_INFER] Calculation Complete.\n\r");

    // 3. Check off-mem's data
    RESULT_BUF[0] = Xil_In32(DATA_BASE_ADDR + 12);
    RESULT_BUF[1] = Xil_In32(DATA_BASE_ADDR + 8);
    RESULT_BUF[2] = Xil_In32(DATA_BASE_ADDR + 4);
    RESULT_BUF[3] = Xil_In32(DATA_BASE_ADDR + 0);

    sprintf(uart_write_buffer, "%08x%08x%08x%08x", RESULT_BUF[0], RESULT_BUF[1], RESULT_BUF[2], RESULT_BUF[3]);
    
    //printf("[Log:MNIST_INFER] Result: %08x%08x%08x%08x\n\r", uart_write_buffer);
    printf("[Log:MNIST_INFER] Result: %s\n\r", uart_write_buffer);

    printf("[Log:MNIST_INFER] Inferrence Complete\n\r");
    return 0;
}