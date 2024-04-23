SELECT 
	COUNT(*) * TIMESTAMPDIFF(SECOND, CONCAT(curdate(), ' 10:00:00'), NOW()) as EWT
FROM 
    oeee_visual.machine
WHERE machine.state != 'Out';