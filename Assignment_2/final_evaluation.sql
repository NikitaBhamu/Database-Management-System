-- query 1--
with recursive routes as (
				select 0 as dep, source_station_name , destination_station_name ,train_no 
				from train_info 
				where source_station_name = 'KURLA' 
				and train_no = 97131
				union all 
				select dep+1, table1.source_station_name , table1.destination_station_name, table1.train_no
				from routes inner join train_info as table1
				on routes.destination_station_name=table1.source_station_name 
				where dep < 2
				)
select distinct destination_station_name from routes
order by destination_station_name


--query 2--
with recursive table1 as (select * from train_info where train_info.day_of_arrival = train_info.day_of_departure),
routes as ( select destination_station_name, day_of_departure, day_of_arrival, 0 as hop
			from table1
			where source_station_name = 'KURLA'
			and train_no = 97131
			union all
			select table1.destination_station_name,table1.day_of_departure, table1.day_of_arrival, hop+1 as hop
			from table1, routes
			where table1.source_station_name = routes.destination_station_name 
			and table1.day_of_departure = routes.day_of_arrival 
			and hop < 2
)
select distinct destination_station_name 
from routes 
order by destination_station_name asc;

--query 3--
with recursive table1 as (select * from train_info where train_info.day_of_arrival = train_info.day_of_departure),
routes as (
	select destination_station_name, day_of_departure, day_of_arrival, distance, 0 as hop
	from table1
	where source_station_name = 'DADAR'

	union all
	select table1.destination_station_name,table1.day_of_departure, table1.day_of_arrival, table1.distance+routes.distance ,hop+1 as hop
	from table1, routes
	where table1.source_station_name = routes.destination_station_name 
	and table1.day_of_departure = routes.day_of_arrival 
	and hop < 2
)
select distinct destination_station_name, distance, day_of_departure as day
from routes 
where destination_station_name <> 'DADAR'
order by destination_station_name asc, distance asc, day asc;

--query 4--
with recursive day_map as (select *
						   from (values (1, 'Monday'), (2, 'Tuesday'), (3, 'Wednesday'), (4, 'Thursday'), (5, 'Friday'), (6, 'Saturday'), (7, 'Sunday')) as x(num, day_of_week)),
dep_day_map as (select train_no, source_station_name,destination_station_name, arrival_time, departure_time , day_of_arrival, day_of_departure, day_map.num as dep_day
				from train_info, day_map
				where day_map.day_of_week = train_info.day_of_departure),
final_train_info as (select train_no, source_station_name,destination_station_name, arrival_time, departure_time , day_of_arrival, day_of_departure, dep_day, day_map.num as arr_day
 					 from dep_day_map, day_map
					 where day_map.day_of_week = dep_day_map.day_of_arrival
					 and ((dep_day < day_map.num) or (dep_day=day_map.num and departure_time < arrival_time))
					 ),
routes as ( select source_station_name, destination_station_name, arr_day, arrival_time, 0 as hop
			from final_train_info
			where source_station_name = 'DADAR'  
			union all
			select routes.source_station_name, final_train_info.destination_station_name,final_train_info.arr_day,final_train_info.arrival_time, hop + 1 as hop
			from final_train_info,routes
			where final_train_info.source_station_name=routes.destination_station_name
			and ((final_train_info.dep_day > routes.arr_day) or (final_train_info.dep_day = routes.arr_day AND final_train_info.departure_time >= routes.arrival_time))
			and hop < 2)		
select distinct destination_station_name
from routes 
where destination_station_name <> 'DADAR'
order by destination_station_name asc;

--query 5--
with recursive routes as(
	select source_station_name, destination_station_name, 0 as hop
    from train_info
    where source_station_name = 'CST-MUMBAI'
    union all
    select routes.source_station_name,train_info.destination_station_name, hop + 1 as hop
    FROM train_info, routes
    WHERE routes.destination_station_name = train_info.source_station_name
    AND train_info.source_station_name != 'VASHI'
    AND train_info.source_station_name != 'CST-MUMBAI'
    AND hop < 2
)
select count(*)
from routes
where routes.destination_station_name = 'VASHI';

--query 6--
with recursive routes as (
	select source_station_name, destination_station_name, ARRAY[source_station_name, destination_station_name]::varchar[] as visited, distance
	from train_info
	union all
	(
	with t2 as (select routes.source_station_name, train_info.destination_station_name, routes.visited || ARRAY[train_info.destination_station_name] as visited, train_info.distance+routes.distance as distance
		 from train_info, routes
		 where train_info.source_station_name = routes.destination_station_name
		 and (not(train_info.destination_station_name = ANY(routes.visited)))
		 and train_info.destination_station_name != routes.source_station_name
		 and array_length(visited, 1)<=7)
	select t2.*
	from t2 inner join
			    (	select source_station_name,destination_station_name, min(distance) as min_dist
			        from t2
			        group by source_station_name,destination_station_name
			    ) as temp_table 
		on t2.source_station_name = temp_table.source_station_name 
		and t2.destination_station_name = temp_table.destination_station_name 
		and t2.distance = temp_table.min_dist
	)
)
select distinct destination_station_name, source_station_name, min(distance) as distance
from routes 
where source_station_name<>destination_station_name 
group by source_station_name, destination_station_name
order by destination_station_name asc, source_station_name asc, distance asc;

--query 7--
with recursive routes as(
	select source_station_name,destination_station_name,0 as hop
	FROM train_info
	where source_station_name<>destination_station_name
	union
	select routes.source_station_name, train_info.destination_station_name, hop+1 as hop
	from train_info, routes
	where train_info.source_station_name = routes.destination_station_name
	and routes.source_station_name <> train_info.destination_station_name
	and hop < 3
) 
SELECT distinct source_station_name,destination_station_name
FROM routes
where source_station_name<>destination_station_name
ORDER BY source_station_name asc ,destination_station_name asc;

--query 8--
with recursive table1 as (select * from train_info where  train_info.day_of_departure = train_info.day_of_arrival),
routes AS (
	select distinct destination_station_name,table1.day_of_departure as days, ARRAY[source_station_name, destination_station_name]::varchar[] as visited, 0 as hop
	from table1
	where source_station_name = 'SHIVAJINAGAR'

	union all
	select distinct destination_station_name, day_of_departure, array_agg(distinct visited), max(hop)
	from
	(SELECT distinct train_info.destination_station_name, train_info.day_of_departure ,unnest(routes.visited || ARRAY[train_info.destination_station_name]) as visited, hop+1 as hop
	FROM table1 as train_info, routes
	WHERE train_info.source_station_name = routes.destination_station_name
	and not(train_info.destination_station_name = ANY(routes.visited))
	and train_info.day_of_arrival = routes.days
	) as t2
	group by t2.destination_station_name, t2.day_of_departure
)
SELECT DISTINCT destination_station_name, days as day
FROM routes 
where destination_station_name <> 'SHIVAJINAGAR'
ORDER BY destination_station_name ASC,day asc;

--query 9a--
with recursive table1 as (select * from train_info where  train_info.day_of_departure = train_info.day_of_arrival),
dest AS (
	select distinct destination_station_name,table1.day_of_departure as days, array[source_station_name, destination_station_name]::varchar[] as visited, 0 as hop, distance
	from table1
	where source_station_name = 'LONAVLA'

	union all
	select destination_station_name, day_of_departure, array_agg(distinct visited), max(hop), min(distance)
	from
	(select distinct train_info.destination_station_name, train_info.day_of_departure ,unnest(dest.visited || ARRAY[train_info.destination_station_name]) as visited, hop+1 as hop, (train_info.distance + dest.distance) as distance
	from table1 as train_info, dest
	where train_info.source_station_name = dest.destination_station_name
	and not(train_info.destination_station_name = any(dest.visited))
	and train_info.day_of_arrival = dest.days) as t2
	group by destination_station_name, day_of_departure
)
select distinct destination_station_name, min(distance) as distance, days as day
from dest 
group by destination_station_name, day
order by distance asc, destination_station_name asc, day asc;

--query 9n--
with recursive table1 as (select * from train_info where  train_info.day_of_departure = train_info.day_of_arrival),
dest AS (
	select distinct destination_station_name,table1.day_of_departure as days, array[source_station_name, destination_station_name]::varchar[] as visited, 0 as hop, distance
	from table1
	where source_station_name = 'LONAVLA'

	union all
	select destination_station_name, day_of_departure, array_agg(distinct visited), max(hop), min(distance)
	from
	(select distinct train_info.destination_station_name, train_info.day_of_departure ,unnest(dest.visited || ARRAY[train_info.destination_station_name]) as visited, hop+1 as hop, (train_info.distance + dest.distance) as distance
	from table1 as train_info, dest
	where train_info.source_station_name = dest.destination_station_name
	and not(train_info.destination_station_name = any(dest.visited))
	and train_info.day_of_arrival = dest.days) as t2
	group by destination_station_name, day_of_departure
)
select distinct destination_station_name, min(distance) as distance, days as day
from dest 
group by destination_station_name, day
order by destination_station_name asc,distance asc, day asc;

--query 10--
with recursive routes as (
	select source_station_name, destination_station_name, ARRAY[source_station_name, destination_station_name]::varchar[] as visited, distance
	from train_info
	union all
	(
	with t2 as (select routes.source_station_name, train_info.destination_station_name, routes.visited || ARRAY[train_info.destination_station_name] as visited, train_info.distance+routes.distance as distance
		 from train_info, routes
		 where train_info.source_station_name = routes.destination_station_name
		 and (not(train_info.destination_station_name = ANY(routes.visited)) OR train_info.destination_station_name=routes.source_station_name)
		 and routes.source_station_name != train_info.source_station_name)
	select t2.*
	from t2 inner join
			    (
			        SELECT source_station_name,destination_station_name, MAX(distance) as max_dist
			        FROM t2
			        GROUP BY source_station_name,destination_station_name
			    ) as temp_table 
		on t2.source_station_name = temp_table.source_station_name 
		and t2.destination_station_name = temp_table.destination_station_name 
		and t2.distance = temp_table.max_dist
	)
)
select source_station_name, max(distance) as distance
from routes 
where source_station_name=destination_station_name 
group by source_station_name
order by source_station_name asc;

--query 11--
WITH RECURSIVE routes AS (
    SELECT source_station_name, destination_station_name, 0 as hop
    FROM train_info
    UNION ALL
    SELECT  routes.source_station_name,train_info.destination_station_name, hop + 1 as hop 
    FROM train_info, routes
    WHERE routes.destination_station_name = train_info.source_station_name
    AND hop < 1
),
rechable_dest_count as (
    SELECT source_station_name, count(DISTINCT destination_station_name)
    FROM routes
    GROUP BY source_station_name
),
station_count AS (
    SELECT count(distinct stations) from (SELECT distinct destination_station_name as stations FROM train_info
    							  UNION 
    							  SELECT distinct source_station_name as stations FROM train_info) as t2 )
SELECT source_station_name
FROM rechable_dest_count,station_count
WHERE rechable_dest_count.count = station_count.count
ORDER BY source_station_name asc;

--query 12--
WITH RECURSIVE R(GAMEID,
				 HOMETEAMID,
				AWAYTEAMID,
				TEAMNAMES) AS
				((SELECT G.GAMEID,
				G.HOMETEAMID,
				G.AWAYTEAMID,
				T.NAME
			FROM GAMES G,
				TEAMS T
			WHERE G.HOMETEAMID = T.TEAMID
				AND T.NAME = 'Arsenal')
		UNION
			(SELECT G.GAMEID,
					G.HOMETEAMID,
					G.AWAYTEAMID,
					T.NAME
				FROM GAMES G,
					TEAMS T,
					R
				WHERE G.HOMETEAMID = T.TEAMID
					AND G.AWAYTEAMID = R.AWAYTEAMID))
SELECT DISTINCT(R.TEAMNAMES)
FROM R
WHERE R.TEAMNAMES <> 'Arsenal'
ORDER BY R.TEAMNAMES ASC;


--query 13--
SELECT DISTINCT NAME AS TEAMNAMES,
	GOALS,
	YEAR
FROM (
	(SELECT GOUT.HOMETEAMID AS HOMETEAMID,
			TOUT.NAME,
			GOUT.YEAR
		FROM GAMES GOUT,
			TEAMS TOUT
		WHERE GOUT.HOMETEAMID = TOUT.TEAMID
			AND GOUT.AWAYTEAMID in
				(SELECT DISTINCT(GIN.AWAYTEAMID)
					FROM GAMES GIN,
						TEAMS TIN1
					WHERE GIN.AWAYTEAMID = TIN1.TEAMID
						AND GIN.HOMETEAMID =
							(SELECT TIN2.TEAMID
								FROM TEAMS AS TIN2
								WHERE TIN2.NAME = 'Arsenal'))) T
	JOIN
	(SELECT ONE.TEAM,
			HGOALS + AGOALS AS GOALS
		FROM (
			(SELECT HOMETEAMID AS TEAM,
					SUM(HOMEGOALS) AS HGOALS
				FROM GAMES
				GROUP BY HOMETEAMID) AS ONE
		JOIN
			(SELECT AWAYTEAMID AS TEAM,
					SUM(AWAYGOALS) AS AGOALS
				FROM GAMES
				GROUP BY AWAYTEAMID) AS TWO ON ONE.TEAM = TWO.TEAM)) J ON T.HOMETEAMID = J.TEAM)
ORDER BY GOALS DESC,
	YEAR ASC
LIMIT 1;

--query 14a--
WITH R(TEAMNAMES,HOMEGOALS,AWAYGOALS) AS
	(SELECT TOUT.NAME,
			GOUT.HOMEGOALS,
			GOUT.AWAYGOALS
		FROM GAMES GOUT,
			TEAMS TOUT
		WHERE GOUT.HOMETEAMID = TOUT.TEAMID
			AND YEAR = '2015'
			AND GOUT.AWAYTEAMID in
				(SELECT DISTINCT(GIN.AWAYTEAMID)
					FROM GAMES GIN,
						TEAMS TIN1
					WHERE GIN.AWAYTEAMID = TIN1.TEAMID
						AND GIN.HOMETEAMID =
							(SELECT TIN2.TEAMID
								FROM TEAMS AS TIN2
								WHERE TIN2.NAME = 'Leicester')))
SELECT R.TEAMNAMES,
	HOMEGOALS - AWAYGOALS AS GOALDIFF
FROM R
WHERE R.TEAMNAMES <> 'Leicester'
	AND HOMEGOALS - AWAYGOALS > 3
ORDER BY GOALDIFF ASC,
	R.TEAMNAMES ASC;

--query 14b--
WITH R(TEAMNAMES,HOMEGOALS,AWAYGOALS) AS
	(SELECT TOUT.NAME,
			GOUT.HOMEGOALS,
			GOUT.AWAYGOALS
		FROM GAMES GOUT,
			TEAMS TOUT
		WHERE GOUT.HOMETEAMID = TOUT.TEAMID
			AND YEAR = '2015'
			AND GOUT.AWAYTEAMID in
				(SELECT DISTINCT(GIN.AWAYTEAMID)
					FROM GAMES GIN,
						TEAMS TIN1
					WHERE GIN.AWAYTEAMID = TIN1.TEAMID
						AND GIN.HOMETEAMID =
							(SELECT TIN2.TEAMID
								FROM TEAMS AS TIN2
								WHERE TIN2.NAME = 'Leicester')))
SELECT DISTINCT R.TEAMNAMES,
	HOMEGOALS - AWAYGOALS AS GOALDIFF
FROM R
WHERE R.TEAMNAMES <> 'Leicester'
	AND HOMEGOALS - AWAYGOALS > 3
ORDER BY GOALDIFF ASC,
	R.TEAMNAMES ASC;


--query 15a--
WITH RECURSIVE R(GAMEID,
				HOMETEAMID,
				AWAYTEAMID,
				TEAMNAMES) AS (
		(SELECT G.GAMEID,
				G.HOMETEAMID,
				G.AWAYTEAMID,
				T.NAME
			FROM GAMES G,
				TEAMS T
			WHERE G.HOMETEAMID = T.TEAMID
				AND T.NAME = 'Valencia')
	UNION
		(SELECT G.GAMEID,
				G.HOMETEAMID,
				G.AWAYTEAMID,
				T.NAME
			FROM GAMES G,
				TEAMS T,
				R
			WHERE G.HOMETEAMID = T.TEAMID
				AND G.AWAYTEAMID = R.AWAYTEAMID))
SELECT P.NAME,
	A.GOALS
FROM
	(SELECT P.PLAYERID,
			SUM(GOALS) AS GOALS
		FROM R,
			APPEARANCES A,
			PLAYERS P
		WHERE R.TEAMNAMES <> 'Valencia'
			AND R.GAMEID = A.GAMEID
			AND A.PLAYERID = P.PLAYERID
		GROUP BY P.PLAYERID) A,
	PLAYERS P
WHERE P.PLAYERID = A.PLAYERID
	AND A.GOALS =
		(SELECT MAX(GOALS)
			FROM
				(SELECT PLAYERID,
						SUM(GOALS) AS GOALS
					FROM APPEARANCES A,
						R
					WHERE A.GAMEID = R.GAMEID
						AND R.TEAMNAMES <> 'Valencia'
					GROUP BY PLAYERID) B)
					ORDER BY A.GOALS DESC, P.NAME ASC;


--query 15b--
WITH RECURSIVE R(GAMEID,
				HOMETEAMID,
				AWAYTEAMID,
				TEAMNAMES) AS (
		(SELECT G.GAMEID,
				G.HOMETEAMID,
				G.AWAYTEAMID,
				T.NAME
			FROM GAMES G,
				TEAMS T
			WHERE G.HOMETEAMID = T.TEAMID
				AND T.NAME = 'Valencia')
	UNION
		(SELECT G.GAMEID,
				G.HOMETEAMID,
				G.AWAYTEAMID,
				T.NAME
			FROM GAMES G,
				TEAMS T,
				R
			WHERE G.HOMETEAMID = T.TEAMID
				AND G.AWAYTEAMID = R.AWAYTEAMID))
SELECT P.NAME,
	A.GOALS
FROM
	(SELECT P.PLAYERID,
			SUM(GOALS) AS GOALS
		FROM R,
			APPEARANCES A,
			PLAYERS P
		WHERE R.GAMEID = A.GAMEID
			AND A.PLAYERID = P.PLAYERID
		GROUP BY P.PLAYERID) A,
	PLAYERS P
WHERE P.PLAYERID = A.PLAYERID
	AND A.GOALS =
		(SELECT MAX(GOALS)
			FROM
				(SELECT PLAYERID,
						SUM(GOALS) AS GOALS
					FROM APPEARANCES A,
						R
					WHERE A.GAMEID = R.GAMEID
					GROUP BY PLAYERID) B)
					ORDER BY A.GOALS DESC, P.NAME ASC;


--query 16--
WITH RECURSIVE R(GAMEID,
				HOMETEAMID,
				AWAYTEAMID,
				TEAMNAMES) AS (
				(SELECT G.GAMEID,
						G.HOMETEAMID,
						G.AWAYTEAMID,
						T.NAME
					FROM GAMES G,
						TEAMS T
					WHERE G.HOMETEAMID = T.TEAMID
						AND T.NAME = 'Everton')
			UNION
				(SELECT G.GAMEID,
						G.HOMETEAMID,
						G.AWAYTEAMID,
						T.NAME
					FROM GAMES G,
						TEAMS T,
						R
					WHERE G.HOMETEAMID = T.TEAMID
						AND G.AWAYTEAMID = R.AWAYTEAMID))
SELECT P.NAME,
	A.ASSISTS AS ASSISTCOUNTS
FROM
	(SELECT P.PLAYERID,
			SUM(ASSISTS) AS ASSISTS
		FROM R,
			APPEARANCES A,
			PLAYERS P
		WHERE R.TEAMNAMES <> 'Everton'
			AND R.GAMEID = A.GAMEID
			AND A.PLAYERID = P.PLAYERID
		GROUP BY P.PLAYERID) A,
	PLAYERS P
WHERE P.PLAYERID = A.PLAYERID
	AND A.ASSISTS =
		(SELECT MAX(ASSISTS)
			FROM
				(SELECT PLAYERID,
						SUM(ASSISTS) AS ASSISTS
					FROM APPEARANCES A,
						R
					WHERE A.GAMEID = R.GAMEID
						AND R.TEAMNAMES <> 'Everton'
					GROUP BY PLAYERID) B)
					ORDER BY A.ASSISTS DESC, P.NAME ASC;


--query 17--
WITH RECURSIVE R(GAMEID,
				HOMETEAMID,
				AWAYTEAMID,
				TEAMNAMES) AS (
				(SELECT G.GAMEID,
						G.HOMETEAMID,
						G.AWAYTEAMID,
						T.NAME
					FROM GAMES G,
						TEAMS T
					WHERE G.HOMETEAMID = T.TEAMID
						AND T.NAME = 'AC Milan')
			UNION
				(SELECT G.GAMEID,
						G.HOMETEAMID,
						G.AWAYTEAMID,
						T.NAME
					FROM GAMES G,
						TEAMS T,
						R
					WHERE G.HOMETEAMID = T.TEAMID
						AND G.YEAR = '2016'
						AND G.AWAYTEAMID = R.AWAYTEAMID))
SELECT P.NAME,
	A.SHOTS AS SHOTSCOUNT
FROM
	(SELECT P.PLAYERID,
			SUM(SHOTS) AS SHOTS
		FROM R,
			APPEARANCES A,
			PLAYERS P
		WHERE R.TEAMNAMES <> 'AC Milan'
			AND R.GAMEID = A.GAMEID
			AND A.PLAYERID = P.PLAYERID
		GROUP BY P.PLAYERID) A,
	PLAYERS P
WHERE P.PLAYERID = A.PLAYERID
	AND A.SHOTS =
		(SELECT MAX(SHOTS)
			FROM
				(SELECT PLAYERID,
						SUM(SHOTS) AS SHOTS
					FROM APPEARANCES A,
						R
					WHERE A.GAMEID = R.GAMEID
						AND R.TEAMNAMES <> 'AC Milan'
					GROUP BY PLAYERID) B)
ORDER BY A.SHOTS DESC,
	P.NAME ASC;


--query 18a--
WITH R(HOMETEAMID,
		TEAMNAMES,
		YEAR,
		GOALS) AS
	(SELECT GOUT.HOMETEAMID,
			TOUT.NAME,
			GOUT.YEAR,
			GOUT.AWAYGOALS
		FROM GAMES GOUT,
			TEAMS TOUT
		WHERE GOUT.HOMETEAMID = TOUT.TEAMID
			AND GOUT.YEAR = '2020'
			AND GOUT.AWAYTEAMID in
				(SELECT DISTINCT(GIN.AWAYTEAMID)
					FROM GAMES GIN,
						TEAMS TIN1
					WHERE GIN.AWAYTEAMID = TIN1.TEAMID
						AND GIN.HOMETEAMID =
							(SELECT TIN2.TEAMID
								FROM TEAMS AS TIN2
								WHERE TIN2.NAME = 'AC Milan')))
SELECT R.TEAMNAMES,
	'2020' AS YEAR
FROM R
WHERE R.TEAMNAMES <> 'AC Milan'
	AND R.GOALS = 0
GROUP BY R.TEAMNAMES
ORDER BY R.TEAMNAMES
LIMIT 5;


--query 18b--
WITH R(HOMETEAMID,
	TEAMNAMES,
	YEAR,
	GOALS) AS
	(SELECT GOUT.HOMETEAMID,
			TOUT.NAME,
			GOUT.YEAR,
			GOUT.AWAYGOALS
		FROM GAMES GOUT,
			TEAMS TOUT
		WHERE GOUT.HOMETEAMID = TOUT.TEAMID
			AND GOUT.YEAR = '2020'
			AND GOUT.AWAYTEAMID in
				(SELECT DISTINCT(GIN.AWAYTEAMID)
					FROM GAMES GIN,
						TEAMS TIN1
					WHERE GIN.AWAYTEAMID = TIN1.TEAMID
						AND GIN.HOMETEAMID =
							(SELECT TIN2.TEAMID
								FROM TEAMS AS TIN2
								WHERE TIN2.NAME = 'AC Milan')))
SELECT A.TEAMNAMES,
	'2020' AS YEAR
FROM
	(SELECT R.TEAMNAMES,
			SUM(GOALS) AS GOALS
		FROM R
		WHERE R.TEAMNAMES <> 'AC Milan'
		GROUP BY R.TEAMNAMES
		ORDER BY R.TEAMNAMES) A
WHERE A.GOALS = 0
LIMIT 5;


--query 19--
WITH R1 AS
	(SELECT GAMES.HOMETEAMID ,
			SUM(GAMES.HOMEGOALS) AS GOALS,
			GAMES.LEAGUEID
		FROM GAMES
		WHERE GAMES.YEAR = 2019
		GROUP BY(GAMES.HOMETEAMID,
												GAMES.LEAGUEID)),
	R2 AS
	(SELECT GAMES.AWAYTEAMID,
			SUM(GAMES.AWAYGOALS) AS GOALS,
			GAMES.LEAGUEID
		FROM GAMES
		WHERE GAMES.YEAR = 2019
		GROUP BY(GAMES.AWAYTEAMID,
												GAMES.LEAGUEID)),
	R3 AS
	(SELECT R1.HOMETEAMID AS TEAMID,
			R1.GOALS + R2.GOALS AS GOALS,
			R1.LEAGUEID
		FROM R1,
			R2
		WHERE R1.HOMETEAMID = R2.AWAYTEAMID
		ORDER BY GOALS DESC),
	R4 AS
	(SELECT MAX(GOALS) AS MAXGOALS,
			R3.LEAGUEID
		FROM R3
		GROUP BY (R3.LEAGUEID)),
	R5 AS
	(SELECT R3.TEAMID,
			R4.LEAGUEID,
			TEAMS.NAME,
			R3.GOALS
		FROM R3,
			R4,
			TEAMS
		WHERE R3.GOALS = R4.MAXGOALS
			AND R3.LEAGUEID = R4.LEAGUEID
			AND R3.TEAMID = TEAMS.TEAMID ),
	R6 AS
	(SELECT GAMES.AWAYTEAMID,
			R5.TEAMID,
			R5.LEAGUEID
		FROM GAMES,
			R5
		WHERE R5.TEAMID = GAMES.HOMETEAMID
		GROUP BY GAMES.AWAYTEAMID,
			R5.TEAMID,
			R5.LEAGUEID),
	R7 AS
	(SELECT DISTINCT GAMES.HOMETEAMID,
			R6.TEAMID,
			R6.LEAGUEID
		FROM GAMES,
			R6
		WHERE GAMES.HOMETEAMID != R6.TEAMID
			AND R6.AWAYTEAMID = GAMES.AWAYTEAMID
		GROUP BY GAMES.HOMETEAMID,
			R6.TEAMID,
			R6.LEAGUEID),
	R8 AS
	(SELECT DISTINCT GAMEID,
			R7.TEAMID,
			R7.LEAGUEID
		FROM R7,
			GAMES
		WHERE R7.HOMETEAMID = GAMES.AWAYTEAMID
			AND R7.LEAGUEID = GAMES.LEAGUEID
			AND GAMES.YEAR = 2019 ),
	R9 AS
	(SELECT APPEARANCES.PLAYERID,
			SUM(APPEARANCES.GOALS) AS GOALS,
			R8.TEAMID,
			R8.LEAGUEID
		FROM R8,
			APPEARANCES
		WHERE R8.GAMEID = APPEARANCES.GAMEID
			AND R8.LEAGUEID = APPEARANCES.LEAGUEID
		GROUP BY APPEARANCES.PLAYERID,
			R8.TEAMID,
			R8.LEAGUEID),
	A5 AS
	(SELECT R9.PLAYERID,
			R9.TEAMID,
			R9.GOALS,
			RANK() OVER(PARTITION BY R9.LEAGUEID
															ORDER BY R9.GOALS DESC) AS RANK
		FROM R9)
SELECT LEAGUES.NAME AS LEAGUENAME,
	PLAYERS.NAME AS PLAYERNAMES,
	A5.GOALS AS PLAYERTOPSCORE,
	TEAMS.NAME AS TEAMNAME,
	R5.GOALS AS TEAMTOPSCORE
FROM A5,
	PLAYERS,
	LEAGUES,
	TEAMS, R5
WHERE A5.PLAYERID = PLAYERS.PLAYERID
	AND A5.TEAMID = R5.TEAMID
	AND R5.TEAMID = TEAMS.TEAMID
	AND R5.LEAGUEID = LEAGUES.LEAGUEID
	AND A5.RANK = 1
ORDER BY PLAYERTOPSCORE DESC,
	TEAMTOPSCORE DESC,
	PLAYERNAMES;


--query 20--
WITH RECURSIVE PATHS AS
	(SELECT HOMETEAMID,
			AWAYTEAMID, array[HOMETEAMID,
			AWAYTEAMID] AS SEQUENCE,
			1 AS LEVEL
		FROM GAMES
		WHERE HOMETEAMID =
				(SELECT TEAMID
					FROM TEAMS
					WHERE NAME = 'Manchester United')
		UNION SELECT PATHS.HOMETEAMID,
			GAMES.AWAYTEAMID,
			SEQUENCE || GAMES.AWAYTEAMID,
			LEVEL + 1
		FROM PATHS
		INNER JOIN GAMES ON GAMES.HOMETEAMID = PATHS.AWAYTEAMID
		AND GAMES.AWAYTEAMID <> ALL(SEQUENCE)
		AND PATHS.HOMETEAMID <>
			(SELECT TEAMID
				FROM TEAMS
				WHERE NAME = 'Manchester City'))
SELECT MAX(PATHS.LEVEL)
FROM PATHS
WHERE AWAYTEAMID =
		(SELECT TEAMID
			FROM TEAMS
			WHERE NAME = 'Manchester City');


--query 21--
WITH RECURSIVE PATHS AS
	(SELECT HOMETEAMID,
			AWAYTEAMID, array[HOMETEAMID,
			AWAYTEAMID] AS SEQUENCE,
			1 AS LEVEL
		FROM GAMES
		WHERE HOMETEAMID =
				(SELECT TEAMID
					FROM TEAMS
					WHERE NAME = 'Manchester United')
		UNION SELECT PATHS.HOMETEAMID,
			GAMES.AWAYTEAMID,
			SEQUENCE || GAMES.AWAYTEAMID,
			LEVEL + 1
		FROM PATHS
		INNER JOIN GAMES ON GAMES.HOMETEAMID = PATHS.AWAYTEAMID
		AND GAMES.AWAYTEAMID <> ALL(SEQUENCE)
		AND PATHS.HOMETEAMID <>
			(SELECT TEAMID
				FROM TEAMS
				WHERE NAME = 'Manchester City'))
SELECT COUNT(*)
FROM PATHS
WHERE AWAYTEAMID =
		(SELECT TEAMID
			FROM TEAMS
			WHERE NAME = 'Manchester City');

--query 22--
WITH RECURSIVE R AS
	(SELECT DISTINCT HOMETEAMID,
			AWAYTEAMID,
			LEAGUEID
		FROM GAMES),
	PATHS AS
	(SELECT DISTINCT HOMETEAMID,
			AWAYTEAMID,
			LEAGUEID, array[HOMETEAMID,
			AWAYTEAMID] AS PATH,
			1 AS LEVEL
		FROM R
		UNION SELECT PATHS.HOMETEAMID,
			R.AWAYTEAMID,
			R.LEAGUEID,
			PATH || R.AWAYTEAMID,
			LEVEL + 1
		FROM R
		INNER JOIN PATHS ON PATHS.AWAYTEAMID = R.HOMETEAMID
		AND PATHS.LEAGUEID = R.LEAGUEID
		AND NOT(R.AWAYTEAMID = ANY(PATH))),
	MAX_LEAGUE AS
	(SELECT LEAGUEID,
			MAX(PATHS.LEVEL) AS BEST
		FROM PATHS
		GROUP BY LEAGUEID)
SELECT DISTINCT LEAGUES.NAME AS LEAGUENAME,
	T1.NAME AS TEAMANAME,
	T2.NAME AS TEAMBNAME,
	PATHS.LEVEL AS COUNT
FROM PATHS
INNER JOIN LEAGUES ON LEAGUES.LEAGUEID = PATHS.LEAGUEID
INNER JOIN MAX_LEAGUE ON MAX_LEAGUE.LEAGUEID = PATHS.LEAGUEID
INNER JOIN TEAMS AS T1 ON T1.TEAMID = PATHS.HOMETEAMID
INNER JOIN TEAMS AS T2 ON T2.TEAMID = PATHS.AWAYTEAMID
AND MAX_LEAGUE.BEST = PATHS.LEVEL
ORDER BY COUNT DESC, T1.NAME ASC,
	T2.NAME ASC,
	LEAGUENAME ASC;

