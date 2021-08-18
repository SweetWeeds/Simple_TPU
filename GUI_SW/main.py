import sys
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5 import uic
import serial
import torch
from torchvision import datasets, transforms
import random
import numpy as np
import qimage2ndarray

transform = transforms.Compose([transforms.ToTensor(),
                              transforms.Normalize((0.5,), (0.5,)),
                              ])

form_class = uic.loadUiType("gui.ui")[0]

trainset = datasets.MNIST('./trainset', download=True, train=True, transform=transform)
valset = datasets.MNIST('./testset', download=True, train=False, transform=transform)
trainloader = torch.utils.data.DataLoader(trainset, batch_size=64, shuffle=True)
valloader = iter(torch.utils.data.DataLoader(valset, batch_size=64, shuffle=True))

class WindowClass(QMainWindow, form_class) :
    def __init__(self) :
        super().__init__()
        self.setupUi(self)
        self.initUI()
        self.PORT = "COM3"
        self.BAUDRATE = 115200
        self.serial_inst = None
        self.img = None
        self.byte_img = None
        self.img_uart = None

    def initUI(self):
        self.pushButton.clicked.connect(self.SerialConnect)
        self.pushButton_2.clicked.connect(self.GetRandomImage)
        self.pushButton_3.setEnabled(False)
        self.pushButton_4.setEnabled(False)
    
    def getByteImage(self, img):
        ret = img + 1
        ret = ret * 256 / ret.max()
        ret = ret.astype(int)
        ret = np.reshape(ret, (28, 28))
        ret = 256-np.kron(ret, np.ones((8, 8), dtype=int))
        return ret

    def getUartData(self, x, Q):
        ret = np.trunc(x*(2**Q)).astype(int)
        ret = np.clip(ret, -128, 127)
        ret = np.reshape(ret, (49, 16))
        return ret

    def SerialConnect(self):
        mode = self.pushButton.text()
        if (mode == "Connect"):
            try:
                self.serial_inst = serial.Serial(self.PORT, self.BAUDRATE)
                self.pushButton_3.setEnabled(True)
                self.pushButton_4.setEnabled(True)
                self.pushButton.setText("Disconnect")
            except:
                err_msg = f"[ERROR] Can't open {self.PORT}[{self.BAUDRATE}]"
                print(err_msg)
                msg = QMessageBox()
                msg.setIcon(QMessageBox.Critical)
                msg.setText(err_msg)
                #msg.setInformativeText('More information')
                msg.setWindowTitle("Connection Error")
                msg.exec_()
        else:
            try:
                #self.serial_inst = serial.Serial(self.PORT, self.BAUDRATE)
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
        self.img = images[random.randint(0, len(images)-1)].numpy()
        # Refresh image view
        self.byte_img = self.getByteImage(self.img)
        scene = QGraphicsScene(self)
        scene.addPixmap(QPixmap.fromImage(qimage2ndarray.array2qimage(self.byte_img)))
        self.graphicsView.setScene(scene)

        # Get data for UART Transmission
        self.img_uart = self.getUartData(self.img, 4)
        print(self.img_uart)

if __name__ == "__main__" :
    #QApplication : 프로그램을 실행시켜주는 클래스
    app = QApplication(sys.argv) 

    myWindow = WindowClass() 

    # Show Windows
    myWindow.show()

    # Execute Event Loop
    app.exec_()