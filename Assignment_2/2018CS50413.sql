--1--
with t1 as
(
   select destination_station_name
   from train_info
   where (train_no = 97131 and source_station_name='KURLA')
),
t2 as
(
   select train_info.destination_station_name
   from (train_info join t1
         on (t1.destination_station_name = train_info.source_station_name)
        )
),
t3 as
(
    select train_info.destination_station_name
     from (train_info join t2
           on (t2.destination_station_name = train_info.source_station_name)
          )
)
select distinct a.destination_station_name
from (select t1.destination_station_name from t1
      UNION ALL
      select t2.destination_station_name from t2
      UNION ALL
      select t3.destination_station_name from t3
    ) as a
order by a.destination_station_name;

--2--
with t1 as
(
   select destination_station_name, day_of_arrival
   from train_info
   where (train_no = 97131 and source_station_name='KURLA'
          and day_of_departure = day_of_arrival)
),
t2 as
(
   select train_info.destination_station_name, train_info.day_of_arrival
   from (train_info join t1
         on (t1.destination_station_name = train_info.source_station_name
             and train_info.day_of_departure = train_info.day_of_arrival
             and t1.day_of_arrival = train_info.day_of_departure)
        )
),
t3 as
(
    select train_info.destination_station_name, train_info.day_of_arrival
     from (train_info join t2
           on (t2.destination_station_name = train_info.source_station_name
               and train_info.day_of_departure = train_info.day_of_arrival
               and t2.day_of_arrival = train_info.day_of_departure)
          )
)
select distinct a.destination_station_name
from (select t1.destination_station_name from t1
      UNION ALL
      select t2.destination_station_name from t2
      UNION ALL
      select t3.destination_station_name from t3
    ) as a
order by a.destination_station_name;

--3--
with recursive destination_distance(destination_station_name, distance, day_of_arrival, hops, mypath) as
(
   select distinct destination_station_name, distance, day_of_arrival, 0 as hops, ARRAY[source_station_name, destination_station_name] as mypath
   from train_info
   where (source_station_name = 'DADAR'
          and destination_station_name <> 'DADAR'
          and day_of_arrival = day_of_departure)
   UNION ALL
   select distinct t.destination_station_name, d.distance+t.distance as distance, t.day_of_arrival ,1+d.hops as hops, d.mypath||ARRAY[t.destination_station_name]
   from destination_distance as d, train_info as t
   where (
          t.source_station_name = d.destination_station_name
          and 1+d.hops <= 2
          and t.destination_station_name != ALL( d.mypath)
          and t.source_station_name <> t.destination_station_name
          and t.day_of_arrival = t.day_of_departure
          and t.day_of_departure = d.day_of_arrival
         )
)
select distinct destination_station_name, distance, day_of_arrival as day
from destination_distance
where destination_station_name <> 'DADAR'
order by destination_station_name, distance, day_of_arrival;


--4--
with recursive day_mapping as
(
  select 'Monday' as day, 1 as daynum
  UNION
  select 'Tuesday' as day, 2 as daynum
  UNION
  select 'Wednesday' as day, 3 as daynum
  UNION
  select 'Thursday' as day, 4 as daynum
  UNION
  select 'Friday' as day, 5 as daynum
  UNION
  select 'Saturday' as day, 6 as daynum
  UNION
  select 'Sunday' as day, 7 as daynum
),
destination_distance(destination_station_name, distance, day_of_arrival, arrival_time, hops, mypath) as
(
   select distinct destination_station_name, distance, day_of_arrival, arrival_time, 0 as hops, ARRAY[source_station_name, destination_station_name] as mypath
   from train_info
   where (source_station_name = 'DADAR'
          and destination_station_name <> 'DADAR')
   UNION ALL
   select distinct t.destination_station_name, d.distance+t.distance as distance, t.day_of_arrival , t.arrival_time, 1+d.hops as hops, d.mypath||ARRAY[t.destination_station_name]
   from destination_distance as d, train_info as t
   where (
          t.source_station_name = d.destination_station_name
          and 1+d.hops <= 2
          and t.destination_station_name != ALL( d.mypath)
          and t.source_station_name <> t.destination_station_name
          and ((
                  (select daynum from day_mapping where day = d.day_of_arrival)<(select daynum from day_mapping where day = t.day_of_departure)
               )
               or
               (
                 ((select daynum from day_mapping where day = d.day_of_arrival)=(select daynum from day_mapping where day = t.day_of_departure)
                  and d.arrival_time <= t.departure_time
                 )
               )
              )
         )
)
select distinct destination_station_name
from destination_distance
where destination_station_name <> 'DADAR'
order by destination_station_name;



--5--
with t1 as
(
   select train_info.source_station_name, train_info.destination_station_name, 0 as hop
   from train_info
   where (source_station_name='CST-MUMBAI' and destination_station_name='VASHI')
),
t2 as
(
   select a.source_station_name, b.destination_station_name, 1 as hop
   from (train_info as a join train_info as b
         on (a.source_station_name = 'CST-MUMBAI'
             and b.destination_station_name = 'VASHI'
             and a.destination_station_name = b.source_station_name
             and a.destination_station_name <> 'CST-MUMBAI'
             and a.destination_station_name <> 'VASHI'
            )
        )
),
t3 as
(
    select a.source_station_name, c.destination_station_name, 2 as hop
    from (train_info as a join train_info as b
           on (a.source_station_name = 'CST-MUMBAI'
               and a.destination_station_name = b.source_station_name
               and a.destination_station_name <> 'CST-MUMBAI'
               and a.destination_station_name <> 'VASHI'
               and b.source_station_name <> b.destination_station_name
              )
           join train_info as c
           on (c.destination_station_name = 'VASHI'
               and b.destination_station_name = c.source_station_name
               and b.destination_station_name <> 'CST-MUMBAI'
               and b.destination_station_name <> 'VASHI'
              )
          )
)
select count(a.*) as Count
from (select t1.source_station_name, t1.destination_station_name, t1.hop from t1
      UNION ALL
      select t2.source_station_name, t2.destination_station_name, t2.hop from t2
      UNION ALL
      select t3.source_station_name, t3.destination_station_name, t3.hop from t3
    ) as a
;

--6--
with recursive allPairs(source_station_name, destination_station_name, distance, traincount, path) as
(
  select source_station_name, destination_station_name, distance, 1 as traincount, ARRAY[source_station_name, destination_station_name]
  from train_info
  where destination_station_name <> source_station_name
  UNION
  select a.source_station_name, t.destination_station_name, a.distance+t.distance as distance, 1+a.traincount as traincount, a.path||ARRAY[t.destination_station_name]
  from allPairs as a, train_info as t
  where (a.destination_station_name = t.source_station_name
         and a.source_station_name <> t.destination_station_name
         and 1+a.traincount <= 6
         and t.destination_station_name != ALL(a.path)
        )
)
select destination_station_name, source_station_name, min(distance) as distance
from allPairs
group by source_station_name, destination_station_name
having (source_station_name <> destination_station_name)
order by destination_station_name, source_station_name;


--7--
with recursive allPairs(source_station_name, destination_station_name, traincount) as
(
  select source_station_name, destination_station_name, 1 as traincount
  from train_info
  where source_station_name <> destination_station_name
  UNION
  select a.source_station_name, t.destination_station_name, 1+a.traincount as traincount
  from allPairs as a, train_info as t
  where (a.destination_station_name = t.source_station_name
         and a.source_station_name <> t.destination_station_name
         and 1+a.traincount <= 4
        )
)
select distinct source_station_name, destination_station_name
from allPairs
where (source_station_name <> destination_station_name)
order by source_station_name, destination_station_name;


--8--
with recursive reachable(destination_station_name, day_of_arrival, path) as
(
  select t.destination_station_name, t.day_of_arrival, ARRAY[t.source_station_name, t.destination_station_name]
  from train_info as t
  where (t.source_station_name = 'SHIVAJINAGAR'
         and t.day_of_departure = t.day_of_arrival)
  UNION
  select t.destination_station_name, t.day_of_arrival, r.path || ARRAY[t.destination_station_name]
  from train_info as t, reachable as r
  where(r.destination_station_name = t.source_station_name
        and r.day_of_arrival = t.day_of_departure
        and t.day_of_arrival = t.day_of_departure
        and t.destination_station_name != ALL(r.path)
       )
)
select distinct destination_station_name, day_of_arrival as day
from reachable
where (destination_station_name <> 'SHIVAJINAGAR')
order by destination_station_name;


--9--
with recursive reachable(destination_station_name, distance, day_of_arrival, path) as
(
  select t.destination_station_name, t.distance, t.day_of_arrival, ARRAY[t.source_station_name, t.destination_station_name]
  from train_info as t
  where (t.source_station_name = 'LONAVLA'
         and t.day_of_departure = t.day_of_arrival)
  UNION
  select t.destination_station_name, t.distance+r.distance as distance ,t.day_of_arrival, r.path || ARRAY[t.destination_station_name]
  from train_info as t, reachable as r
  where(r.destination_station_name = t.source_station_name
        and r.day_of_arrival = t.day_of_departure
        and t.day_of_arrival = t.day_of_departure
        and t.destination_station_name != ALL(r.path)
       )
),
min_distances as
(
  select destination_station_name, min(distance) as mindistance
  from reachable
  group by destination_station_name
  having (destination_station_name <> 'LONAVLA')
)
select r.destination_station_name, r.distance, r.day_of_arrival as day
from reachable as r, min_distances as md
where ( r.destination_station_name = md.destination_station_name
        and r.distance = md.mindistance
      )
order by r.distance desc, r.destination_station_name;

--10--



--11--
with recursive allPairs(source_station_name, destination_station_name, hops) as
(
  select t.source_station_name, t.destination_station_name, 0 as hops
  from train_info as t
  UNION
  select p.source_station_name, t.destination_station_name, 1+p.hops
  from train_info as t, allPairs as p
  where(1+p.hops <= 1)
),
distinct_stations as
(
  select source_station_name as station from train_info
  UNION
  select destination_station_name as station from train_info
),
t as
(
  select distinct source_station_name, destination_station_name
  from allPairs
),
p as(
  select source_station_name, count(*)
  from t
  group by source_station_name
)
select source_station_name
from p
where count = (select count(*) from distinct_stations)
;

--12--
with resultant_teamids as
(
  select distinct t1.hometeamid
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'Arsenal')
         and t1.hometeamid <> t2.hometeamid
        )
)
select distinct teams.name as teamnames
from teams
where teams.teamid in (select * from resultant_teamids)
order by teams.name;


--13--
with resultant_teamids as
(
  select t1.hometeamid, t1.year
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'Arsenal')
         and t1.hometeamid <> t2.hometeamid
        )
),
hometeam_goals as
(
  select games.hometeamid, sum(games.homegoals) as homegoals
  from games
  group by games.hometeamid
),
awayteam_goals as
(
  select games.awayteamid, sum(games.awaygoals) as awaygoals
  from games
  group by games.awayteamid
),
total_goals as
(
  select t1.hometeamid as teamid, t1.homegoals+t2.awaygoals as score
  from (
         hometeam_goals as t1 full outer join awayteam_goals as t2
         on (t1.hometeamid = t2.awayteamid)
       )
  order by score desc
)
select teams.name as teamnames, total_goals.score as goals, resultant_teamids.year as year
from teams, total_goals, resultant_teamids
where (teams.teamid = resultant_teamids.hometeamid
       and teams.teamid = total_goals.teamid)
order by total_goals.score desc, resultant_teamids.year, teams.name
limit 1;


--14--
with resultant_teamids as
(
  select distinct t1.hometeamid
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'Leicester')
         and t1.hometeamid <> t2.hometeamid
         and t1.year = 2015
        )
),
difference_teams as
(
  select t.name as teamnames, g.homegoals-g.awaygoals as goaldiff
  from (games as g join teams as t
        on (g.awayteamid = t.teamid
            and g.year = 2015
            and g.hometeamid in (select * from resultant_teamids)
            and (g.homegoals-g.awaygoals) > 3
            and g.hometeamid <> g.awayteamid)
        )
  order by g.homegoals-g.awaygoals, t.name
)
select * from difference_teams;


--15--
with resultant_teamids as
(
  select distinct t1.hometeamid
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'Valencia')
         and t1.hometeamid <> t2.hometeamid
        )
),
required_games as
(
  select distinct g.gameid, g.leagueid
  from games as g
  where (g.hometeamid in (select * from resultant_teamids))
),
required_appearances as
(
  select b.playerid, sum(b.goals)
  from
  ( select a.playerid, a.goals
    from (required_games as r join appearances as a
          on (r.gameid = a.gameid and r.leagueid = a.leagueid))
  ) as b
  group by b.playerid
)
select p.name as playernames, ra.sum as goals
from players as p, required_appearances as ra
where (ra.sum = (select max(required_appearances.sum) from required_appearances)
       and p.playerid = ra.playerid
      )
order by ra.sum desc, p.name;


--16--
with resultant_teamids as
(
  select t1.hometeamid
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'Everton')
         and t1.hometeamid <> t2.hometeamid
        )
),
required_games as
(
  select g.gameid, g.leagueid
  from games as g
  where (g.hometeamid in (select * from resultant_teamids))
),
required_appearances as
(
  select b.playerid, sum(b.assists)
  from
  ( select a.playerid, a.assists
    from (required_games as r join appearances as a
          on (r.gameid = a.gameid and r.leagueid = a.leagueid))
  ) as b
  group by b.playerid
)
select p.name as playernames, ra.sum as assistscount
from players as p, required_appearances as ra
where (ra.sum = (select max(required_appearances.sum) from required_appearances)
       and p.playerid = ra.playerid
      )
order by ra.sum desc, p.name;


--17--
with resultant_teamids as
(
  select t1.awayteamid
  from games as t1, games as t2, teams
  where (t1.hometeamid = t2.hometeamid
         and t2.awayteamid = (select teams.teamid from teams
                             where teams.name = 'AC Milan')
         and t1.awayteamid <> t2.awayteamid
         and t1.year = 2016
        )
),
required_games as
(
  select g.gameid, g.leagueid
  from games as g
  where (g.awayteamid in (select * from resultant_teamids) and g.year=2016)
),
required_appearances as
(
  select b.playerid, sum(b.shots)
  from
  ( select a.playerid, a.shots
    from (required_games as r join appearances as a
          on (r.gameid = a.gameid and r.leagueid = a.leagueid))
  ) as b
  group by b.playerid
)
select p.name as playernames, ra.sum as shotscount
from players as p, required_appearances as ra
where (ra.sum = (select max(required_appearances.sum) from required_appearances)
       and p.playerid = ra.playerid
      )
order by p.name;


--18--
with resultant_teamids as
(
  select t1.hometeamid
  from games as t1, games as t2, teams
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = (select teams.teamid from teams
                             where teams.name = 'AC Milan')
         and t1.hometeamid <> t2.hometeamid
         and t1.year = 2020
        )
  union
  select t1.awayteamid
  from games as t1, games as t2, teams
  where (t1.hometeamid = t2.hometeamid
         and t2.awayteamid = (select teams.teamid from teams
                             where teams.name = 'AC Milan')
         and t1.awayteamid <> t2.awayteamid
         and t1.year = 2020
        )
),
required_games as
(
  select g.gameid, g.leagueid, g.hometeamid, g.awayteamid, g.year
  from games as g
  where (g.hometeamid in (select * from resultant_teamids)
         and g.year=2020 and g.awaygoals = 0)
)
select distinct teams.name as teamname, required_games.year as year
from (required_games join teams
      on (required_games.awayteamid = teams.teamid))
order by teams.name
limit 5;



--19--
with hometeams as
(
  select g.leagueid, g.gameid, g.hometeamid, g.homegoals
  from games as g
  where g.year = 2019
),
awayteams as
(
  select g.leagueid, g.gameid, g.awayteamid, g.awaygoals
  from games as g
  where g.year = 2019
),
all_teams as
(
  select h.leagueid, h.gameid, h.hometeamid as teamid, h.homegoals as goals
  from hometeams as h
  union
  select a.leagueid, a.gameid, a.awayteamid as teamid, a.awaygoals as goals
  from awayteams as a
),
all_teams_scores as
(
   select all_teams.leagueid, all_teams.teamid, sum(goals) as goals
   from all_teams
   group by all_teams.leagueid, all_teams.teamid
),
league_top_scores as
(
  select all_teams_scores.leagueid, max(all_teams_scores.goals)
  from all_teams_scores
  group by all_teams_scores.leagueid
),
league_top_scorers as
(
  select a.leagueid, a.teamid, a.goals as teamscore
  from league_top_scores as l, all_teams_scores as a
  where (a.leagueid = l.leagueid and a.goals = l.max)
),
teams_in_common as
(
  select distinct l.teamid, t1.hometeamid
  from games as t1, games as t2, league_top_scorers as l
  where (t1.awayteamid = t2.awayteamid
         and t2.hometeamid = l.teamid
         and t1.hometeamid <> t2.hometeamid
         and t1.year = 2019
        )
),
required_games as
(
  select distinct l.teamid, g.gameid, g.leagueid
  from games as g, league_top_scorers as l
  where (g.hometeamid in (select hometeamid from teams_in_common where teamid=l.teamid)
         and g.year=2019)
  union
  select distinct g.gameid, g.leagueid
  from games as g
  where (g.awayteamid in  (select hometeamid from teams_in_common where teamid=l.teamid)
         and g.year=2019)
)
select * from league_top_scorers;

--20--
with recursive path(hometeamid,awayteamid,pathlength, mypath) as
(
  select distinct hometeamid, awayteamid, 1 as pathlength, ARRAY[hometeamid,awayteamid] as mypath
  from games
  where (hometeamid = (select teamid from teams where name = 'Manchester United'))
  UNION
  select distinct path.hometeamid, games.awayteamid, (1+path.pathlength) as pathlength, path.mypath||ARRAY[games.awayteamid]
  from games, path
  where (path.awayteamid = games.hometeamid
         and path.hometeamid = (select teamid from teams where name = 'Manchester United')
         and games.awayteamid != ALL(path.mypath)
        )
)
select max(path.pathlength) as count from path
where (path.hometeamid = (select teamid from teams where name = 'Manchester United')
      and path.awayteamid = (select teamid from teams where name = 'Manchester City'));


--21--
with recursive path(hometeamid,awayteamid,pathlength, mypath) as
(
  select distinct hometeamid, awayteamid, 1 as pathlength, ARRAY[hometeamid,awayteamid] as mypath
  from games
  where (hometeamid = (select teamid from teams where name = 'Manchester United'))
  UNION
  select distinct path.hometeamid, games.awayteamid, (1+path.pathlength) as pathlength, path.mypath||ARRAY[games.awayteamid]
  from games, path
  where (path.awayteamid = games.hometeamid
         and path.hometeamid = (select teamid from teams where name = 'Manchester United')
         and games.awayteamid != ALL(path.mypath)
        )
)
select count(path.*) as count from path
where (path.hometeamid = (select teamid from teams where name = 'Manchester United')
      and path.awayteamid = (select teamid from teams where name = 'Manchester City'));


--22--
with recursive path(hometeamid,awayteamid,leagueid,pathlength, mypath) as
(
  select hometeamid, awayteamid, leagueid, 1 as pathlength, ARRAY[hometeamid,awayteamid] as mypath
  from games

  UNION

  select path.hometeamid,games.awayteamid, games.leagueid, (1+path.pathlength) as pathlength, path.mypath||ARRAY[games.awayteamid]
  from games, path
  where (path.awayteamid = games.hometeamid
         and games.leagueid = path.leagueid
         and games.awayteamid != ALL(path.mypath)
        )
),
table1 as
(
  select leagues.name as leaguename, t1.name as teamAname, t2.name as teamBname, path.pathlength as count
  from leagues, teams as t1, teams as t2, path
  where (leagues.leagueid = path.leagueid
         and t1.teamid = path.hometeamid
         and t2.teamid = path.awayteamid)
),
table2 as
(
  select table1.leaguename, max(table1.count) as maxcount
  from table1
  group by table1.leaguename
)
select distinct table1.leaguename, table1.teamAname, table1.teamBname, table1.count
from table1, table2
where(table1.leaguename = table2.leaguename
      and table1.count = table2.maxcount)
order by table1.count desc, table1.teamAname, table1.teamBname
;
