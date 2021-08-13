import os
import random
import math
from datetime import datetime

#RAM_DEPTH = 256
UB_RAM_DEPTH = 256
WB_RAM_DEPTH = 8192
#RAM_DATA_NUM = 16
UB_RAM_DATA_NUM = 16
WB_RAM_DATA_NUM = 16
#RAM_DATA_BITS = 8
UB_RAM_DATA_BITS = 8
WB_RAM_DATA_BITS = 8

FIFO_DEPTH = 4
FIFO_DATA_NUM = 16
FIFO_DATA_BITS = 8

ACC_DEPTH = 16
ACC_DATA_NUM = 16
ACC_DATA_BITS = 20

MMU_SIZE = 16
MMU_BITS = 8

OPCODE_BITS = 4
ADDRA_BITS  = 32
ADDRB_BITS  = 32
OPCODE = {
    "IDLE_INST"         : 0,
    "DATA_FIFO_INST"    : 1,
    "WEIGHT_FIFO_INST"  : 2,
    "AXI_TO_UB_INST"    : 3,
    "AXI_TO_WB_INST"    : 4,
    "UB_TO_DATA_FIFO_INST" : 5,
    "UB_TO_WEIGHT_FIFO_INST" : 6,
    "MAT_MUL_INST"      : 7,
    "MAT_MUL_ACC_INST"  : 8,
    "ACC_TO_UB_INST"    : 9,
    "UB_TO_AXI_INST"    : 10
}

def gen_random_hex_mem_data(file_path: str, depth=256, data_num=4, nbits=8):
    random.seed(datetime.now())
    with open(file_path, "w") as fp:
        for d in range(depth):
            data = ""
            for n in range(data_num):
                data += tohex(random.randint(-2**(nbits-1), 2**(nbits-1)-1), nbits)
            data += "\n"
            fp.write(data)

def compare(file_path: str, data: list) -> bool:
    flag = True
    try:
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
    except:
        print(f"[ERROR] File not found. ({file_path})")

def compare_file(file1: str, file2: str) -> bool:
    print(f"/** Comparing \"{file1}\" and \"{file2}\" **/")
    flag = True
    try:
        # file1
        fp1 = open(file1, "r")
        data1 = fp1.read().split("\n")
        fp1.close()

        # file2
        fp2 = open(file2, "r")
        data2 = fp2.read().split("\n")
        fp2.close()

        # Compare
        num_lines = len(data1)
        if (num_lines > len(data2)):
            num_lines = len(data2)
        for i in range(num_lines):
            if (data1[i] == "" or data2[i] == ""):
                continue
            elif (data1[i] != data2[i]):
                print(f"[WARNING] Data mismatch in {i + 1} line.")
                print(f"          Data1:{data1[i]}")
                print(f"          Data2:{data2[i]}")
                flag = False
    except:
        print(f"[ERROR] File not found. ({file1},{file2})")
    if (flag == True):
        print(f"\"{file1}\" and \"{file2}\" are matching.")
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
    def __init__(self, depth: int, data_num: int, nbits: int, out_nbits = None, fill_zero = True):
        # Init data
        if (fill_zero):
            self.data = [(tohex(0, nbits) * data_num) for i in range(depth)]
        else:
            self.data = ["" for i in range(depth)]
        self.depth = depth
        self.data_num = data_num
        self.nbits = nbits
        self.out_nbits = out_nbits

    def write(self, addr: int, val: str):
        self.data[addr] = val

    def load_file(self, file_path: str):
        with open(file_path, "r") as fp:
            file_content = fp.read().split("\n")
            data_len = len(file_content)
            if (self.depth < data_len):
                data_len = self.depth
            for i, l in enumerate(file_content):
                if i < data_len:
                    self.write(i, l)
                else:
                    break

    def accumulate(self, addr: int, val: str):
        data = decode(self.data[addr], self.data_num, self.nbits)
        val = decode(val, self.data_num, self.nbits)
        for i in range(self.data_num):
            data[i] += val[i]
        self.data[addr] = encode(data, self.data_num, self.nbits)

    def read(self, addr: int) -> str:
        if (self.out_nbits == None):
            return self.data[addr]
        else:
            ret = str()
            max_val = 2 ** (self.out_nbits - 1) - 1
            min_val = - (2 ** (self.out_nbits - 1))
            # Decode
            decoded = decode(self.data[addr], self.data_num, self.nbits)
            for i, d in enumerate(decoded):
                if (d < min_val):
                    d = min_val
                elif (max_val < d):
                    d = max_val
                decoded[i] = d
            encoded = encode(decoded, self.data_num, self.out_nbits)
            return encoded
    
    def print(self, dec = False, do_print = True):
        if (dec == False):
            if (do_print):
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
        ret = self.data[-1]
        self.data = [val] + self.data
        self.data.pop(-1)
        return ret

    def read(self):
        return self.data[-1]

    def print(self, dec = False, do_print = True):
        if (dec == False):
            if (do_print):
                for i in range(self.depth):
                    print(f"{i}:{self.data[i]}")
            return self.data
        else:
            ret = list()
            for i in range(self.depth):
                decoded = decode(self.data[i], self.data_num, self.nbits)
                if (do_print):
                    print(f"{i}:{decoded}")
                ret += decoded
            return ret

class MATRIX_MULTIPLY_UNIT:
    def __init__(self, size: int, nbits: int, USE_Q_NUMBER=False, Q=4):
        self.size = size
        self.input_nbits = nbits
        self.output_nbits = nbits * 2 + 4
        self.weights = [[0 for i in range(size)] for i in range(size)]

        # Q-Number format
        self.USE_Q_NUMBER = USE_Q_NUMBER
        self.Q = Q
        self.K = 2**(self.Q-1)

    def weight_print(self, dec=False, do_print = True):
        if (dec == True):
            for i in range(self.size):
                if (do_print):
                    print(f"{i}:{self.weights[i]}")
            return self.weights
        else:
            ret = list()
            for i in range(self.size):
                encoded = encode(self.weights[i], self.size, self.input_nbits)
                if (do_print):
                    print(f"{i}:{encoded}")
                ret.append(encoded)
            return ret
    
    def load_weights(self, win: str):
        win_decoded = decode(win, self.size, self.input_nbits)
        self.weights.append(win_decoded)
        self.weights.pop(0)

    def mul(self, ain: str):
        ain_decoded = list(reversed(decode(ain, self.size, self.input_nbits)))
        aout = [0 for i in range(self.size)]
        ret = str()
        for i in range(self.size):
            #print(f"a:{ain_decoded}, w:{self.weights[i]}")
            for j in range(self.size):
                aout[j] += self.weights[i][j] * ain_decoded[i]
        if (self.USE_Q_NUMBER):
            for j in range(self.size):
                aout[j] += self.K
                aout[j] = math.floor(float(aout[j])/float(2**self.Q))
        print(aout)
        ret = encode(aout, self.size, self.output_nbits)
        return ret

class SYSTOLIC_ARRAY:
    def __init__(self, gen_isa=False, USE_Q_NUMBER=False, Q=4):
        self.UB          = BRAM( depth=UB_RAM_DEPTH,  data_num=UB_RAM_DATA_NUM,  nbits=UB_RAM_DATA_BITS , fill_zero=True )
        self.WB          = BRAM( depth=WB_RAM_DEPTH,  data_num=WB_RAM_DATA_NUM,  nbits=WB_RAM_DATA_BITS , fill_zero=True )
        self.DATA_FIFO   = FIFO( depth=FIFO_DEPTH, data_num=FIFO_DATA_NUM, nbits=FIFO_DATA_BITS )
        self.WEIGHT_FIFO = FIFO( depth=FIFO_DEPTH, data_num=FIFO_DATA_NUM, nbits=FIFO_DATA_BITS )
        self.ACCUMULATOR = BRAM( depth=ACC_DEPTH,  data_num=ACC_DATA_NUM,  nbits=ACC_DATA_BITS, out_nbits=UB_RAM_DATA_BITS )
        self.MMU         = MATRIX_MULTIPLY_UNIT( size=MMU_SIZE, nbits=MMU_BITS, USE_Q_NUMBER=USE_Q_NUMBER, Q=Q)
        self.isa_fp      = None
        self.isa_file    = "./pc.mem"
        self.gen_isa     = gen_isa
    
    # Deprecated
    #def WRITE_DATA(self, addr: int, val: str):
    #    self.UB.write(addr, val)

    def AXI_TO_UB_INST(self, off_mem: BRAM, addra: str, addrb: str):
        buffer = list()
        off_mem.read(addrb)
        partition_num = int(self.UB.data_num / off_mem.data_num)
        for i in range(partition_num):
            buffer.append(off_mem.read(addrb+(partition_num-1)-i))
        self.UB.write(addra, "".join(buffer))
    
    def AXI_TO_WB_INST(self, off_mem: BRAM, addra: str, addrb: str):
        buffer = list()
        off_mem.read(addrb)
        partition_num = int(self.UB.data_num / off_mem.data_num)
        for i in range(partition_num):
            buffer.append(off_mem.read(addrb+(partition_num-1)-i))
        self.WB.write(addra, "".join(buffer))

    def UB_TO_AXI_INST(self, off_mem: BRAM, addra: str, addrb: str):
        buffer = self.UB.read(addrb)
        partition_num = int(self.UB.data_num / off_mem.data_num)
        partition_size = int(off_mem.data_num*8/4)
        for i in range(partition_num):
            off_mem.write(addra+(partition_num-1)-i, buffer[i*partition_size:(i+1)*partition_size])

    def UB_TO_DATA_FIFO_INST(self, addr: int):
        self.DATA_FIFO.write(self.UB.read(addr))
    
    def UB_PRINT(self, dec = False, do_print = True):
        return self.UB.print(dec=dec, do_print=do_print)
    
    # Deprecated
    #def WRITE_WEIGHT(self, addr: int, val: str):
    #    self.WB.write(addr, val)

    def LOAD_WEIGHT(self, addr: int):
        tmp = self.WEIGHT_FIFO.write(self.WB.read(addr))
        self.MMU.load_weights(tmp)

    def WB_PRINT(self, dec = False, do_print = True):
        return self.WB.print(dec=dec, do_print=do_print)
    
    def DATA_FIFO_PRINT(self, dec = False, do_print = True):
        return self.DATA_FIFO.print(dec=dec, do_print=do_print)
    
    def WEIGHT_FIFO_PRINT(self, dec = False, do_print = True):
        return self.WEIGHT_FIFO.print(dec=dec, do_print=do_print)
    
    def MMU_WEIGHT_PRINT(self, dec=False, do_print = True):
        return self.MMU.weight_print(dec=dec, do_print=do_print)

    def MAT_MUL(self, addra: int) -> str:
        tmp = self.MMU.mul(self.DATA_FIFO.read())
        self.ACCUMULATOR.write(addra, tmp)
        #self.UB_TO_DATA_FIFO_INST(addrb)
        return self.ACCUMULATOR.read(addra)

    def MAT_MUL_ACC(self, addra: int) -> str:
        tmp = self.MMU.mul(self.DATA_FIFO.read())
        self.ACCUMULATOR.accumulate(addra, tmp)
        #self.UB_TO_DATA_FIFO_INST(addrb)
        return self.ACCUMULATOR.read(addra)
    
    def WRITE_RESULT(self, addra: int, addrb: int):
        self.UB.write(addra, self.ACCUMULATOR.read(addrb))

    def ACC_PRINT(self, dec = False, do_print = True) -> str:
        return self.ACCUMULATOR.print(dec=dec, do_print=do_print)

    def READ_UB(self, addrb) -> str:
        return self.UB.read(addrb)

    def GENERATE_ISA(self, opcode: str, addra: int, addrb: int, isa_bits=128, fp_close=False):
        if (self.gen_isa == False):
            return
        if (self.isa_fp == None):
            if os.path.exists(os.path.join(self.isa_file)):
                os.remove(os.path.join(self.isa_file))
            self.isa_fp = open(self.isa_file, "a")
        if (opcode not in OPCODE):
            print("[ERROR] opcode is not included.")
            return
        opcode = tohex(OPCODE[opcode], OPCODE_BITS)
        addra  = tohex(addra, ADDRA_BITS)
        addrb  = tohex(addrb, ADDRB_BITS)
        isa = hexto(opcode + addra + addrb, OPCODE_BITS+ADDRA_BITS+ADDRB_BITS)
        isa = tohex(isa, isa_bits) + "\n"
        self.isa_fp.write(isa)

    def ISA_FP_CLOSE(self):
        if (self.isa_fp != None):
            self.isa_fp.close()