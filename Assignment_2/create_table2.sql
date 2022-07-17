CREATE TABLE IF NOT EXISTS train_info (
    train_no bigint ,
    train_name text,
    distance bigint,
    source_station_name  text,
    departure_time time,
    day_of_departure  text,
    destination_station_name  text,
    arrival_time  time,
    day_of_arrival  text,
    CONSTRAINT train_no PRIMARY KEY (train_no)
);
