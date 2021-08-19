import sys
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5 import uic
from serial import Serial
import torch
from torchvision import datasets, transforms
import random
import numpy as np
import qimage2ndarray
import os
from scipy.special import log_softmax

transform = transforms.Compose([transforms.ToTensor(),
                              transforms.Normalize((0.5,), (0.5,)),
                              ])

form_class = uic.loadUiType("gui.ui")[0]

trainset = datasets.MNIST('./trainset', download=True, train=True, transform=transform)
valset = datasets.MNIST('./testset', download=True, train=False, transform=transform)
trainloader = torch.utils.data.DataLoader(trainset, batch_size=64, shuffle=True)
valloader = iter(torch.utils.data.DataLoader(valset, batch_size=64, shuffle=True))
TEST_DATA = np.array(np.load(os.path.join("./img0.npy"))[0])

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

def fixed_to_point(x, Q):
    ret = x/(2**Q)
    return ret

def GetRandomImage(img=None, label=None):
    if (img==None):
        images, labels = next(iter(valloader))
        rand_idx = random.randint(0, len(images)-1)
        img = images[rand_idx].numpy()
        label = labels[rand_idx]

    print(f"img:{self.img}")
    # Refresh image view
    self.byte_img = self.getByteImage(self.img)
    scene = QGraphicsScene(self)
    scene.addPixmap(QPixmap.fromImage(qimage2ndarray.array2qimage(self.byte_img)))
    self.graphicsView.setScene(scene)

    # Get data for UART Transmission
    self.img_uart = self.getUartData(self.img, 4)

    return img, label


class WindowClass(QMainWindow, form_class) :
    def __init__(self) :
        super().__init__()
        self.setupUi(self)
        self.initUI()
        self.PORT = "COM4"
        self.BAUDRATE = 115200
        self.serial_inst = None
        self.label = None
        self.img = None
        self.byte_img = None
        self.img_uart = None

    def initUI(self):
        self.pushButton.clicked.connect(self.SerialConnect)
        self.pushButton_2.clicked.connect(self.GetRandomImage)
        self.pushButton_3.setEnabled(False)
        self.pushButton_3.clicked.connect(self.Inference)
        #self.pushButton_3.clicked.connect(self.Test)
        self.pushButton_4.setEnabled(False)
        self.pushButton_4.clicked.connect(self.Benchmark)

    def SerialConnect(self):
        mode = self.pushButton.text()
        if (mode == "Connect"):
            try:
                self.serial_inst = Serial(self.PORT, self.BAUDRATE, timeout=None)
                self.pushButton_3.setEnabled(True)
                self.pushButton_4.setEnabled(True)
                self.pushButton.setText("Disconnect")
                self.GetRandomImage()
            except Exception as e:
                err_msg = f"[ERROR] Can't open {self.PORT}[{self.BAUDRATE}]"
                print(err_msg)
                msg = QMessageBox()
                msg.setIcon(QMessageBox.Critical)
                msg.setText(err_msg)
                msg.setInformativeText(e)
                msg.setWindowTitle("Connection Error")
                msg.exec_()
        else:
            try:
                self.serial_inst.close()
                self.serial_inst = None
                self.pushButton_3.setEnabled(False)
                self.pushButton_4.setEnabled(False)
                self.pushButton.setText("Connect")
            except:
                err_msg = f"[ERROR] Can't open {self.PORT}[{self.BAUDRATE}]"
                print(err_msg)
                msg = QMessageBox()
                msg.setIcon(QMessageBox.Critical)
                msg.setText(err_msg)
                #msg.setInformativeText('More information')
                msg.setWindowTitle("Connection Error")
                msg.exec_()
    
    def GetRandomImage(self):
        images, labels = next(iter(valloader))
        rand_idx = random.randint(0, len(images)-1)
        self.img = images[rand_idx].numpy()
        self.label = labels[rand_idx]
        self.RefreshImg()
        self.getUartData(self.img, 4)

    def getUartData(self, x, Q):
        ret = np.trunc(x*(2**Q)).astype(int)
        ret = np.clip(ret, -128, 127)
        ret = ret.flatten()
        self.img_uart = ret
        return ret
    
    def getByteImage(self, img):
        ret = img + 1
        ret = ret * 256 / ret.max()
        ret = ret.astype(int)
        ret = np.reshape(ret, (28, 28))
        ret = 256-np.kron(ret, np.ones((8, 8), dtype=int))
        return ret

    def RefreshImg(self):
        # Refresh image view
        self.byte_img = self.getByteImage(self.img)
        scene = QGraphicsScene(self)
        scene.addPixmap(QPixmap.fromImage(qimage2ndarray.array2qimage(self.byte_img)))
        self.graphicsView.setScene(scene)

    def Test(self):
        # Write Input Data
        for i in range(0, 784, 16):
            tmp = encode(np.flip(TEST_DATA[i:i+16]), 16, 8)
            self.serial_inst.write(tmp.encode('ascii'))
            while self.serial_inst.inWaiting() == 0:
                continue
            while self.serial_inst.inWaiting() > 0:
                resp = self.serial_inst.read()
                if (resp != b'\x01'):
                    print(f"[ERROR] Resp value is not correct ({resp})")
        
        # Get Calculated Data
        result = ""
        while (len(result) < 32):
            while self.serial_inst.inWaiting() == 0:
                continue
            while self.serial_inst.inWaiting() > 0:
                tmp = self.serial_inst.read()
                #print(f"tmp:{tmp}")
                result += tmp.decode("ascii")
        
        x = np.flip(decode(result, 16, 8))
        x = fixed_to_point(x, 4)
        x = log_softmax(x)

        ps = torch.exp(torch.tensor(x))
        probab = list(ps.to("cpu").numpy())
        pred_label = probab.index(max(probab))
        print(f"Pred:{pred_label}")

    def Inference(self):
        #test_input = np.array([i for i in range(784)])
        test_input = self.img_uart
        self.serial_inst.reset_output_buffer()
        self.serial_inst.reset_input_buffer()
        for i in range(0, 784, 16):
            tmp = encode(np.flip(test_input[i:i+16]), 16, 8)
            self.serial_inst.write(tmp.encode('ascii'))
            while self.serial_inst.inWaiting() == 0:
                continue
            while self.serial_inst.inWaiting() > 0:
                resp = self.serial_inst.read()
                if (resp != b'\x01'):
                    print(f"[ERROR] Resp value is not correct ({resp})")

        # Get Calculated Data
        result = ""
        while (len(result) < 32):
            while self.serial_inst.inWaiting() == 0:
                continue
            while self.serial_inst.inWaiting() > 0:
                tmp = self.serial_inst.read()
                #print(f"tmp:{tmp}")
                result += tmp.decode("ascii")
        
        x = np.flip(decode(result, 16, 8))
        x = fixed_to_point(x, 4)
        x = log_softmax(x)

        ps = torch.exp(torch.tensor(x))
        probab = list(ps.to("cpu").numpy())
        pred_label = probab.index(max(probab))
        print(f"Pred:{pred_label}, True:{self.label}")
        return pred_label
    
    def Benchmark(self):
        correct_count, all_count = 0, 0
        for images,labels in valloader:
            for i in range(len(labels)):
                self.img = images[i].view(1, 784).to("cpu").numpy()
                self.label = labels.numpy()[i]
                self.RefreshImg()
                self.getUartData(self.img, 4)

                pred_label = self.Inference()
                if(self.label == pred_label):
                    correct_count += 1
                all_count += 1
        
        print("Number Of Images Tested =", all_count)
        print("\nModel Accuracy =", (correct_count/all_count))


if __name__ == "__main__" :
    #QApplication : 프로그램을 실행시켜주는 클래스
    app = QApplication(sys.argv) 

    myWindow = WindowClass() 

    # Show Windows
    myWindow.show()

    # Execute Event Loop
    app.exec_()