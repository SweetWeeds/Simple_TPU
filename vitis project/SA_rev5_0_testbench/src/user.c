#include "user.h"

U32 clogb2(int bit_depth) {
    U32 ret;
    for(ret=0; bit_depth>0; ret=ret+1)
        bit_depth = bit_depth >> 1;
    return ret;
}

void compare_data(U32 *val1, U32 *val2, U32 size) {
	U32 flag = 0;
	for (int i = 0; i < size; i++) {
		if (val1[i] != val2[i]) {
			flag = 1;
		}
	}
	if (flag) {
		printf("[Warning:main] Data mismatching.\n\r");
	} else {
		printf("[Log:main] Data matching.\n\r");
	}
}