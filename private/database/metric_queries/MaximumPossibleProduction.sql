SELECT 
	SUM(Avg_pr*TIMESTAMPDIFF(SECOND, CONCAT(CURRENT_DATE(), ' 10:00:00'), NOW())/3600) as MPP
FROM 
    oeee_visual.machine
INNER JOIN oeee_visual.type ON type.idType = machine.type
WHERE machine.state != 'Out';