SELECT 
  machine.idMachine AS ID, 
  machine.state AS Estado,
  IFNULL(production.TotalProduction, 0) AS TotalProduction,
  SUM(
    IF(
      finished_time IS NULL, 
      TIMESTAMPDIFF(SECOND, error_time, NOW()), 
      TIMESTAMPDIFF(SECOND, error_time, finished_time)
    )
  ) AS Inactive_Time,
  CASE
    WHEN EXISTS (
      SELECT 1 
      FROM oeee_visual.error_instance ei
      WHERE ei.Machine_ID = machine.idMachine
      AND ei.Error_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
      AND ei.finished_time IS NULL
    ) THEN TIMESTAMPDIFF(SECOND, (
      SELECT MAX(ei.Error_time) 
      FROM oeee_visual.error_instance ei
      WHERE ei.Machine_ID = machine.idMachine
      AND ei.Error_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
      AND ei.finished_time IS NULL
    ), NOW())
    WHEN EXISTS (
      SELECT 1 
      FROM oeee_visual.error_instance ei
      WHERE ei.Machine_ID = machine.idMachine
      AND ei.Error_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
      AND ei.finished_time IS NOT NULL
    ) THEN TIMESTAMPDIFF(SECOND, (
      SELECT MAX(ei.Finished_time) 
      FROM oeee_visual.error_instance ei
      WHERE ei.Machine_ID = machine.idMachine
      AND ei.Error_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
      AND ei.finished_time IS NOT NULL
    ), NOW())
    ELSE TIMESTAMPDIFF(SECOND, CONCAT(CURDATE(), ' 10:00:00'), NOW())
  END AS TS
FROM 
  oeee_visual.machine
LEFT JOIN (
  SELECT Machine_ID, SUM(produced) AS TotalProduction
  FROM oeee_visual.production
  WHERE production_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
  GROUP BY Machine_ID
) AS production ON machine.idMachine = production.Machine_ID
LEFT JOIN oeee_visual.error_instance ON machine.idMachine = error_instance.Machine_ID
AND error_instance.Error_time BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY
GROUP BY machine.idMachine;