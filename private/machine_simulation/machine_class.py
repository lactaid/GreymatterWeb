import random

class Machine:
    def __init__(self, ID, rate):
        #number es el ID
        self.ID = ID
        #sockets viene a ser la producción de la máquina
        self.sockets = 0
        #Esta variable se utiliza para detectar si la máquina tuvo algún error
        self.possible_errors = [1,2,3]
        self.fault_mode = 0
        self.error = False
        #Simboliza la producción por unidad de tiempo
        self.rate = rate
        # print("Machine", self.ID, "created!")

    def newSocket(self):
        if not self.error:
            return self.rate + random.randint(-1, 1)

    def stop(self):
        self.error = True

    def getFaultMode(self):
        return self.fault_mode
    
    def hasError(self):
        return self.error

    def Work(self):
        bullet = random.randint(0,100)
        print('The bullet is: ', bullet)
        if(bullet > 100):
            self.stop()
            self.fault_mode = random.sample(self.possible_errors, 1)[0]
            print("Production stopped at machine", self.ID, "!")
            return 0
        else:
            return self.newSocket()
    
