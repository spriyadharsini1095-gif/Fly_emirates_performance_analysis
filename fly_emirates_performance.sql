SHOW VARIABLES LIKE 'local_infile';
USE fly_emirates_performance;

LOAD DATA LOCAL INFILE 'C:/Users/Priya Parthiban/Downloads/flights.csv'
INTO TABLE flights
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

USE fly_emirates_performance;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/flights.csv'
INTO TABLE flights
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@year,@month,@day,@day_of_week,@airline,@flight_number,@tail_number,
 @origin_airport,@destination_airport,@scheduled_departure,@departure_time,
 @departure_delay,@taxi_out,@wheels_off,@scheduled_time,@elapsed_time,
 @air_time,@distance,@wheels_on,@taxi_in,@scheduled_arrival,@arrival_time,
 @arrival_delay,@diverted,@cancelled,@cancellation_reason,@air_system_delay,
 @security_delay,@airline_delay,@late_aircraft_delay,@weather_delay)
SET
 year                = NULLIF(@year,''),
 month               = NULLIF(@month,''),
 day                 = NULLIF(@day,''),
 day_of_week         = NULLIF(@day_of_week,''),
 airline             = NULLIF(@airline,''),
 flight_number       = NULLIF(@flight_number,''),
 tail_number         = NULLIF(@tail_number,''),
 origin_airport      = NULLIF(@origin_airport,''),
 destination_airport = NULLIF(@destination_airport,''),
 scheduled_departure = NULLIF(@scheduled_departure,''),
 departure_time      = NULLIF(@departure_time,''),
 departure_delay     = NULLIF(@departure_delay,''),
 taxi_out            = NULLIF(@taxi_out,''),
 wheels_off          = NULLIF(@wheels_off,''),
 scheduled_time      = NULLIF(@scheduled_time,''),
 elapsed_time        = NULLIF(@elapsed_time,''),
 air_time            = NULLIF(@air_time,''),
 distance            = NULLIF(@distance,''),
 wheels_on           = NULLIF(@wheels_on,''),
 taxi_in             = NULLIF(@taxi_in,''),
 scheduled_arrival   = NULLIF(@scheduled_arrival,''),
 arrival_time        = NULLIF(@arrival_time,''),
 arrival_delay       = NULLIF(@arrival_delay,''),
 diverted            = NULLIF(@diverted,''),
 cancelled           = NULLIF(@cancelled,''),
 cancellation_reason = NULLIF(@cancellation_reason,''),
 air_system_delay    = NULLIF(@air_system_delay,''),
 security_delay      = NULLIF(@security_delay,''),
 airline_delay       = NULLIF(@airline_delay,''),
 late_aircraft_delay = NULLIF(@late_aircraft_delay,''),
 weather_delay       = NULLIF(@weather_delay,'');
 SELECT COUNT(*) FROM flights;
SELECT * FROM flights LIMIT 10;
SELECT
    COUNT(*) - COUNT(departure_time)  AS missing_dep_time,
    COUNT(*) - COUNT(arrival_delay)   AS missing_arr_delay,
     sum(cancellation_reason is null) AS missing_reason,
     sum(cancelled = 1) as total_cancelled,
     sum(diverted=1) as total_diverted
FROM flights;
set sql_safe_updates=0;
##Fill missing values (the fillna(0) equivalent)
update flights
set 
departure_time=coalesce(departure_time,'0000'),
wheels_off     = COALESCE(wheels_off, '0000'),
    wheels_on      = COALESCE(wheels_on, '0000'),
    arrival_time   = COALESCE(arrival_time, '0000'),
    departure_delay= COALESCE(departure_delay, 0),
    taxi_out       = COALESCE(taxi_out, 0),
    taxi_in        = COALESCE(taxi_in, 0),
    elapsed_time   = COALESCE(elapsed_time, 0),
    air_time       = COALESCE(air_time, 0),
    arrival_delay  = COALESCE(arrival_delay, 0);
update flights
set
air_system_delay=coalesce(air_system_delay,0),
security_delay      = COALESCE(security_delay, 0),
    airline_delay       = COALESCE(airline_delay, 0),
    late_aircraft_delay = COALESCE(late_aircraft_delay, 0),
    weather_delay       = COALESCE(weather_delay, 0);
    ##Decode codes (the .map() dictionaries → CASE / lookup)
    alter table flights add column	cancellation_label varchar(20);
update flights
set cancellation_label=case cancellation_reason
when"A" then 'Carrier'
when"B" then "Weather"
when"C" then "National Air System"
when "D" then "Security"
else "Notcancelled"
end;
alter table flights add column day_name varchar(20);
update flights
set day_name=case day_of_week
when 1 then "Monday"
when 2 then "Tuesday"
when 3 then "Wednesday"
when 4 then "Thursday"
when 5 then "Friday"
when 6 then "Saturday"
when 7 then "Sunday"
end;
drop table if exists airline_lookup;
create table airline_lookup(code varchar(5) primary key,name varchar(50));
insert into airline_lookup values
('AA','American Airlines'),('AS','Alaska Airlines'),('B6','JetBlue Airways'),
 ('DL','Delta Air Lines'),('EV','ExpressJet Airlines'),('F9','Frontier Airlines'),
 ('HA','Hawaiian Airlines'),('MQ','Envoy Air'),('NK','Spirit Airlines'),
 ('OO','SkyWest Airlines'),('UA','United Airlines'),('US','US Airways'),
 ('VX','Virgin America'),('WN','Southwest Airlines');
 alter table flights
ADD COLUMN sched_dep_hhmm CHAR(5),
    ADD COLUMN dep_time_hhmm  CHAR(5),
    ADD COLUMN sched_arr_hhmm CHAR(5),
    ADD COLUMN arr_time_hhmm  CHAR(5);
    UPDATE flights
SET sched_dep_hhmm = CONCAT(LEFT(LPAD(scheduled_departure,4,'0'),2),':',RIGHT(LPAD(scheduled_departure,4,'0'),2)),
    dep_time_hhmm  = CONCAT(LEFT(LPAD(departure_time,4,'0'),2),':',RIGHT(LPAD(departure_time,4,'0'),2)),
    sched_arr_hhmm = CONCAT(LEFT(LPAD(scheduled_arrival,4,'0'),2),':',RIGHT(LPAD(scheduled_arrival,4,'0'),2)),
    arr_time_hhmm  = CONCAT(LEFT(LPAD(arrival_time,4,'0'),2),':',RIGHT(LPAD(arrival_time,4,'0'),2));
 alter table flights add column flight_date DATE;
 ##delay category column
 alter table flights
 add column departure_status varchar(15),
 add column arrival_status varchar(15);
UPDATE flights
SET departure_status = CASE
        WHEN departure_delay <  0  THEN 'Early'
        WHEN departure_delay =  0  THEN 'On Time'
        WHEN departure_delay <= 15 THEN 'Minor Delay'
        WHEN departure_delay <= 60 THEN 'Moderate Delay'
        ELSE 'Major Delay' END,
    arrival_status = CASE
        WHEN arrival_delay <  0  THEN 'Early'
        WHEN arrival_delay =  0  THEN 'On Time'
        WHEN arrival_delay <= 15 THEN 'Minor Delay'
        WHEN arrival_delay <= 60 THEN 'Moderate Delay'
        ELSE 'Major Delay' END;
        ##remove duplicates
        alter table flights add column id int auto_increment primary key first;
        delete f1 from flights f1
        join flights f2
        on f1.year=f2.year and f1.month=f2.month and f1.day=f2.day
        AND f1.flight_number=f2.flight_number AND f1.tail_number=f2.tail_number
  AND f1.origin_airport=f2.origin_airport
  AND f1.id > f2.id;
  SELECT COUNT(*) AS total,
       COUNT(*) - COUNT(DISTINCT year, month, day, flight_number,
                        tail_number, origin_airport) AS dupes
FROM flights;
create index idx_dedup
on flights(year,month,day,flight_number,tail_number,origin_airport);
SELECT COUNT(*) FROM flights;
SELECT COUNT(*) AS total,
       COUNT(*) - COUNT(DISTINCT year, month, day, flight_number,
                        tail_number, origin_airport) AS dupes
FROM flights;
SHOW INDEX FROM flights;
SELECT year, month, day, flight_number, tail_number, origin_airport,
       COUNT(*) AS copies
FROM flights
GROUP BY year, month, day, flight_number, tail_number, origin_airport
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;
CREATE TABLE flights_dedup LIKE flights;
INSERT INTO flights_dedup
SELECT * FROM flights
WHERE id IN (
    SELECT min_id FROM (
        SELECT MIN(id) AS min_id
        FROM flights
        GROUP BY year, month, day, flight_number,
                 tail_number, origin_airport
    ) AS keepers
);
SELECT COUNT(*) FROM flights_dedup;
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT year, month, day, flight_number, tail_number, origin_airport) AS distinct_keys
FROM flights;
DROP TABLE flights_dedup;
SELECT COUNT(*) AS total,
       COUNT(*) - COUNT(DISTINCT year, month, day, flight_number,
                        origin_airport, destination_airport,
                        scheduled_departure) AS true_dupes
FROM flights;
CREATE OR REPLACE VIEW flights_clean AS
SELECT f.id, f.flight_date, f.day_name,
       f.airline AS airline_code, a.name AS airline_name,
       f.flight_number, f.tail_number, f.origin_airport, f.destination_airport,
       f.sched_dep_hhmm, f.dep_time_hhmm, f.departure_delay, f.departure_status,
       f.sched_arr_hhmm, f.arr_time_hhmm, f.arrival_delay, f.arrival_status,
       f.distance, f.air_time, f.elapsed_time,
       f.diverted, f.cancelled, f.cancellation_label,
       f.air_system_delay, f.security_delay, f.airline_delay,
       f.late_aircraft_delay, f.weather_delay
FROM flights f
LEFT JOIN airline_lookup a ON f.airline = a.code;

SELECT * FROM flights_clean LIMIT 50;
##airlines tables
use fly_emirates_performance;
create table airlines(
IATA_CODE VARCHAR(5) PRIMARY KEY,
AIRLINE VARCHAR(60));
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/airlines.csv'
INTO TABLE airlines
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SHOW VARIABLES LIKE 'secure_file_priv';
INSERT INTO airlines (IATA_CODE, AIRLINE) VALUES
 ('UA','United Air Lines Inc.'),
 ('AA','American Airlines Inc.'),
 ('US','US Airways Inc.'),
 ('F9','Frontier Airlines Inc.'),
 ('B6','JetBlue Airways'),
 ('OO','Skywest Airlines Inc.'),
 ('AS','Alaska Airlines Inc.'),
 ('NK','Spirit Air Lines'),
 ('WN','Southwest Airlines Co.'),
 ('DL','Delta Air Lines Inc.'),
 ('EV','Atlantic Southeast Airlines'),
 ('HA','Hawaiian Airlines Inc.'),
 ('MQ','American Eagle Airlines Inc.'),
 ('VX','Virgin America');
select * from airlines;
select count(*) from airlines;
CREATE OR REPLACE VIEW flights_clean AS
SELECT f.id, f.flight_date, f.day_name,
       f.airline AS airline_code, a.AIRLINE AS airline_name,
       f.flight_number, f.tail_number, f.origin_airport, f.destination_airport,
       f.sched_dep_hhmm, f.dep_time_hhmm, f.departure_delay, f.departure_status,
       f.sched_arr_hhmm, f.arr_time_hhmm, f.arrival_delay, f.arrival_status,
       f.distance, f.air_time, f.elapsed_time,
       f.diverted, f.cancelled, f.cancellation_label,
       f.air_system_delay, f.security_delay, f.airline_delay,
       f.late_aircraft_delay, f.weather_delay
FROM flights f
LEFT JOIN airlines a ON f.airline = a.IATA_CODE;

SELECT * FROM flights_clean LIMIT 50;

SELECT DISTINCT f.airline
FROM flights f
LEFT JOIN airlines a ON f.airline = a.IATA_CODE
WHERE a.IATA_CODE IS NULL;
SELECT airline_code, airline_name, COUNT(*) AS flights
FROM flights_clean
GROUP BY airline_code, airline_name
ORDER BY flights DESC;
SELECT departure_status, COUNT(*) 
FROM flights_clean
GROUP BY departure_status;
##airports table
USE fly_emirates_performance;
CREATE TABLE airports (
    IATA_CODE VARCHAR(5) PRIMARY KEY,
    AIRPORT   VARCHAR(120),
    CITY      VARCHAR(60),
    STATE     VARCHAR(5),
    COUNTRY   VARCHAR(5),
    LATITUDE  DECIMAL(10,5),
    LONGITUDE DECIMAL(10,5)
) CHARACTER SET utf8mb4;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/airports.csv'
INTO TABLE airports
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(IATA_CODE, AIRPORT, CITY, STATE, COUNTRY, @lat, @lon)
SET LATITUDE  = NULLIF(@lat,''),
    LONGITUDE = NULLIF(@lon,'');
    SELECT COUNT(*) FROM airports; 
    SELECT * FROM airports WHERE LATITUDE IS NULL; 
UPDATE airports SET LATITUDE=30.35806, LONGITUDE=-85.79972 WHERE IATA_CODE='ECP';
UPDATE airports SET LATITUDE=44.65093, LONGITUDE=-73.46812 WHERE IATA_CODE='PBG';
UPDATE airports SET LATITUDE=29.95921, LONGITUDE=-81.33977 WHERE IATA_CODE='UST';
SELECT f.id, f.flight_date, f.airline_code,
       f.origin_airport,      o.AIRPORT AS origin_name,      o.CITY AS origin_city,
       f.destination_airport, d.AIRPORT AS dest_name,        d.CITY AS dest_city,
       f.departure_delay, f.arrival_delay, f.distance
FROM flights_clean f
LEFT JOIN airports o ON f.origin_airport      = o.IATA_CODE
LEFT JOIN airports d ON f.destination_airport = d.IATA_CODE
LIMIT 50;
SELECT DISTINCT f.origin_airport
FROM flights_clean f
LEFT JOIN airports o ON f.origin_airport = o.IATA_CODE
WHERE o.IATA_CODE IS NULL;
##Average delay per airline.
select a.airline as airline_name,round(avg(f.arrival_delay),1) as avg_arrival_delay from flights f
left join airlines a on f.airline=a.IATA_CODE
where f.cancelled=0 group by a.airline order by avg_arrival_delay desc;
##Cancellation rate by airport
select origin_airport,round(sum(cancelled)*100.0/count(*),2) as cancellation_rate_pct,
count(*) as total_flights from flights group by origin_airport order by cancellation_rate_pct desc;
##Flight volumes, delays, cancellations Volume and KPIs by airline
select a.AIRLINE as airline_name,count(*) as total_flights, sum(f.CANCELLED) AS cancelled_flights,
round(sum(f.cancelled)*100.0/count(*),2) as cancellation_rate_pct,
round(sum(case when f.cancelled=0 and f.arrival_delay<=15 then 1 else 0 end)*100.0/sum(case when f.cancelled=0 then 1 
else 0 end),2) as on_time_pct,round(avg(case when f.cancelled=0 then f.arrival_delay end),1) as avg_delay
from flights f left join airlines a on f.airline=a.IATA_CODE
group by a.airline order by total_flights desc;
##Volume by month
select month,count(*) as total_flights,round(avg(case when cancelled=0 then arrival_delay end),1)
as avg_delay, round (sum(cancelled)*100.0/count(*),2) as cancellation_rate_pct from flights
group by month order by month;
##delay by day of week
select DAY_OF_WEEK, COUNT(*) as Total_flights,round(avg(case when cancelled =0 then departure_delay end),1)
as Avg_dep_delay from flights group by DAY_OF_WEEK order by DAY_OF_WEEK;
##Cancellation reason breakdowm
select CANCELLATION_REASON,COUNT(*) as cancellations,round(count(*)*100.0/sum(count(*)) over (),1)
as pct_of_cancellations from flights where cancelled=1 group by CANCELLATION_REASON order by cancellations desc;
##Busiest route 
select ORIGIN_AIRPORT,DESTINATION_AIRPORT,count(*) as flights,round(avg(case when cancelled=0 then ARRIVAL_DELAY END),1)
as avg_delay from flights group by ORIGIN_AIRPORT,DESTINATION_AIRPORT order by flights desc limit 20;
UPDATE airports SET LATITUDE=30.35806, LONGITUDE=-85.79972 WHERE IATA_CODE='ECP';
UPDATE airports SET LATITUDE=44.65093, LONGITUDE=-73.46812 WHERE IATA_CODE='PBG';
UPDATE airports SET LATITUDE=29.95921, LONGITUDE=-81.33977 WHERE IATA_CODE='UST';
select * from airports;
SELECT IATA_CODE, AIRPORT, LATITUDE, LONGITUDE
FROM airports
WHERE IATA_CODE IN ('ECP','PBG','UST');
