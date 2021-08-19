#ifndef USER_HEADER_H
#define USER_HEADER_H

#define SA_BASE_ADDR       0xA0020000
#define OFF_MEM_BASE_ADDR  0xA0000000
#define BUFFER_SIZE     33
#define INST_NUM        13999
#define OFF_MEM_DEPTH   256
#define C_S_WRITE       0b00000000000000000000000000010010
#define C_S_START       0b00000000001001111011000000111001
#define C_S_NONE        0b00000000001001111011000000111000
#define INST_START_ADDR 0
#define INST_END_ADDR   (INST_START_ADDR + INST_NUM)
#define DATA_BASE_ADDR  (0xA0000000+(6720 << 4))

#define DATA_BATCH_SIZE         16
#define INPUT_DATA_BATCH_NUM    49
#define RESULT_DATA_NUM         1

#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

typedef unsigned char U8;
typedef char S8;
typedef unsigned int U32;
typedef int S32;
typedef unsigned long long U64;

U32 clogb2(U32 bit_depth);
void compare_data(U32 *val1, U32 *val2, U32 size);

#endif
// End of user.h //
