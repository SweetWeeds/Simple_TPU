import os

RAM_DEPTH = 256
RAM_data_num = 16
RAM_DATA_BITS = 8

FIFO_DEPTH = 4
FIFO_data_num = 16
FIFO_DATA_BITS = 8

ACC_DEPTH = 16
ACC_DATA_NUM = 16
ACC_DATA_BITS = 20

MMU_SIZE = 16
MMU_BITS = 8

def compare(file_path: str, data: list) -> bool:
    flag = True
    with open(file_path, "r") as fp:
        file_content = fp.read().split("\n")
        for i, l in enumerate(data):
            if ('x' in file_content[i] or 'X' in file_content[i]):
                if (l == ""):
                    continue
                else:
                    print(f"[WARNING] Data mismatch in {i + 1} line.")
                    print(f"          Data:{l}")
                    print(f"          File:{file_content[i]}")
                    flag = False
            elif (l == file_content[i]):
                continue
            else:
                print(f"[WARNING] Data mismatch in {i + 1} line.")
                print(f"          Data:{l}")
                print(f"          File:{file_content[i]}")
                flag = False
        return flag

def tohex(val: int, nbits: int) -> str:
    if (val < 0):
        return format((val + (1 << nbits)) % (1 << nbits), f'0{int(nbits/4)}x')
    else:
        return format(val, f'0{int(nbits/4)}x')

def hexto(hexval: str, nbits: int) -> str:
    ret = int(hexval, 16)
    if ((2 ** (nbits - 1)) <= ret):
        ret = ret - (1 << nbits)
    return ret

def decode(data: str, data_num: int, nbits: int) -> list:
    ret = list()
    radix_len = len(data) / data_num
    for i in range(data_num):
        ret.append(hexto(data[i * int(nbits/4) : (i + 1) * int(nbits/4)], nbits))
    return ret

def encode(data: list, data_num: int, nbits: int) -> str:
    ret = str()
    for i in range(data_num):
        ret += tohex(data[i], nbits)
    return ret

class BRAM:
    def __init__(self, depth: int, data_num: int, nbits: int):
        self.data = ["" for i in range(depth)]
        self.depth = depth
        self.data_num = data_num
        self.nbits = nbits

    def write(self, addr: int, val: str):
        self.data[addr] = val
    
    def accumulate(self, addr: int, val: str):
        data = decode(self.data[addr], self.data_num, self.nbits)
        val = decode(val, self.data_num, self.nbits)
        for i in range(self.data_num):
            data[i] += val[i]
        self.data[addr] = encode(data, self.data_num, self.nbits)

    def read(self, addr: int) -> str:
        return self.data[addr]
    
    def print(self, dec = False):
        if (dec == False):
            for i in range(self.depth):
                print(f"{i}:{self.data[i]}")
            return self.data
        else:
            ret = list()
            for i in range(self.depth):
                if (self.data[i] != ""):
                    decoded = decode(self.data[i], self.data_num, self.nbits)
                else:
                    decoded = ""
                ret += decoded
            return ret

class FIFO:
    def __init__(self, depth: int, data_num: int, nbits: int):
        self.data = [("0" * int(nbits / 4 * data_num)) for i in range(depth)]
        self.depth = depth
        self.data_num = data_num
        self.nbits = nbits

    def write(self, val: str):
        ret = self.data[0]
        self.data.append(val)
        self.data.pop(0)
        return ret

    def read(self):
        return self.data[0]

    def print(self, dec=False):
        if (dec == False):
            for i in range(self.depth):
                print(f"{i}:{self.data[i]}")
            return self.data
        else:
            ret = list()
            for i in range(self.depth):
                decoded = decode(self.data[i], self.data_num, self.nbits)
                print(f"{i}:{decoded}")
                ret += decoded
            return ret

class MATRIX_MULTIPLY_UNIT:
    def __init__(self, size: int, nbits: int):
        self.size = size
        self.input_nbits = nbits
        self.output_nbits = nbits * 2 + 4
        self.weights = [[0 for i in range(size)] for i in range(size)]

    def weight_print(self, dec=False):
        if (dec == True):
            for i in range(self.size):
                print(f"{i}:{self.weights[i]}")
            return self.weights
        else:
            ret = list()
            for i in range(self.size):
                encoded = encode(self.weights[i], self.size, self.input_nbits)
                print(f"{i}:{encoded}")
                ret += encoded
            return ret
    
    def load_weights(self, win: str):
        win_decoded = [i for i in reversed(decode(win, self.size, self.input_nbits))]
        self.weights.append(win_decoded)
        self.weights.pop(0)

    def mul(self, ain: str):
        ain_decoded = decode(ain, self.size, self.input_nbits)
        aout = [0 for i in range(self.size)]
        ret = str()
        for i in range(self.size):
            for j in range(self.size):
                aout[j] += self.weights[j][i] * ain_decoded[i]
        ret = encode(aout, self.size, self.output_nbits)
        return ret

class SYSTOLIC_ARRAY:
    def __init__(self):
        self.UB = BRAM(RAM_DEPTH, RAM_data_num, RAM_DATA_BITS)
        self.WB = BRAM(RAM_DEPTH, RAM_data_num, RAM_DATA_BITS)
        self.DATA_FIFO = FIFO(FIFO_DEPTH, FIFO_data_num, FIFO_DATA_BITS)
        self.WEIGHT_FIFO = FIFO(FIFO_DEPTH, FIFO_data_num, FIFO_DATA_BITS)
        self.ACCUMULATOR = BRAM(ACC_DEPTH, ACC_DATA_NUM, ACC_DATA_BITS)
        self.MMU = MATRIX_MULTIPLY_UNIT(MMU_SIZE, MMU_BITS)
    
    def WRITE_DATA(self, addr: int, val: str):
        self.UB.write(addr, val)
    
    def LOAD_DATA(self, addr: int):
        self.DATA_FIFO.write(self.UB.read(addr))
    
    def UB_PRINT(self, dec = False):
        return self.UB.print(dec=dec)
    
    def WRITE_WEIGHT(self, addr: int, val: str):
        self.WB.write(addr, val)

    def LOAD_WEIGHT(self, addr: int):
        tmp = self.WEIGHT_FIFO.write(self.WB.read(addr))
        self.MMU.load_weights(tmp)

    def WB_PRINT(self, dec = False):
        return self.WB.print(dec=dec)
    
    def DATA_FIFO_PRINT(self, dec = False):
        return self.DATA_FIFO.print(dec=dec)
    
    def WEIGHT_FIFO_PRINT(self, dec = False):
        return self.WEIGHT_FIFO.print(dec=dec)
    
    def MMU_WEIGHT_PRINT(self, dec=False):
        return self.MMU.weight_print(dec=dec)

    def MAT_MUL(self, addr: int) -> str:
        tmp = self.MMU.mul(self.DATA_FIFO.read())
        self.ACCUMULATOR.write(addr, tmp)
        return self.ACCUMULATOR.read(addr)

    def MAT_MUL_ACC(self, addr: int) -> str:
        tmp = self.MMU.mul(self.DATA_FIFO.read())
        self.ACCUMULATOR.accumulate(addr, tmp)
        return self.ACCUMULATOR.read(addr)

    def ACC_PRINT(self, dec = False) -> str:
        return self.ACCUMULATOR.print(dec=dec)
