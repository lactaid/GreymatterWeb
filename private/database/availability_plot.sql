WITH RECURSIVE hours AS (
    SELECT 8 AS hour
    UNION ALL
    SELECT hour + 1
    FROM hours
    WHERE hour < 20
),
error_hours AS (
    SELECT
        Machine_ID,
        HOUR(error_time) AS start_hour,
        HOUR(finished_time) AS end_hour,
        error_time,
        finished_time
    FROM
        error_instance
    WHERE
        error_time >= CURDATE() AND error_time < CURDATE() + INTERVAL 1 DAY
		AND Machine_ID = 1
)
SELECT
    h.hour,
    3600 - SUM(
        CASE
            WHEN h.hour = e.start_hour AND h.hour = e.end_hour THEN TIMESTAMPDIFF(SECOND, error_time, finished_time)
            WHEN h.hour = e.start_hour THEN TIMESTAMPDIFF(SECOND, error_time, DATE_ADD(CURDATE() + INTERVAL h.hour HOUR, INTERVAL 1 HOUR))
            WHEN h.hour = e.end_hour THEN TIMESTAMPDIFF(SECOND, CURDATE() + INTERVAL h.hour HOUR, finished_time)
            ELSE 0
        END
    ) / 3600 AS availability
FROM
    hours h
LEFT JOIN
    error_hours e ON h.hour BETWEEN e.start_hour AND e.end_hour
GROUP BY
    h.hour
ORDER BY
    h.hour;