/*Disponibilidad*/
WITH T_FUNC AS (
SELECT 
    SUM(
        IF(finished_time IS NULL, 
		   TIMESTAMPDIFF(SECOND, error_time, NOW()), 
		   TIMESTAMPDIFF(SECOND, error_time, finished_time)
           ))
    AS Total_Inactive_Time
FROM 
    oeee_visual.error_instance
WHERE Machine_ID = 1
AND Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY)

SELECT (TIMESTAMPDIFF(SECOND, '2024-04-05 10:00:00', NOW()) - Total_Inactive_Time ) / 
		TIMESTAMPDIFF(SECOND, '2024-04-05 10:00:00', NOW()) as Disponibilidad FROM T_FUNC;

/*Rendimiento*/
WITH R_PROD AS (
SELECT SUM(produced) as Real_production
FROM oeee_visual.production
WHERE Machine_ID = 1
AND production_time >= curdate()
AND production_time < curdate() + INTERVAL 1 DAY),

T_FUNC AS (
SELECT 
    SUM(TIMESTAMPDIFF(SECOND, Error_time, Finished_time))
    AS Total_Inactive_Time
FROM 
    oeee_visual.error_instance
WHERE Machine_ID = 1
AND Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY),

Speed AS (
SELECT Avg_pr as Speed FROM oeee_visual.machine
INNER JOIN oeee_visual.type
WHERE idMachine = 1
AND machine.type = type.idtype)

SELECT Real_production / (Speed * (TIMESTAMPDIFF(SECOND, '2024-04-05 12:00:00', NOW()) - Total_Inactive_Time) / 3600) as Rendimiento FROM R_PROD, Speed, T_Func;

/*Calidad, de momento asumimos que hay n = 88 producciones buenas*/
SELECT 4 / SUM(produced) as Calidad
FROM oeee_visual.production
WHERE Machine_ID = 1
AND production_time >= curdate()
AND production_time < curdate() + INTERVAL 1 DAY;

/*MTTR
Nota: ¿Debemos detectar el número total de reparaciones o el número total de fallos?
, ¿qué le pasa a esta métrica si no se repara la máquina?*/
SELECT 
    AVG(
        IF(finished_time IS NULL, 
		   TIMESTAMPDIFF(SECOND, error_time, NOW()), 
		   TIMESTAMPDIFF(SECOND, error_time, finished_time)
           )
    ) AS MTTR
FROM 
    oeee_visual.error_instance
WHERE Machine_ID = 1
AND Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY;


/*MTBF*/
SELECT 
    (Total_Active_Time / NULLIF(total_errors, 0)) as MTBF 
FROM 
    (SELECT 
        TIMESTAMPDIFF(SECOND, '2024-04-05 10:00:00', NOW()) - SUM(
            IF(finished_time IS NULL, 
                TIMESTAMPDIFF(SECOND, error_time, NOW()), 
                TIMESTAMPDIFF(SECOND, error_time, finished_time)
            )) AS Total_Active_Time
    FROM 
        oeee_visual.error_instance
    WHERE 
        Machine_ID = 1
        AND Error_time >= CURDATE()
        AND Error_time < CURDATE() + INTERVAL 1 DAY) AS ACTIVITY,
    (SELECT 
        COUNT(*) as total_errors
    FROM 
        oeee_visual.error_instance
    WHERE 
        Machine_ID = 1
        AND Error_time >= CURDATE()
        AND Error_time < CURDATE() + INTERVAL 1 DAY) AS S_ERROR;
        
/*Utilizacion de tecnicos MTU
Nota: Asumimos que solo una persona trabaja */
WITH WORKING AS (
SELECT SUM(finished_time - asigned_time) as time_working
FROM oeee_visual.error_instance
INNER JOIN
	oeee_visual.repair on repair.ErrorInstance = error_instance.ID_ErrorInstance
WHERE
	finished_time IS NOT NULL),
    
SHOULD_WORK AS (
SELECT SUM(
	IF(finished_time IS NULL, 
		   TIMESTAMPDIFF(SECOND, error_time, NOW()), 
		   TIMESTAMPDIFF(SECOND, error_time, finished_time)
           )
) as error_happening
FROM oeee_visual.error_instance
LEFT JOIN
	oeee_visual.repair on repair.ErrorInstance = error_instance.ID_ErrorInstance
WHERE Machine_ID = 1
	AND Error_time >= curdate()
	AND Error_time < curdate() + INTERVAL 1 DAY)
    
SELECT time_working/error_happening as MTU FROM WORKING, SHOULD_WORK;
    
/*Production of machines individually*/
SELECT production_time, produced FROM oeee_visual.production 
WHERE Machine_ID = 1 AND production_time >= curdate() ORDER BY production_time ASC LIMIT 100;

/*Production of machines globally each hour*/
SELECT DATE_FORMAT(production_time, '%Y-%m-%d %H:00:00') AS Interval_Start, SUM(produced) as Production
FROM oeee_visual.production 
WHERE production_time >= curdate() 
GROUP BY Interval_Start 
ORDER BY Interval_Start ASC 
LIMIT 100;

/*Machine Selection*/
SELECT idMachine as ID, state as Estado FROM oeee_visual.machine;

/*Errores acumulados*/
SELECT Faultmode, COUNT(*) as Numero_errores
FROM oeee_visual.error_instance
INNER JOIN
	oeee_visual.error on error.idError = error_instance.ID_Error
GROUP BY ID_Error;

/*Errores cada 5 minutos*/
SELECT DATE_FORMAT(Error_time, '%Y-%m-%d %H:%i:00') AS Interval_Start, COUNT(*) as Fault_mode
FROM oeee_visual.error_instance
WHERE 1#Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY
GROUP BY Interval_Start ,
         ROUND(MINUTE(Error_time) / 5)
ORDER BY Interval_Start ASC 
LIMIT 100;