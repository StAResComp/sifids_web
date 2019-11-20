-- stored procedures used by Shiny app

-- stored procedure for checking user details
CREATE OR REPLACE FUNCTION appLogin ( --{{{
  in_username TEXT,
  in_password TEXT
)
RETURNS TABLE (
  user_id INTEGER,
  user_role CHAR(1),
  vessel_id INTEGER,
  vessel_name VARCHAR(255),
  vessel_type CHAR(1)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_role, 
           COALESCE(u.vessel_id, u.traccar_id) AS vessel_id, 
           COALESCE(v.vessel_name, tv.device_name) AS vessel_name, 
           CASE WHEN u.vessel_id IS NOT NULL THEN 's'::CHAR(1)
                WHEN u.traccar_id IS NOT NULL THEN 't'::CHAR(1)
                ELSE NULL
            END AS vessel_type
      FROM app_users AS u
 LEFT JOIN tm_vessels AS v USING (vessel_id)
 LEFT JOIN traccar.traccar_devices AS tv ON u.traccar_id = tv.device_id
     WHERE user_name = in_username
       AND user_password = CRYPT(in_password, user_password)
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- dates for vessel
CREATE OR REPLACE FUNCTION datesForVessel ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  minDate DATE,
  maxDate DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(t.time_stamp)::DATE AS minDate,
           MAX(t.time_stamp)::DATE AS maxDate
      FROM tm_tracks AS t
INNER JOIN tm_trips AS tr USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND tr.vessel_id = u.vessel_id)
        OR (u.user_role = 'a' AND (in_vessels IS NULL OR tr.vessel_id = ANY(in_vessels)));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- data for heat map showing time spent (hauling) on map
CREATE OR REPLACE FUNCTION heatMapData ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  lat NUMERIC(15,12),
  long NUMERIC(15,12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude
      FROM tm_tracks AS t
INNER JOIN tm_trips AS tr USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE t.activity_id = 2 -- hauling
       AND t.dummy = 0 -- not dummy point
       AND (in_min_date IS NULL OR in_max_date IS NULL OR t.time_stamp BETWEEN in_min_date AND in_max_date)
       AND ((u.user_role = 'f' AND tr.vessel_id = u.vessel_id)
         OR (u.user_role = 'a' AND (in_vessels IS NULL OR tr.vessel_id = ANY(in_vessels))));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- data for revisits map
CREATE OR REPLACE FUNCTION revisitsMapData ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE
)
RETURNS TABLE (
  lat1 NUMERIC(15,12),
  long1 NUMERIC(15,12),
  lat2 NUMERIC(15,12),
  long2 NUMERIC(15,12),
  counts BIGINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.latitude1, g.longitude1, g.latitude2, g.longitude2, COUNT(*)
      FROM tm_grid AS g
INNER JOIN tm_tracks AS t USING (grid_id)
INNER JOIN tm_trips AS tr USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE dummy = 0
       AND (in_min_date IS NULL OR in_max_date IS NULL OR t.time_stamp BETWEEN in_min_date AND in_max_date)
       AND ((u.user_role = 'f' AND tr.vessel_id = u.vessel_id)
         OR (u.user_role = 'a' AND (in_vessels IS NULL OR tr.vessel_id = ANY(in_vessels))))
  GROUP BY g.grid_id
    HAVING COUNT(*) > 1
  ORDER BY COUNT(*) ASC;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- data for trips made by vessel
CREATE OR REPLACE FUNCTION trips ( --{{{
  in_user_id INTEGER,
  in_vessel_type CHAR(1),
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  trip_name VARCHAR(255),
  creels_low INTEGER,
  creels_high INTEGER,
  distance INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT tr.trip_id AS trip_id, tr.trip_name, tr.creels_low, tr.creels_high, (tr.distance / 1000)::INTEGER
      FROM tm_trips AS tr
INNER JOIN tm_tracks AS t USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (in_min_date IS NULL OR in_max_date IS NULL OR t.time_stamp BETWEEN in_min_date AND in_max_date)
       AND ((u.user_role = 'f' AND tr.vessel_id = u.vessel_id AND in_vessel_type = 's')
         OR (u.user_role = 'a' AND (in_vessels IS NULL OR tr.vessel_id = ANY(in_vessels))))
  GROUP BY tr.trip_id 
 UNION ALL
    SELECT tr.trip_id AS trip_id, tr.trip_name, NULL, NULL, NULL
      FROM traccar.traccar_trips AS tr
INNER JOIN traccar.traccar_track AS t USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (in_min_date IS NULL OR in_max_date IS NULL OR t.time_stamp BETWEEN in_min_date AND in_max_date)
       AND ((u.user_role = 'f' AND tr.device_id = u.traccar_id AND in_vessel_type = 't')
         OR (u.user_role = 'a' AND (in_vessels IS NULL OR tr.device_id = ANY(in_vessels))))
  GROUP BY tr.trip_id
  ORDER BY trip_id ASC;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessel/s
CREATE OR REPLACE FUNCTION vessels ( --{{{
  in_user_id INTEGER,
  in_vessel_type CHAR(1)
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name
      FROM tm_vessels AS v
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND v.vessel_id = u.vessel_id AND in_vessel_type = 's')
        OR (u.user_role = 'a')
 UNION ALL
    SELECT t.device_id, t.device_name
      FROM traccar.traccar_devices AS t
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND t.device_id = u.traccar_id AND in_vessel_type = 't')
        OR (u.user_role = 'a');
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get tracks from trips
CREATE OR REPLACE FUNCTION tracksFromTrips ( --{{{
  in_user_id INTEGER,
  in_vessel_type CHAR(1),
  in_trip_name VARCHAR(255)[]
)
RETURNS TABLE (
  trip_id INTEGER,
  lat NUMERIC(15,12),
  long NUMERIC(15,12),
  activity INTEGER,
  segment INTEGER,
  trip_name VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude, t.activity_id, t.segment, tr.trip_name
      FROM tm_tracks AS t
INNER JOIN tm_trips AS tr USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND tr.vessel_id = u.vessel_id AND in_vessel_type = 's')
         OR (u.user_role = 'a'))
       AND tr.trip_name = ANY(in_trip_name)
 UNION ALL
    SELECT t.trip_id, t.latitude, t.longitude, 1, 1, tr.trip_name -- 1, 1 for not hauling and segment 1
      FROM traccar.traccar_track AS t
INNER JOIN traccar.traccar_trips AS tr USING (trip_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND tr.device_id = u.vessel_id AND in_vessel_type = 't')
         OR (u.user_role = 'a'))
       AND tr.trip_name = ANY(in_trip_name);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- dates for vessel (using Fish 1 forms)
CREATE OR REPLACE FUNCTION datesForVesselFish1 ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  minDate DATE,
  maxDate DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(f.fishing_activity_date)::DATE AS minDate,
           MAX(f.fishing_activity_date)::DATE AS maxDate
      FROM fish1_row AS f
INNER JOIN fish1_header AS fh USING (upload_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
        OR (u.user_role = 'a' AND (in_vessels IS NULL OR fh.vessel_id = ANY(in_vessels)));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- catch per species
-- for table
CREATE OR REPLACE FUNCTION catchPerSpecies ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_port_departure TEXT,
  in_port_landing TEXT,
  in_fo TEXT,
  in_species TEXT[]
)
RETURNS TABLE (
  species TEXT,
  weight NUMERIC
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT f.species, SUM(f.weight)
      FROM fish1_row AS f
INNER JOIN fish1_header AS fh USING (upload_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
         OR (u.user_role = 'a' AND (in_vessels IS NULL OR fh.vessel_id = ANY(in_vessels))))
       AND f.species IS NOT NULL AND f.species <> ''
       AND (in_species IS NULL OR f.species = ANY(in_species))
       AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_activity_date BETWEEN in_min_date AND in_max_date)
       AND (in_port_departure IS NULL OR fh.port_of_departure = in_port_departure)
       AND (in_port_landing IS NULL OR fh.port_of_landing = in_port_landing)
       AND (in_fo IS NULL OR fh.fishery_office = in_fo)
  GROUP BY f.species
  ORDER BY f.species;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- catch per species per week
-- use CTE to get every week between start and finish
-- not just weeks that have data
-- for graph
CREATE OR REPLACE FUNCTION catchPerSpeciesWeek ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_port_departure TEXT,
  in_port_landing TEXT,
  in_fo TEXT,
  in_species TEXT[]
)
RETURNS TABLE (
  week TEXT,
  weight NUMERIC,
  species TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    WITH RECURSIVE weeks (start, finish, week) AS (
                   SELECT s.start, s.finish, s.week
                     FROM (SELECT COALESCE(in_min_date, MIN(fishing_activity_date)) AS start,
                                  COALESCE(in_max_date, MAX(fishing_activity_date)) AS finish,
                                  TO_CHAR(COALESCE(in_min_date, MIN(fishing_activity_date)), 'IYYY-IW') AS week
                             FROM fish1_row LIMIT 1) AS s
                UNION ALL 
                   SELECT w.start + INTERVAL '1 WEEK' AS start, w.finish, TO_CHAR(w.start + INTERVAL '1 WEEK', 'IYYY-IW') AS week
                     FROM weeks AS w
                    WHERE start < finish)
    SELECT ww.week, SUM(r.weight), r.species
      FROM weeks AS ww
 LEFT JOIN (
           SELECT TO_CHAR(f.fishing_activity_date, 'IYYY-IW') AS week, f.weight, f.species, fh.vessel_id
             FROM fish1_row AS f
       INNER JOIN fish1_header AS fh USING (upload_id)
       INNER JOIN app_users AS u ON user_id = in_user_id
            WHERE f.species IS NOT NULL AND f.species <> ''
              AND (in_species IS NULL OR f.species = ANY(in_species))
              AND (in_min_date IS NULL OR in_max_date IS NULL OR f.fishing_activity_date BETWEEN in_min_date AND in_max_date)
              AND (in_port_departure IS NULL OR fh.port_of_departure = in_port_departure)
              AND (in_port_landing IS NULL OR fh.port_of_landing = in_port_landing)
              AND (in_fo IS NULL OR fh.fishery_office = in_fo)
              AND ((u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
                OR (u.user_role = 'a' AND (in_vessels IS NULL OR fh.vessel_id = ANY(in_vessels))))
           ) AS r USING (week)
  GROUP BY ww.week, r.species
  ORDER BY ww.week, r.species;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels with Fish1 forms
CREATE OR REPLACE FUNCTION vesselsFish1 ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name
      FROM vessels AS v
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND v.vessel_id = u.vessel_id)
        OR (u.user_role = 'a' AND (in_vessels IS NULL OR v.vessel_id = ANY(in_vessels)));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get port of departure
CREATE OR REPLACE FUNCTION portOfDeparture ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  port_of_departure TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT fh.port_of_departure
      FROM fish1_header AS fh
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY fh.port_of_departure;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get port of landing
CREATE OR REPLACE FUNCTION portOfLanding ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  port_of_landing TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT fh.port_of_landing
      FROM fish1_header AS fh
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY fh.port_of_landing;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get fishery office/s
CREATE OR REPLACE FUNCTION fisheryOffice ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  fishery_office TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT fh.fishery_office
      FROM fish1_header AS fh
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY fh.fishery_office;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get species
CREATE OR REPLACE FUNCTION species ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  species TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT f.species
      FROM fish1_row AS f
INNER JOIN fish1_header AS fh USING (upload_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND fh.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY f.species;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get dates for effort
CREATE OR REPLACE FUNCTION datesEffort ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  mindate DATE,
  maxdate DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(midweek), MAX(midweek) 
      FROM tm_effort AS e
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND e.vessel_id = u.vessel_id)
        OR (u.user_role = 'a');
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels for effort
CREATE OR REPLACE FUNCTION vesselsEffort ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name
      FROM tm_effort AS e
INNER JOIN tm_vessels AS v USING (vessel_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND e.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY v.vessel_name;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get species for effort
CREATE OR REPLACE FUNCTION speciesEffort ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  species VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT e.species
      FROM tm_effort AS e
INNER JOIN tm_vessels AS v USING (vessel_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE (u.user_role = 'f' AND e.vessel_id = u.vessel_id)
        OR (u.user_role = 'a')
  ORDER BY e.species;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort using distance
CREATE OR REPLACE FUNCTION effortDistance ( --{{{
  in_user_id INTEGER,
  in_vessel_id INTEGER[],
  in_mindate DATE,
  in_maxdate DATE,
  in_species VARCHAR(255)[]
)
RETURNS TABLE (
  midweek DATE,
  catch NUMERIC(20,12),
  species VARCHAR(255),
  effort NUMERIC(20,12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT e.midweek, SUM(e.catch), e.species, SUM(e.distance) / 1000
      FROM tm_effort AS e
INNER JOIN tm_vessels AS v USING (vessel_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND e.vessel_id = u.vessel_id)
         OR (u.user_role = 'a'))
       AND (in_mindate IS NULL OR in_maxdate IS NULL OR e.midweek BETWEEN in_mindate AND in_maxdate)
       AND (in_vessel_id IS NULL OR e.vessel_id = ANY(in_vessel_id))
       AND (in_species IS NULL OR e.species = ANY(in_species))
  GROUP BY e.midweek, e.species
  ORDER BY e.midweek;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort using creels
CREATE OR REPLACE FUNCTION effortCreels ( --{{{
  in_user_id INTEGER,
  in_vessel_id INTEGER[],
  in_mindate DATE,
  in_maxdate DATE,
  in_species VARCHAR(255)[]
)
RETURNS TABLE (
  midweek DATE,
  catch NUMERIC(20,12),
  species VARCHAR(255),
  effort NUMERIC(20,12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT e.midweek, SUM(e.catch), e.species, SUM(e.creels)
      FROM tm_effort AS e
INNER JOIN tm_vessels AS v USING (vessel_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND e.vessel_id = u.vessel_id)
         OR (u.user_role = 'a'))
       AND (in_mindate IS NULL OR in_maxdate IS NULL OR e.midweek BETWEEN in_mindate AND in_maxdate)
       AND (in_vessel_id IS NULL OR e.vessel_id = ANY(in_vessel_id))
       AND (in_species IS NULL OR e.species = ANY(in_species))
  GROUP BY e.midweek, e.species
  ORDER BY e.midweek;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort using trips
CREATE OR REPLACE FUNCTION effortTrips ( --{{{
  in_user_id INTEGER,
  in_vessel_id INTEGER[],
  in_mindate DATE,
  in_maxdate DATE,
  in_species VARCHAR(255)[]
)
RETURNS TABLE (
  midweek DATE,
  catch NUMERIC(20,12),
  species VARCHAR(255),
  effort NUMERIC(20,12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT e.midweek, SUM(e.catch), e.species, SUM(e.trips)::NUMERIC(20,12)
      FROM tm_effort AS e
INNER JOIN tm_vessels AS v USING (vessel_id)
INNER JOIN app_users AS u ON (user_id = in_user_id)
     WHERE ((u.user_role = 'f' AND e.vessel_id = u.vessel_id)
         OR (u.user_role = 'a'))
       AND (in_mindate IS NULL OR in_maxdate IS NULL OR e.midweek BETWEEN in_mindate AND in_maxdate)
       AND (in_vessel_id IS NULL OR e.vessel_id = ANY(in_vessel_id))
       AND (in_species IS NULL OR e.species = ANY(in_species))
  GROUP BY e.midweek, e.species
  ORDER BY e.midweek;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
