RAM_DEPTH = 256
RAM_WIDTH = 16
RAM_DATA_BITS = 8

FIFO_DEPTH = 4
FIFO_WIDTH = 16
FIFO_DATA_BITS = 8

ACC_DEPTH = 16
ACC_WIDTH = 16
ACC_DATA_BITS = 20

MMU_SIZE = 16
MMU_BITS = 8

def tohex(val: int, nbits: int) -> str:
    if (val < 0):
        return format((val + (1 << nbits)) % (1 << nbits), '02x')
    else:
        return format(val, '02x')

def hexto(hexval: str, nbits: int) -> str:
    ret = int(hexval, 16)
    if ((2 ** (nbits - 1)) <= ret):
        ret = ret - (1 << nbits)
    return ret

def decode(data: str, width: int, nbits: int) -> list:
    ret = list()
    for i in range(width):
        ret.append(hexto(data[i * 2:i * 2 + 2], nbits))
    return ret

def encode(data: list, width: int, nbits: int) -> str:
    ret = str()
    for i in range(width):
        ret += tohex(data[i], nbits)
    return ret

class BRAM:
    def __init__(self, depth: int, width: int, nbits: int):
        self.data = ["" for i in range(depth)]
        self.depth = depth
        self.width = width
        self.nbits = nbits

    def write(self, addr: int, val: str):
        self.data[addr] = val
    
    def accumulate(self, addr: int, val: str):
        data = decode(self.data[addr], self.width, self.nbits)
        val = decode(val, self.width, self.nbits)
        for i in range(self.width):
            data[i] += val[i]
        self.data[addr] = encode(data, self.width, self.nbits)

    def read(self, addr: int) -> str:
        return self.data[addr]
    
    def print(self, dec = False):
        for i in range(self.depth):
            if (dec == False):
                print(f"{i}:{self.data[i]}")
            else:
                decoded = decode(self.data[i], self.width, self.nbits)
                print(f"{i}:{decoded}")

class FIFO:
    def __init__(self, depth: int, width: int, nbits: int):
        self.data = [("0" * int(nbits / 4 * width)) for i in range(depth)]
        self.depth = depth
        self.width = width
        self.nbits = nbits

    def write(self, val: str):
        ret = self.data[0]
        self.data.append(val)
        self.data.pop(0)
        return ret

    def read(self):
        return self.data[0]

    def print(self, dec=False):
        for i in range(self.depth):
            if (dec == False):
                print(f"{i}:{self.data[i]}")
            else:
                decoded = decode(self.data[i], self.width, self.nbits)
                print(f"{i}:{decoded}")

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
        else:
            for i in range(self.size):
                encoded = encode(self.weights[i], self.size, self.input_nbits)
                print(f"{i}:{encoded}")
    
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
        print(aout)
        ret = encode(aout, self.size, self.output_nbits)
        return ret

class SYSTOLIC_ARRAY:
    def __init__(self):
        self.UB = BRAM(RAM_DEPTH, RAM_WIDTH, RAM_DATA_BITS)
        self.WB = BRAM(RAM_DEPTH, RAM_WIDTH, RAM_DATA_BITS)
        self.DATA_FIFO = FIFO(FIFO_DEPTH, FIFO_WIDTH, FIFO_DATA_BITS)
        self.WEIGHT_FIFO = FIFO(FIFO_DEPTH, FIFO_WIDTH, FIFO_DATA_BITS)
        self.ACCUMULATOR = BRAM(ACC_DEPTH, ACC_WIDTH, ACC_DATA_BITS)
        self.MMU = MATRIX_MULTIPLY_UNIT(MMU_SIZE, MMU_BITS)
    
    def WRITE_DATA(self, addr: int, val: str):
        self.UB.write(addr, val)
    
    def LOAD_DATA(self, addr: int):
        self.DATA_FIFO.write(self.UB.read(addr))
    
    def UB_PRINT(self, dec = False):
        self.UB.print(dec=dec)
    
    def WRITE_WEIGHT(self, addr: int, val: str):
        self.WB.write(addr, val)

    def LOAD_WEIGHT(self, addr: int):
        tmp = self.WEIGHT_FIFO.write(self.WB.read(addr))
        self.MMU.load_weights(tmp)

    def WB_PRINT(self, dec = False):
        self.WB.print(dec=dec)
    
    def DATA_FIFO_PRINT(self, dec = False):
        self.DATA_FIFO.print(dec=dec)
    
    def WEIGHT_FIFO_PRINT(self, dec = False):
        self.WEIGHT_FIFO.print(dec=dec)
    
    def MMU_WEIGHT_PRINT(self, dec=False):
        self.MMU.weight_print(dec=dec)

    def MAT_MUL(self, addr: int) -> str:
        self.ACCUMULATOR.write(addr, self.MMU.mul(self.DATA_FIFO.read()))
        return self.ACCUMULATOR.read(addr)

    def MAT_MUL_ACC(self, addr: int) -> str:
        self.ACCUMULATOR.accumulate(addr, self.MMU.mul(self.DATA_FIFO.read()))
        return self.ACCUMULATOR.read(addr)

    def ACC_PRINT(self, dec = False) -> str:
        self.ACCUMULATOR.print(dec=dec)
