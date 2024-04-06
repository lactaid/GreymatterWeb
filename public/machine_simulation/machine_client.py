import schedule
import time
import mysql.connector
from getpass import getpass
from machine_class import Machine

try:
    oeee_db = mysql.connector.connect(
        host="localhost",
        database="oeee_visual",
        user="root", #Preferably create user with only insert permission
        password="" #Remember to change password
    )
    if oeee_db.is_connected():
        cursor = oeee_db.cursor()
        cursor.execute("select database();")
        record = cursor.fetchone()
        print("You're connected to database: ", record)
except mysql.connector.Error as e:
    oeee_db.close()
    print("Error while connecting to MySQL", e)
finally:
    if 'oeee_db' in locals() and oeee_db.is_connected():
        cursor.close()
#Inicializar el La maquina
my_machine = Machine(1, 5)
flag = True

def Shift():
    production = my_machine.Work()

    if my_machine.hasError():
        error_id = my_machine.getFaultMode()
        with oeee_db.cursor() as cursor:
            cursor.execute(f"""INSERT INTO oeee_visual.error_instance (ID_Error, Error_time, Machine_ID) VALUES 
	                        ({error_id}, NOW(), {my_machine.ID});""")
            oeee_db.commit()
        raise ValueError("Machine got an error")
        
    print("Machine just generated: ", production)

    with oeee_db.cursor() as cursor:
        cursor.execute(f"""INSERT INTO oeee_visual.production (Machine_ID, production_time, produced) VALUES
                ({my_machine.ID}, NOW(), {production});""")
        oeee_db.commit()

try:
    schedule.every(10).seconds.do(Shift)

    while True:
        schedule.run_pending()
        time.sleep(1)
except ValueError as e:
    print(e)
except mysql.connector.Error as e:
    print("Error while connecting to MySQL", e)
finally:
    if 'oeee_db' in locals() and oeee_db.is_connected():
        oeee_db.close()
        print("MySQL connection is closed")
