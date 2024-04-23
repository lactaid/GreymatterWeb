CREATE TRIGGER oeee_visual.after_error_instance_insert
AFTER INSERT ON oeee_visual.error_instance
FOR EACH ROW
    UPDATE oeee_visual.machine
    SET state = 'Blocked'
    WHERE idMachine = NEW.Machine_ID;

DROP TRIGGER oeee_visual.before_error_instance_insert;
DELIMITER //
CREATE TRIGGER oeee_visual.before_error_instance_insert
BEFORE INSERT ON oeee_visual.error_instance
FOR EACH ROW
BEGIN
    DECLARE existe INT;
    SET existe = 0;
    
    -- Verificar si la tupla ya existe
    SELECT COUNT(*) INTO existe FROM oeee_visual.error_instance 
    WHERE finished_time IS NULL
    AND Machine_ID = NEW.Machine_ID
    AND Error_time >= curdate()
	AND Error_time < curdate() + INTERVAL 1 DAY;
    
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La máquina ya tiene un error';
    END IF;
END; 
//
/*Transacción para reparar una máquina*/
#Buscamos el error
SELECT ID_ErrorInstance, Error_time FROM oeee_visual.error_instance
WHERE Machine_ID = 1
ORDER BY Error_time desc
LIMIT 1;

#Actualizamos el finished_time
UPDATE oeee_visual.repair
SET op_status = 'Successful', Finished_time = NOW();

#Actualizamos la máquina
UPDATE oeee_visual.machine
SET repair.state = 'Operative'
WHERE idMachine = 1;
