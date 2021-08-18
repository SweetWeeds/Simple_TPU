#ifndef USER_HEADER_H
#define USER_HEADER_H

#define BUFFER_SIZE     33
#define INST_NUM        13998
#define OFF_MEM_DEPTH   256
#define C_S_WRITE       0b00000000000000000000000000010010
#define C_S_START       0b00000000001001111011000000111001
#define C_S_NONE        0b00000000001001111011000000111000
#define INST_START_ADDR 0
#define INST_END_ADDR   (INST_START_ADDR + INST_NUM)
#define RESULT_BASE_ADDR (6720 << 4)

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

typedef char U8;
typedef int  U32;
typedef unsigned long long U64;

U32 clogb2(U32 bit_depth);
void compare_data(U32 *val1, U32 *val2, U32 size);

#endif
// End of user.h //
