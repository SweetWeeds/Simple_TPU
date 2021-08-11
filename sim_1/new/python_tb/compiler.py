from sa import *
import numpy as np

class Matrix:
    def __init__(self, data: list, addr: int):
        self.data = data
        self.addr = addr

def matmul(a, b):
    a_dim = a.shape
    b_dim = b.shape
