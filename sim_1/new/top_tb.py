from sa import *

if __name__ == "__main__":
    SA = SYSTOLIC_ARRAY()
    decode = False

    # 1. Write data to UB
    print("1. Write data to UB")
    for i in range(256):
        data = encode([i - j for j in range(15, -1, -1)], 16, 8)
        SA.WRITE_DATA(i, data)
    SA.UB_PRINT(dec=decode)

    # 2. Write weight to WB
    print("2. Write weight to WB")
    for i in range(256):
        weight = encode([- i + j for j in range(15, -1, -1)], 16, 8)
        SA.WRITE_WEIGHT(i, weight)
    SA.WB_PRINT()

    # 3. IDLE

    # 4. Load Data
    print("4. Load Data")
    for i in range(5):
        SA.LOAD_DATA(i)
    SA.DATA_FIFO_PRINT(dec=True)
    
    # 5. Load Weight
    print("5. Load Weight")
    for i in range(21):
        SA.LOAD_WEIGHT(i)
    SA.MMU_WEIGHT_PRINT(dec=True)
    SA.WEIGHT_FIFO_PRINT()

    # 6. Matrix Multiplication
    print("6. Matrix Multiplication")
    for i in range(5):
        SA.MAT_MUL(i)
        SA.LOAD_DATA(i)
    SA.ACC_PRINT()

    # 7. Matrix Multiplication with accumulation
    print ("7. Matrix Multiplication with accumulation")
    for i in range(5):
        SA.MAT_MUL_ACC(i)
        SA.LOAD_DATA(i)
    SA.ACC_PRINT()