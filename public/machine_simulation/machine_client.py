import schedule
import time
import socket
import threading
import json
from machine_class import Machine

SERVER_HOST = '127.0.0.1'
SERVER_PORT = 4000

Running = True
pr = 0
# Crea un socket TCP/IP
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Conecta el socket al servidor
client_socket.connect((SERVER_HOST, SERVER_PORT))
print("Conectado al servidor")

# Creamos la máquina
my_machine = Machine(3,2)

def Shift():
    global client_socket, pr

    #Producimos
    pr += my_machine.Work()
    production = [my_machine.ID, pr]

    #Si la maquina tiene error
    if my_machine.hasError():
        error_id = my_machine.getFaultMode()
        production.append(error_id)
    
    #Mandamos el arreglo como json
    json_data = json.dumps(production)

    print(f"Machine {my_machine.ID}, just generated", production)

    # Envía el mensaje al servidor
    client_socket.sendall(json_data.encode('utf-8'))

    #Reviso de nuevo si tenemos un error, para terminar la conexion
    if my_machine.hasError():
        raise ValueError('Some error happened')

    #Recibimos
    response = client_socket.recv(1024)
    hold = response.decode('utf-8')
    
    if hold == "1":
        print('Holding production...', pr)
    else:
        pr = 0

try:
    #Enviamos nuestro ID primero
    client_socket.send(str(my_machine.ID).encode(('utf-8')))

    schedule.every(5).seconds.do(Shift)
    while Running:
        schedule.run_pending()
        time.sleep(1)
except ValueError as e:
    print(e)
except KeyboardInterrupt as k:
    print('Forcecully closed connection')
finally:
    # Cierra la conexión con el servidor
    client_socket.close()
    print("Conexión cerrada")