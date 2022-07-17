with recursive
    stations as (select distinct source_station_name from train_info union (select distinct destination_station_name from train_info)),
    journey as 
    (select source_station_name, destination_station_name, distance, day_of_arrival, 0 as hops, array[source_station_name, destination_station_name] as stations 
        from train_info 
    union all
    select j.source_station_name, t.destination_station_name, t.distance+j.distance, t.day_of_arrival, j.hops+1, j.stations || t.destination_station_name
    from train_info t, journey j 
    where t.source_station_name=j.destination_station_name and 
        t.source_station_name<>t.destination_station_name and
        t.destination_station_name != all(j.stations) and
        j.hops < 1),
    result as (select distinct source_station_name, destination_station_name from journey),
    temp as (select source_station_name, count(*) as count from result group by source_station_name),
    c as (select count(*) from (select distinct * from stations) as p)
select * from c;