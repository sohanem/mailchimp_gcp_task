create or replace table reporting_london_bicycle.sohaney_report_london_bicyle_hires as
-- 1. # of rides started at a station on a particular start date
with 
start_rides as (select start_station_id as station_id, 
start_station_name as terminal_name,
extract(date from start_date) as ride_start_date,
count(distinct rental_id) as num_rides_started_at_stn
from
 `astute-atlas-348300.london_bicycles.cycle_hire`

group by 1,2,3),

-- 2. # of rides ended at a station on a particular end date
end_rides as (select end_station_id as station_id, 
end_station_name as terminal_name,
extract(date from end_date) as ride_end_date,
count(distinct rental_id) as num_rides_ended_at_stn
from 
 `astute-atlas-348300.london_bicycles.cycle_hire` 
group by 1,2,3),

-- 3. total duration of rides started at a station on a particular date
-- 4. weighted avg of all rides started at a station on a particular date 

other_aggs as (
    select
    start_station_id,
    extract(date from start_date) as ride_start_date,
    sum(duration) as total_ride_duration,
    count(rental_id) as num_rides,
    sum(duration) / count(rental_id) as avg_ride_duration,
from `astute-atlas-348300.london_bicycles.cycle_hire`

group by start_station_id,extract(date from start_date)) ,

-- 5. median duration of rides started at a station on a particular date
median_rides as (
 select
    start_station_id,
    extract(date from start_date) as ride_start_date,
    percentile_cont(duration,0.5) over (partition by start_station_id, extract(date from start_date)) as median_duration
from `astute-atlas-348300.london_bicycles.cycle_hire`
),

-- 6. The most common station that people rode to "from" that station on a particular day
most_common_dest as ( 
select start_station_id, 
extract(date from start_date) as ride_start_date,
end_station_id,
end_station_name,
count(rental_id)  as num_rentals
from `astute-atlas-348300.london_bicycles.cycle_hire`
group by 1,2,3,4
),
dest as (

select start_station_id, 
 ride_start_date,
 end_station_id,
 end_station_name
from
(
select start_station_id, 
 ride_start_date,
 end_station_id,
 end_station_name,
 row_number() over (partition by start_station_id, 
 ride_start_date order by num_rentals desc) as rank_rentals
 from most_common_dest ) as temp1
 where rank_rentals = 1
),

-- 7. The most common station that people rode from "to" that station on a particular day
most_common_source as (select end_station_id,
extract(date from end_date) as ride_end_date,
start_station_id,
start_station_name,
count(rental_id) as num_rentals
from `astute-atlas-348300.london_bicycles.cycle_hire`
group by 1,2,3,4
),
src as (
select end_station_id, 
 ride_end_date,
 start_station_id,
 start_station_name
from
(
select end_station_id, 
 ride_end_date,
 start_station_id,
 start_station_name,
 row_number() over (partition by end_station_id, 
 ride_end_date order by num_rentals desc) as rank_rentals
 from most_common_source ) as temp2
 where rank_rentals = 1
),

final_report as (
-- final joins to create the table
select coalesce(s.station_id,e.station_id) as station_id,
coalesce(s.terminal_name,e.terminal_name) as station_name,
coalesce(s.ride_start_date,e.ride_end_date) as report_date,
num_rides_started_at_stn,
num_rides_ended_at_stn,
/**total and average durationo of ride columns**/
o.total_ride_duration,
o.avg_ride_duration as avg_dur_rides_started_at_stn,
/**median ride duration**/
m.median_duration as median_ride_duration,
/**most common dest**/
d.end_station_id as most_common_destination_id,
d.end_station_name as most_common_destination_name,
/**most common start**/
sc.start_station_id as most_common_start_id,
sc.start_station_name as most_common_start_name
from start_rides s full outer join end_rides e
on s.station_id = e.station_id
and s.ride_start_date = e.ride_end_date

left join other_aggs o
 on s.station_id = o.start_station_id
 and s.ride_start_date = o.ride_start_date

 left join median_rides m
 on s.station_id = m.start_station_id
 and s.ride_start_date = m.ride_start_date

 left join dest d
 on s.station_id = d.start_station_id
 and s.ride_start_date = d.ride_start_date

 left join src sc
 on e.station_id = sc.end_station_id
 and e.ride_end_date = sc.ride_end_date

 group by 1,2,3,4,5,6,7,8,9,10,11,12

)

select *  from final_report ;
