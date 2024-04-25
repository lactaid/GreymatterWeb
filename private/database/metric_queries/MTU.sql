WITH WORKING AS (
SELECT coalesce(SUM(TIMESTAMPDIFF(SECOND, Asigned_time, Finished_time)), 0) as time_working
FROM oeee_visual.error_instance
INNER JOIN
	oeee_visual.repair on repair.ErrorInstance = error_instance.ID_ErrorInstance
WHERE
	finished_time IS NOT NULL
	AND Error_time >= CURDATE()
	AND Error_time < CURDATE() + INTERVAL 1 DAY),
    
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
WHERE 
	Error_time >= curdate()
	AND Error_time < curdate() + INTERVAL 1 DAY)
    
SELECT time_working/error_happening as MTU FROM WORKING, SHOULD_WORK;