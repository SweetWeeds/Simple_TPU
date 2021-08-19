import sys
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5.QtCore import *
from PyQt5 import uic
from serial import Serial
import serial
import torch
from torchvision import datasets, transforms
import random
import numpy as np
import qimage2ndarray
import os
from scipy.special import log_softmax

serial_inst = None
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

def getUartData(x, Q):
        ret = np.trunc(x*(2**Q)).astype(int)
        ret = np.clip(ret, -128, 127)
        ret = ret.flatten()
        return ret


def Inference(img_uart, serial_inst):
    test_input = img_uart
    serial_inst.reset_output_buffer()
    serial_inst.reset_input_buffer()
    for i in range(0, 784, 16):
        tmp = encode(np.flip(test_input[i:i+16]), 16, 8)
        serial_inst.write(tmp.encode('ascii'))
        while serial_inst.inWaiting() == 0:
            continue
        while serial_inst.inWaiting() > 0:
            resp = serial_inst.read()
            # Response Check
            if (resp != b'\x01'):
                print(f"[ERROR] Resp value is not correct ({resp})")

    # Get Calculated Data
    result = ""
    while (len(result) < 32):
        while serial_inst.inWaiting() == 0:
            continue
        while serial_inst.inWaiting() > 0:
            tmp = serial_inst.read()
            #print(f"tmp:{tmp}")
            result += tmp.decode("ascii")
    
    x = np.flip(decode(result, 16, 8))
    x = fixed_to_point(x, 4)
    x = log_softmax(x)

    ps = torch.exp(torch.tensor(x))
    probab = list(ps.to("cpu").numpy())
    pred_label = probab.index(max(probab))
    #print(f"Pred:{pred_label}, True:{self.label}")
    return pred_label



class BenchmarkQThread(QThread):
    img_refresh_event = pyqtSignal(list)
    pred_event = pyqtSignal(list)
    benchmark_complete_event = pyqtSignal(list)
    def __init__(self, parent=None):
        super().__init__()

    def run(self):
        global serial_inst
        correct_count, all_count = 0, 0
        entire_count = len(valloader)*64
        for images,labels in valloader:
            for i in range(len(labels)):
                img = images[i].view(1, 784).to("cpu").numpy()
                label = labels.numpy()[i]
                
                self.img_refresh_event.emit([img, label])

                #self.RefreshImg()
                #self.getUartData(self.img, 4)
                img_uart = getUartData(img, 4)
                pred_label = Inference(img_uart=img_uart, serial_inst=serial_inst)

                if(label == pred_label):
                    correct_count += 1
                all_count += 1

                self.pred_event.emit([pred_label, all_count, entire_count, correct_count])

        accuracy = (correct_count/all_count)
        print("Number Of Images Tested =", all_count)
        print("\nModel Accuracy =", accuracy)
        self.benchmark_complete_event.emit([all_count, accuracy])
    
    def stop(self):
        self.working = False
        self.quit()
        self.wait(5000)


class WindowClass(QMainWindow, form_class) :
    def __init__(self) :
        super().__init__()
        self.setupUi(self)
        self.initUI()
        self.PORT = "COM4"
        self.BAUDRATE = 115200
        #self.serial_inst = None
        self.label = None
        self.img = None
        self.byte_img = None
        self.img_uart = None
        self.correct_count = 0
        self.all_count = 0

    def initUI(self):
        self.pushButton.clicked.connect(self.SerialConnect)
        self.pushButton_2.clicked.connect(self.GetRandomImage)
        self.pushButton_3.setEnabled(False)
        self.pushButton_3.clicked.connect(self.Inference)
        #self.pushButton_3.clicked.connect(self.Test)
        self.pushButton_4.setEnabled(False)
        self.pushButton_4.clicked.connect(self.Benchmark)
        self.progressBar.setValue(0)
        self.progressBar.setValue(150)
        self.bench_th = BenchmarkQThread()
        self.bench_th.benchmark_complete_event.connect(self.Bench_Complete)
        self.bench_th.pred_event.connect(self.Bench_Pred)
        self.bench_th.img_refresh_event.connect(self.Bench_Img_Refresh)
        self.bench_en = False

    def SerialConnect(self):
        global serial_inst
        mode = self.pushButton.text()
        if (mode == "Connect"):
            try:
                serial_inst = Serial(self.PORT, self.BAUDRATE, timeout=None)
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
                serial_inst.close()
                serial_inst = None
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
        self.img_uart = getUartData(x, Q)
    
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
        global serial_inst
        # Write Input Data
        for i in range(0, 784, 16):
            tmp = encode(np.flip(TEST_DATA[i:i+16]), 16, 8)
            serial_inst.write(tmp.encode('ascii'))
            while serial_inst.inWaiting() == 0:
                continue
            while serial_inst.inWaiting() > 0:
                resp = serial_inst.read()
                if (resp != b'\x01'):
                    print(f"[ERROR] Resp value is not correct ({resp})")
        
        # Get Calculated Data
        result = ""
        while (len(result) < 32):
            while serial_inst.inWaiting() == 0:
                continue
            while serial_inst.inWaiting() > 0:
                tmp = serial_inst.read()
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
        global serial_inst
        pred_label = Inference(getUartData(self.img, 4), serial_inst)
        print(f"Pred:{pred_label}, True:{self.label}")
        self.PredlabelEdit.setText(f"{pred_label}")
        return pred_label
    
    @pyqtSlot()
    def Benchmark(self):
        if (self.bench_en == False):
            self.pushButton_4.setText("Stop")
            self.bench_th.start()
        else:
            self.pushButton_4.setText("Benchmark")
            self.bench_th.stop()

    def Bench_Img_Refresh(self, val):
        self.img = val[0]
        self.label = val[1]
        self.RefreshImg()
    
    def Bench_Pred(self, val):
        self.PredlabelEdit.setText(f"{val[0]}")
        self.progressBar.setValue(val[1])
        self.progressBar.setMaximum(val[2])
        self.ProgressLabel.setText(f"{val[1]}/{val[2]}")
        acc = val[3]/val[1]
        self.AcclineEdit.setText('%.3f' % acc)
    
    def Bench_Complete(self, val):
        self.progressBar.setValue(val[0])
        self.progressBar.setMaximum(val[0])
        self.AcclineEdit.setText(f"val[1]")


if __name__ == "__main__" :
    app = QApplication(sys.argv) 

    myWindow = WindowClass() 

    # Show Windows
    myWindow.show()

    # Execute Event Loop
    app.exec_()