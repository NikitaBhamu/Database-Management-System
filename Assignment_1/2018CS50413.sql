--1--
WITH table1 AS
( SELECT a.driverid, MAX(a.milliseconds)
  FROM
      ( laptimes
        JOIN
        races
        ON (laptimes.raceid = races.raceid
            AND races.year = 2017)
        JOIN
        circuits
        ON (races.circuitid = circuits.circuitid
            AND circuits.country = 'Monaco')
      ) AS a
  GROUP BY a.driverid
)
SELECT b.driverid, b.forename, b.surname, b.nationality, c.max AS time
FROM drivers AS b
     JOIN table1 AS c
     ON b.driverid = c.driverid
WHERE c.max = (SELECT MAX(table1.max) FROM table1)
ORDER BY b.forename, b.surname, b.nationality;

--2--
SELECT d.name as constructor_name, d.constructorid, d.nationality, d.sum as points
FROM
     (SELECT c.constructorid, c.name, c.nationality, b.sum
      FROM ( SELECT a.constructorid, SUM(a.points)
             FROM ( SELECT constructorresults.constructorid, constructorresults.raceid, constructorresults.points
                    FROM constructorresults JOIN races
                    ON (constructorresults.raceid = races.raceid
                        AND races.year = 2012) ) AS a
             GROUP BY a.constructorid) as b
            JOIN
            constructors as c
      ON (b.constructorid = c.constructorid)
    )  AS d
ORDER BY d.sum DESC, d.name, d.nationality, d.constructorid
LIMIT 5;

--3--
SELECT drivers.driverid, drivers.forename, drivers.surname, b.points
FROM (SELECT a.driverid, SUM(a.points) as points
      FROM (SELECT results.driverid, results.points
            FROM results JOIN races
            ON (results.raceid = races.raceid
                AND races.year BETWEEN 2001 AND 2020)) AS a
      GROUP BY a.driverid) AS b JOIN drivers
ON (drivers.driverid = b.driverid)
WHERE b.points = (SELECT MAX(c.points)
                  FROM (SELECT a.driverid, SUM(a.points) as points
                        FROM (SELECT results.driverid, results.points
                              FROM results JOIN races
                              ON (results.raceid = races.raceid
                                  AND races.year BETWEEN 2001 AND 2020)) AS a
                        GROUP BY a.driverid) as c
                  )
ORDER BY drivers.forename, drivers.surname, drivers.driverid;

--4--
SELECT e.constructorid, e.name, e.nationality, e.points
FROM( SELECT d.constructorid, d.name, d.nationality, d.sum as points
      FROM
          ( SELECT c.constructorid, c.name, c.nationality, b.sum
            FROM ( SELECT a.constructorid, SUM(a.points)
                   FROM ( SELECT constructorresults.constructorid, constructorresults.raceid, constructorresults.points
                          FROM constructorresults JOIN races
                          ON (constructorresults.raceid = races.raceid
                              AND races.year BETWEEN 2010 AND 2020) ) AS a
                   GROUP BY a.constructorid) as b
                   JOIN constructors as c
                   ON (b.constructorid = c.constructorid
                 )
          )  AS d
     ) AS e
WHERE e.points = (SELECT MAX(f.points)
                 FROM (
                         SELECT d.constructorid, d.name, d.nationality, d.sum as points
                               FROM
                                   ( SELECT c.constructorid, c.name, c.nationality, b.sum
                                     FROM ( SELECT a.constructorid, SUM(a.points)
                                            FROM ( SELECT constructorresults.constructorid, constructorresults.raceid, constructorresults.points
                                                   FROM constructorresults JOIN races
                                                   ON (constructorresults.raceid = races.raceid
                                                       AND races.year BETWEEN 2010 AND 2020) ) AS a
                                            GROUP BY a.constructorid) as b
                                            JOIN constructors as c
                                            ON (b.constructorid = c.constructorid
                                          )
                                   )  AS d
                      ) AS f
                  )
ORDER BY e.name, e.nationality, e.constructorid;

--5--
SELECT b.driverid, b.forename, b.surname, c.wins AS race_wins
FROM (drivers AS b JOIN (SELECT a.driverid, SUM(a.positionorder) AS wins
                         FROM (SELECT *
                               FROM results
                               WHERE results.positionorder = 1) AS a
                         GROUP BY a.driverid) AS c
      ON b.driverid = c.driverid
    )
WHERE c.wins = (SELECT MAX(d.wins)
                FROM (SELECT a.driverid, SUM(a.positionorder) AS wins
                      FROM (SELECT *
                            FROM results
                            WHERE results.positionorder = 1) AS a
                      GROUP BY a.driverid) AS d)
ORDER BY  b.forename, b.surname,  b.driverid;

--6--
SELECT constructors.constructorid,  constructors.name, f.totalwins AS num_wins
FROM
(
   ( SELECT e.constructorid, e.totalwins
     FROM ( SELECT c.constructorid, SUM(c.wins) as totalwins
            FROM ((SELECT a.raceid, MAX(a.points) as maxpoints, 1 as wins
                   FROM constructorresults AS a
                   GROUP BY a.raceid) AS b JOIN constructorresults
                                           ON (constructorresults.raceid = b.raceid
                                               AND constructorresults.points = b.maxpoints
                                              )
                  ) AS c
             GROUP BY c.constructorid) AS e
     WHERE e.totalwins = ( SELECT MAX(d.totalwins)
                           FROM (  SELECT c.constructorid, SUM(c.wins) as totalwins
                                   FROM ((SELECT a.raceid, MAX(a.points) as maxpoints, 1 as wins
                                          FROM constructorresults AS a
                                          GROUP BY a.raceid) AS b JOIN constructorresults
                                                                  ON (constructorresults.raceid = b.raceid
                                                                      AND constructorresults.points = b.maxpoints
                                                                     )
                                        ) AS c
                                   GROUP BY c.constructorid
                                 ) AS d
                         )
    ) AS f
    JOIN constructors
    ON constructors.constructorid = f.constructorid
)
ORDER BY constructors.name, constructors.constructorid;

--7--
WITH winning_drivers AS
(
    WITH t AS
    (
      SELECT a.year, a.driverid, SUM(a.points)
          FROM
              (
                SELECT results.*, races.year
                FROM results JOIN races
                ON results.raceid = races.raceid
              ) AS a
          GROUP BY a.year, a.driverid
    ),
    maxinfo AS
    (
      SELECT t.year, MAX(t.sum)
      FROM t
      GROUP BY t.year
    )
    SELECT t.driverid
    FROM t JOIN maxinfo
    ON (t.year=maxinfo.year AND t.sum=maxinfo.max)
),
all_drivers AS
(
    SELECT a.driverid, SUM(a.points)
    FROM results AS a
    GROUP BY a.driverid
),
non_winning_drivers AS
(
    SELECT all_drivers.*
    FROM all_drivers
    WHERE all_drivers.driverid NOT IN (SElECT winning_drivers.driverid
                                       FROM winning_drivers)
)
SELECT a.driverid, b.forename, b.surname, a.sum AS points
FROM non_winning_drivers AS a JOIN drivers AS b
     ON (a.driverid = b.driverid)
ORDER BY sum DESC, b.forename, b.surname, a.driverid
LIMIT 3;

--8--
SELECT e.driverid, e.forename, e.surname, f.num_countries
FROM drivers AS e
     JOIN (SELECT c.driverid, COUNT(DISTINCT c.country) as num_countries
           FROM (
                  SELECT a.raceid, a.driverid, b.country
                  FROM ( (SELECT *
                          FROM results
                          WHERE results.positionorder = 1) AS a
                          JOIN
                         (SELECT *
                          FROM races JOIN circuits
                          ON races.circuitid = circuits.circuitid) AS b
                          ON a.raceid = b.raceid
                        )
                 ) AS c
           GROUP BY c.driverid ) as f
     ON ( e.driverid = f.driverid
          AND f.num_countries = (SELECT MAX(d.num_countries)
                                   FROM (
                                          SELECT c.driverid, COUNT(DISTINCT c.country) as num_countries
                                          FROM (
                                                 SELECT a.raceid, a.driverid, b.country
                                                 FROM ( (SELECT *
                                                         FROM results
                                                         WHERE results.positionorder = 1) AS a
                                                         JOIN
                                                         (SELECT *
                                                          FROM races JOIN circuits
                                                                     ON races.circuitid = circuits.circuitid) AS b
                                                          ON a.raceid = b.raceid
                                                       )
                                                ) AS c
                                   GROUP BY c.driverid ) AS d
                                )
          )
ORDER BY e.forename, e.surname, e.driverid;

--9--
SELECT b.driverid, c.forename, c.surname, b.num_wins
FROM (
        (SELECT a.driverid, SUM(a.positionorder) AS num_wins
         FROM
            ( SELECT *
              FROM results
              WHERE (results.grid = 1 AND results.positionorder=1)
            ) AS a
         GROUP BY a.driverid
        ) AS b
        JOIN
        drivers AS c
        ON (b.driverid = c.driverid)
     )
ORDER BY b.num_wins DESC, c.forename, c.surname,  b.driverid
LIMIT 3;

--10--
WITH temptable AS
(
    SELECT f.raceid, f.num_stops, f.driverid, drivers.forename,
           drivers.surname, f.circuitid, f.name
    FROM (
            (
            SELECT d.*, e.circuitid, e.name FROM
            (
            SELECT c.raceid, c.driverid, MAX(c.stop) as num_stops
            FROM
              ( SELECT a.raceid, a.driverid, b.stop
                FROM((SELECT *
                      FROM results
                      WHERE results.positionorder = 1) AS a
                      JOIN pitstops AS b
                      ON (a.raceid = b.raceid
                          AND a.driverid = b.driverid)
                    )
              ) AS c
            GROUP BY c.raceid, c.driverid
            ) AS d
            JOIN
            (
            SELECT races.raceid, circuits.circuitid, circuits.name
            FROM races JOIN circuits
            ON (races.circuitid = circuits.circuitid)
            ) AS e
            ON (d.raceid = e.raceid)
            ) AS f
            JOIN
            drivers ON (drivers.driverid = f.driverid)
         )
    ORDER BY f.num_stops DESC
)
SELECT temptable.*
FROM temptable
WHERE (temptable.num_stops = (SELECT MAX(temptable.num_stops)
                              FROM temptable) )
ORDER BY temptable.forename, temptable.surname, temptable.name,
         temptable.circuitid, temptable.driverid;

--11--
SELECT *
FROM (
        SELECT b.raceid, c.name, c.location, b.num_collisions
        FROM
        ( SELECT a.raceid, SUM(a.collision) AS num_collisions
          FROM (
                SELECT results.*, 1 AS collision
                FROM results
                WHERE (results.statusid = 4)
              ) AS a
          GROUP BY a.raceid
        ) AS b
        JOIN
        ( SELECT races.raceid, circuits.name, circuits.location
          FROM races JOIN circuits
          ON races.circuitid = circuits.circuitid
        ) AS c
        ON (b.raceid = c.raceid)
        ORDER BY b.num_collisions DESC, c.name, c.location, b.raceid
     ) AS d
WHERE d.num_collisions = (  SELECT MAX(e.num_collisions)
                            FROM
                            (
                              SELECT b.raceid, c.name, c.location, b.num_collisions
                              FROM
                              ( SELECT a.raceid, SUM(a.collision) AS num_collisions
                                FROM (
                                      SELECT results.*, 1 AS collision
                                      FROM results
                                      WHERE (results.statusid = 4)
                                    ) AS a
                                GROUP BY a.raceid
                              ) AS b
                              JOIN
                              ( SELECT races.raceid, circuits.name, circuits.location
                                FROM races JOIN circuits
                                ON races.circuitid = circuits.circuitid
                              ) AS c
                              ON (b.raceid = c.raceid)
                              ORDER BY b.num_collisions DESC, c.name, c.location, b.raceid
                            ) AS e
                         )
ORDER BY d.name, d.location, d.raceid;

--12--
SELECT d.driverid, drivers.forename, drivers.surname, d.temp as count
FROM
(
    ( SELECT *
      FROM (  SELECT a.driverid, SUM(a.temp) as temp
              FROM
              (
               SELECT *, 1 AS temp
               FROM results
               WHERE (results.rank=1 AND results.positionorder=1)
              ) AS a
              GROUP BY a.driverid
           ) AS b
      WHERE b.temp = (SELECT MAX(c.temp)
                      FROM (SELECT a.driverid, SUM(a.temp) as temp
                            FROM
                            (
                             SELECT *, 1 AS temp
                             FROM results
                             WHERE (results.rank=1 AND results.positionorder=1)
                            ) AS a
                            GROUP BY a.driverid) AS c
                     )
      ) AS d
      JOIN
      drivers ON (drivers.driverid = d.driverid )
)
ORDER BY drivers.forename, drivers.surname, d.driverid;

--13--
WITH data1 AS
(
    SELECT a.year, a.constructorid,  SUM(a.points) AS points
    FROM ( SELECT constructorresults.constructorid, constructorresults.raceid, constructorresults.points, races.year
           FROM constructorresults JOIN races ON (constructorresults.raceid = races.raceid) ) AS a
    GROUP BY a.year, a.constructorid
),
firstposition_table AS
(
    SELECT data1.year, data1.constructorid, data1.points AS max_points
    FROM data1, (SELECT b.year, MAX(b.points) AS max_points
                 FROM data1 AS b
                 GROUP BY b.year) AS a
    WHERE (data1.year = a.year AND data1.points = a.max_points)
),
data2 AS
(
    SELECT data1.*
    FROM data1, firstposition_table
    WHERE((data1.year, data1.constructorid, data1.points) NOT IN (SELECT * FROM firstposition_table))
),
secondposition_table AS
(
    SELECT data2.year, data2.constructorid, data2.points AS second_maxpoints
    FROM data2, (SELECT b.year, MAX(b.points) AS max_points
                 FROM data2 AS b
                 GROUP BY b.year) AS a
    WHERE (data2.year = a.year AND data2.points = a.max_points)
),
difference_table AS
(
    SELECT firstposition_table.year, firstposition_table.constructorid AS max_cons,
           firstposition_table.max_points, secondposition_table.constructorid AS sec_cons
           ,secondposition_table.second_maxpoints,
           (firstposition_table.max_points - secondposition_table.second_maxpoints) AS difference
    FROM firstposition_table JOIN secondposition_table
    ON (firstposition_table.year = secondposition_table.year)
)
SELECT p.year, p.point_diff, p.constructor1_id, q1.name AS constructor1_name, p.constructor2_id, q2.name constructor2_name
FROM
     (
      (
        SELECT DISTINCT difference_table.year, difference_table.difference AS point_diff,
                        difference_table.max_cons AS constructor1_id,
                        difference_table.sec_cons AS constructor2_id
        FROM difference_table
        WHERE difference_table.difference = (SELECT MAX(difference_table.difference)
                                             FROM difference_table) ) AS p
      JOIN constructors AS q1
      ON (p.constructor1_id = q1.constructorid)
      JOIN constructors AS q2
      ON (p.constructor2_id = q2.constructorid)
    )
;

--14--
SELECT e.driverid, e.forename, e.surname, e.circuitId AS circuitId,
       e.country, e.position AS pos
FROM (
        SELECT a.driverid, c.forename, c.surname, b.circuitid,
               b.country, d.position
        FROM
        (SELECT results.raceid, results.driverid, races.circuitid
        FROM results JOIN races
        ON (results.raceid = races.raceid
            AND races.year = 2018
            AND results.positionorder = 1)
        ) AS a
        JOIN circuits AS b
        ON (a.circuitid = b.circuitid)
        JOIN drivers AS c
        ON (a.driverid = c.driverid)
        JOIN qualifying AS d
        ON (a.driverid=d.driverid AND a.raceid=d.raceid)

     ) AS e
WHERE e.position = (   SELECT MAX(f.position)
                       FROM (
                               SELECT a.driverid, c.forename, c.surname, b.circuitid,
                                      b.country, d.position
                               FROM
                               (SELECT results.raceid, results.driverid, races.circuitid
                               FROM results JOIN races
                               ON (results.raceid = races.raceid
                                   AND races.year = 2018
                                   AND results.positionorder = 1)
                               ) AS a
                               JOIN circuits AS b
                               ON (a.circuitid = b.circuitid)
                               JOIN drivers AS c
                               ON (a.driverid = c.driverid)
                               JOIN qualifying AS d
                               ON (a.driverid=d.driverid AND a.raceid=d.raceid)

                            ) AS f
                    )
ORDER BY e.forename DESC, e.surname, e.country, e.driverid,  e.circuitId;

--15--
SELECT f.constructorid, f.name, f.num
FROM (
        SELECT d.constructorid, e.name, d.failures AS num
        FROM
        ( SELECT c.constructorid, SUM(failures) AS failures
          FROM(
                SELECT a.raceid, a.constructorid, b.year, 1 AS failures
                FROM(
                      (SELECT *
                       FROM results
                       WHERE results.statusid = 5) AS a
                      JOIN
                      (SELECT *
                       FROM races
                       WHERE races.year >= 2000) AS b
                       ON (a.raceid = b.raceid)
                )
          ) AS c
          GROUP BY c.constructorid
        ) AS d
        JOIN
        constructors as e
        ON (d.constructorid = e.constructorid)
     ) AS f
WHERE f.num = (SELECT MAX(g.num)
               FROM (
                       SELECT d.constructorid, e.name, d.failures AS num
                       FROM
                       ( SELECT c.constructorid, SUM(failures) AS failures
                         FROM(
                               SELECT a.raceid, a.constructorid, b.year, 1 AS failures
                               FROM(
                                     (SELECT *
                                      FROM results
                                      WHERE results.statusid = 5) AS a
                                     JOIN
                                     (SELECT *
                                      FROM races
                                      WHERE races.year >= 2000) AS b
                                      ON (a.raceid = b.raceid)
                               )
                         ) AS c
                         GROUP BY c.constructorid
                       ) AS d
                       JOIN
                       constructors as e
                       ON (d.constructorid = e.constructorid)
                     ) AS g
                )
ORDER BY f.name, f.constructorid;

--16--
SELECT DISTINCT b.driverid, b.forename, b.surname
FROM(
        (SELECT *
        FROM results
        WHERE results.positionorder = 1) AS a
        JOIN
        drivers AS b
        ON (a.driverid = b.driverid AND b.nationality='American')
        JOIN
        (SELECT races.raceid
         FROM races JOIN circuits
         ON (races.circuitid = circuits.circuitid
             AND circuits.country = 'USA')
        ) AS c
        ON (a.raceid = c.raceid)
    )
ORDER BY  b.forename, b.surname, b.driverid
LIMIT 5;

--17 --
WITH t1 AS
(
   SELECT a.*
   FROM
       (
         (SELECT *
          FROM results
          WHERE (results.positionorder=1 OR results.positionorder=2)) AS a
          JOIN races
          ON (races.raceid = a.raceid
              AND races.year >= 2014)
       )
),
t2 AS
(
    SELECT d.constructorid, SUM(d.positionorder)
    FROM (
            SELECT f1.raceid, f1.constructorid, f1.positionorder
            FROM
                (
                  ( SELECT t1.raceid, t1.constructorid, t1.positionorder
                    FROM t1
                    WHERE t1.positionorder = 1) AS f1
                  JOIN
                  ( SELECT t1.raceid, t1.constructorid, t1.positionorder
                    FROM t1
                    WHERE t1.positionorder = 2) AS f2
                  ON (f1.raceid = f2.raceid AND f1.constructorid = f2.constructorid)
                )
    ) AS d
    GROUP BY d.constructorid
)
SELECT m.constructorid, n.name, m.sum AS count
FROM((
      SELECT t2.constructorid, t2.sum
      FROM t2
      WHERE t2.sum = (SELECT MAX(t2.sum) FROM t2)
     )AS m
      JOIN constructors AS n
      ON (m.constructorid = n.constructorid)
    )
;

--18--
WITH t AS
(
    SELECT a.driverid, SUM(a.position)
    FROM (
            SELECT *
            FROM laptimes
            WHERE (laptimes.position = 1)
         ) AS a
    GROUP BY a.driverid
)
SELECT b.driverid, c.forename, c.surname, b.sum AS num_laps
FROM(
       ( SELECT *
          FROM t
          WHERE t.sum = (SELECT MAX(t.sum) FROM t)
       ) AS b
       JOIN drivers AS c
       ON (b.driverid = c.driverid)
    )
;

--19--
SELECT b.driverid, b.forename, b.surname, c.podiums AS count
FROM (drivers AS b JOIN (SELECT a.driverid, SUM(a.podium) AS podiums
                         FROM (SELECT results.*, 1 AS podium
                               FROM results
                               WHERE results.positionorder BETWEEN 1 AND 3) AS a
                         GROUP BY a.driverid) AS c
      ON b.driverid = c.driverid
    )
WHERE c.podiums = (SELECT MAX(d.podiums)
                   FROM (SELECT a.driverid, SUM(a.podium) AS podiums
                         FROM (SELECT results.*, 1 AS podium
                               FROM results
                               WHERE results.positionorder BETWEEN 1 AND 3) AS a
                         GROUP BY a.driverid) AS d)
ORDER BY  b.forename, b.surname DESC,  b.driverid;

--20--
WITH t AS
(
  SELECT a.year, a.driverid, SUM(a.points)
      FROM
          (
            SELECT results.*, races.year
            FROM results JOIN races
            ON results.raceid = races.raceid
          ) AS a
      GROUP BY a.year, a.driverid
),
maxinfo AS
(
  SELECT t.year, MAX(t.sum)
  FROM t
  GROUP BY t.year
),
driverids AS
(
  SELECT a.driverid, SUM(a.champs)
  FROM (
          SELECT t.*, 1 AS champs
          FROM t JOIN maxinfo
          ON (t.year=maxinfo.year AND t.sum=maxinfo.max)
       ) AS a
  GROUP BY a.driverid
)
SELECT driverids.driverid, drivers.forename, drivers.surname,
       driverids.sum AS num_champs
FROM driverids JOIN drivers
ON (driverids.driverid = drivers.driverid)
ORDER BY num_champs DESC, drivers.forename, drivers.surname,
         driverids.driverid
LIMIT 5;
