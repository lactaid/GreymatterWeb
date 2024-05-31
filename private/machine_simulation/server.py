import schedule
import time
import mysql.connector
from getpass import getpass
import socket
import threading
import datetime
import json

#This function handles the database
accumulated_production = {}
insertable = True

#Esta función se encarga de validar que no existan errores
def ValidateError(id):
    conn = createConnection()
    with conn.cursor() as cursor:
            cursor.execute(f"""SELECT COUNT(*) FROM oeee_visual.error_instance
                            WHERE Machine_ID = {id} AND Finished_time IS NULL
                            AND Error_time >= curdate();""")
            result = cursor.fetchone()
            # Esperamos el numero de errores
            return result[0]


def insertError(id, error):
    conn = createConnection()
    with conn.cursor() as cursor:
            cursor.execute(f"""INSERT INTO oeee_visual.error_instance (ID_Error, Error_time, Machine_ID) VALUES 
	                        ({error}, NOW(), {id});""")
            conn.commit()
    conn.close()

def databaseDump():
    global accumulated_production, insertable

    if len(accumulated_production) < 1:
        return
    print('Dumping in database')
    #Evitamos que se inserte en la produccion mientras guardamos en base de datos
    insertable = False

    #Preparamos los datos a insertar

    data = [(key, value) for key, value in accumulated_production.items()]

    conn = createConnection()
    with conn.cursor() as cursor:
            query = f"INSERT INTO oeee_visual.production (Machine_ID, production_time, produced) VALUES (%s, NOW(), %s)"
            cursor.executemany(query, data)
            conn.commit()
    conn.close()
    
    #Borramos el diccionario y permitimos inserción de nuevo
    accumulated_production.clear()
    insertable = True

def handle_client(client_socket, address):
    global accumulated_production, insertable
    print(f"Conexión aceptada desde {address}")

    # Recibimos ID del cliente
    data = client_socket.recv(1024)
    
    machineid = data.decode('utf-8')

    has_active_error = ValidateError(machineid)
    if has_active_error > 0:
        print("The machine that attempted to connect has an active error")
        client_socket.close()
        return
        

    while True:
        # Recibe los datos del cliente
        data = client_socket.recv(1024)
        if not data:
            break

        # Obtiene los datos recibidos
        received_list = json.loads(data.decode('utf-8'))
        machineid = str(received_list[0])

        #Verificamos si la maquina tiene un error
        if len(received_list) > 2:
            errorid = int(received_list[2])
            #Lógica para mandar el error
            insertError(machineid, errorid)
            print('Error happened closing connection with machine: ', machineid)
            client_socket.close()
            return

        #Si no se puede insertar notificar a maquina cliente con un 1 para volver a mandarlo
        if not insertable:
            client_socket.send("1".encode('utf-8'))
            continue
        else:
            client_socket.send("0".encode('utf-8'))
        
        produced = int(received_list[1])

        if machineid in accumulated_production:
            accumulated_production[machineid] += produced
        else:
            accumulated_production[machineid] = produced


        print(f"Recibido de {address}: {received_list}")

    # Cierra la conexión con el cliente
    client_socket.close()

def start_server(host, port):
    # Crea un socket TCP/IP
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Asocia el socket al host y al puerto especificados
    server_socket.bind((host, port))

    # Empieza a escuchar por conexiones entrantes
    server_socket.listen(5)
    print(f"Servidor escuchando en {host}:{port}")

    while True:
        # Espera por conexiones entrantes
        client_socket, address = server_socket.accept()

        # Crea un hilo para manejar la conexión con el cliente
        client_handler = threading.Thread(target=handle_client, args=(client_socket, address))
        client_handler.start()


HOST = '127.0.0.1'  # Dirección IP del servidor
PORT = 4000
schedule.every(20).seconds.do(databaseDump)

server_thread = threading.Thread(target=start_server, args=(HOST, PORT))
server_thread.daemon = True
server_thread.start()

def createConnection():
    while True:
        try:
            conn = mysql.connector.connect(
                    host="localhost",
                    database="oeee_visual",
                    user="",
                    password=""
            )
            return conn
        except mysql.connector.Error as e:
            print("Error while connecting to MySQL", e)

try:    
    while True:
        schedule.run_pending()
        time.sleep(1)
except KeyboardInterrupt as e:
    print('Terminando')