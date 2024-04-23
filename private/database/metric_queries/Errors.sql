SELECT COUNT(*) as Number_of_errors 
FROM oeee_visual.error_instance
WHERE Error_time >= curdate()
AND Error_time < curdate() + INTERVAL 1 DAY;