SELECT
    SUM(
        IF(finished_time IS NULL, 
		   TIMESTAMPDIFF(SECOND, error_time, NOW()), 
		   TIMESTAMPDIFF(SECOND, error_time, finished_time)
           ))
    AS Total_Inactive_Time
FROM 
    oeee_visual.error_instance
WHERE Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY;