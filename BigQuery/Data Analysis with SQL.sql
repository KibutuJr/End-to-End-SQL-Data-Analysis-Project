SELECT * FROM `sql-project-486409.SQL_Project.rides` LIMIT 1000
SELECT * FROM `sql-project-486409.SQL_Project.users` LIMIT 1000
SELECT * FROM `sql-project-486409.SQL_Project.stations` LIMIT 1000



--- get count of rows per table
(SELECT COUNT(*) FROM `sql-project-486409.SQL_Project.rides` ) AS total_rides,
(SELECT COUNT(*) FROM `sql-project-486409.SQL_Project.users` ) AS total_users,
(SELECT COUNT(*) FROM `sql-project-486409.SQL_Project.stations` ) AS total_stations;

--- check missing values
SELECT


COUNTIF(ride_id IS NULL) AS null_ride_ids,
COUNTIF(user_id IS NULL) AS null_user_id,
COUNTIF(start_time IS NULL) AS null_start_time,
COUNTIF(end_time IS NULL) AS null_end_time

FROM `sql-project-486409.SQL_Project.rides`;

--- Summary statistics

SELECT
  MIN(distance_km) AS min_dist,
  MAX(distance_km) AS max_dist,
  AVG(distance_km) AS avg_dist,
  MIN(TIMESTAMP_DIFF(end_time, start_time, MINUTE)) AS min_duration_mins,
  MAX(TIMESTAMP_DIFF(end_time, start_time, MINUTE)) AS max_duration_mins,
  AVG(TIMESTAMP_DIFF(end_time, start_time, MINUTE)) AS avg_duration_mins

FROM `sql-project-486409.SQL_Project.rides`;

-- check for false starts for the rides

SELECT

  COUNTIF(TIMESTAMP_DIFF(end_time, start_time, MINUTE)<2) AS short_duration_trips,
  COUNTIF(distance_km = 0) AS zero_distance_trips

FROM `sql-project-486409.SQL_Project.rides`;

-- different memberships
SELECT
  u.membership_level,
  COUNT(r.ride_id) AS total_rides,
  AVG(r.distance_km) AS avg_distance_km,
  AVG(TIMESTAMP_DIFF(r.end_time, r.start_time, MINUTE)) AS avg_duration_mins

FROM `sql-project-486409.SQL_Project.rides` AS r
JOIN `sql-project-486409.SQL_Project.users` AS u
  ON r.user_id = u.user_id

GROUP BY u.membership_level
ORDER BY total_rides DESC;


--- peek hours
SELECT
  EXTRACT(HOUR FROM start_time) AS hour_of_day,
  COUNT(*) AS ride_count

FROM `sql-project-486409.SQL_Project.rides`

GROUP BY hour_of_day 
ORDER BY hour_of_day;


--- check for popular stations
SELECT
 s.station_name,
 COUNT(r.ride_id) AS total_starts

FROM `sql-project-486409.SQL_Project.rides` AS r
JOIN `sql-project-486409.SQL_Project.stations` AS s
  ON r.start_station_id = s.station_id

GROUP BY s.station_name
ORDER BY total_starts DESC
LIMIT 10;


--- Categorizing rides into short, medium and long

SELECT
    CASE
        WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) <= 10 THEN 'Short (<10m)'
        WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) BETWEEN 11 AND 30 THEN 'Medium (11-30m)'
        ELSE 'Long (>30m)'
    END AS ride_category,
    COUNT(*) count_of_rides

FROM `sql-project-486409.SQL_Project.rides`
GROUP BY ride_category
ORDER BY count_of_rides DESC;



--- Net flow for each station

WITH departures AS (

  SELECT start_station_id, COUNT(*) AS total_departures
  FROM `sql-project-486409.SQL_Project.rides`
  GROUP BY 1

),

arrivals AS (

  SELECT end_station_id, COUNT(*) AS total_arrivals
  FROM `sql-project-486409.SQL_Project.rides`
  GROUP BY 1

)

SELECT

  s.station_name,
  d.total_departures,
  a.total_arrivals,
  (a.total_arrivals - d.total_departures) AS net_flow

FROM `sql-project-486409.SQL_Project.stations` AS s
JOIN departures d ON s.station_id = d.start_station_id
JOIN arrivals a ON s.station_id = a.end_station_id

ORDER BY net_flow ASC;


-- user retention

WITH monthly_signups AS (
  
  SELECT 
    DATE_TRUNC(created_at, MONTH) AS signup_month,
    COUNT(user_id) AS new_user_count
  FROM `sql-project-486409.SQL_Project.users`
  GROUP BY signup_month
)

SELECT 
  signup_month,
  new_user_count,
  LAG(new_user_count) OVER (ORDER BY signup_month) AS previous_month_count,

  (new_user_count - LAG(new_user_count) OVER (ORDER BY signup_month) ) /
  NULLIF(LAG(new_user_count) OVER (ORDER BY signup_month),0) * 100 AS mon_growth

FROM monthly_signups
ORDER BY signup_month;



















