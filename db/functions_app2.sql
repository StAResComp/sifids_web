/****** db/functions_app2.sql
 * NAME
 * functions_app2.sql
 * SYNOPSIS
 * Stored procedures called by the Shiny app
 * AUTHOR
 * Swithun Crowe
 * CREATION DATE
 * 20200218
 ******
 */

/****f* functions_app2.sql/
 * NAME
 * 
 * SYNOPSIS
 * 
 * ARGUMENTS
 * RETURN VALUE
 ******
 */


/****f* functions_app2.sql/appLogin
 * NAME
 * appLogin
 * SYNOPSIS
 * 
 * ARGUMENTS
 * RETURN VALUE
 ******
 */
CREATE OR REPLACE FUNCTION appLogin ( --{{{
  in_username TEXT,
  in_password TEXT
)
RETURNS TABLE (
  user_id INTEGER,
  user_role VARCHAR(32),
  vessel_ids INTEGER,
  vessel_names TEXT,
  vessel_codes VARCHAR(32)
)
AS $FUNC$
BEGIN
  -- log login attempt
  INSERT INTO "Logins" (username) VALUES (in_username);
  
  RETURN QUERY
     SELECT u.user_id, ut.user_type_name, 
            v.vessel_id, v.vessel_name || ' (' || v.vessel_pln || ')', v.vessel_code
       FROM "Users" AS u
 INNER JOIN entities."UserTypes" AS ut USING (user_type_id),
            "Vessels" AS v
      WHERE u.user_name = in_username
        AND u.user_password = CRYPT(in_password, u.user_password)
        -- fisher, so join to just their vessel/s
        AND (
             (ut.user_type_name = 'fisher' 
          AND v.vessel_id IN (SELECT vessel_id 
                               FROM "Vessels" 
                         INNER JOIN "UserVessels" AS uv USING (vessel_id) 
                              WHERE uv.user_id = u.user_id)
             )
        -- admin/researcher, so get all vessels
          OR (ut.user_type_name IN ('admin', 'researcher'))
        -- what about fishery officers?
            )
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- fish 1 catch per species
CREATE OR REPLACE FUNCTION catchPerSpecies ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_port_departure INTEGER,
  in_port_landing INTEGER,
  in_fo INTEGER,
  in_species INTEGER[]
)
RETURNS TABLE (
  species TEXT,
  weight NUMERIC,
  anon INTEGER
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      SELECT t.animal_name, AVG(t.weight), 1 AS anon
        FROM (
              SELECT device_id, animal_name, SUM(f.weight) AS weight
                FROM fish1."Rows" AS f
          INNER JOIN entities."Animals" USING (animal_id)
          INNER JOIN fish1."Headers" USING (header_id)
          INNER JOIN "Uploads" USING (upload_id)
          INNER JOIN "Devices" USING (device_id)
               WHERE (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
            GROUP BY device_id, animal_name) AS t
    GROUP BY animal_name
    ORDER BY animal_name;
  
  -- otherwise return fish1 data for user/all/some users
  ELSE
    RETURN QUERY
      SELECT animal_name, SUM(f.weight), 0 AS anon
        FROM fish1."Rows" AS f
  INNER JOIN entities."Animals" USING (animal_id)
  INNER JOIN fish1."Headers" USING (header_id)
  INNER JOIN "Uploads" USING (upload_id)
  INNER JOIN "Devices" USING (device_id)
  INNER JOIN "Vessels" USING (vessel_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher') 
           OR u1.user_id = in_user_id
             )
         AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
         AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
         AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
         AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing)
         AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo)
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
    GROUP BY animal_name
    ORDER BY animal_name;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- catch per species per week
-- use CTE to get every week betweeen start and finish
-- not just weeks with data
-- for graph
CREATE OR REPLACE FUNCTION catchPerSpeciesWeek ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_port_departure INTEGER,
  in_port_landing INTEGER,
  in_fo INTEGER,
  in_species INTEGER[]
)
RETURNS TABLE (
  week TEXT,
  species TEXT,
  weight NUMERIC,
  anon INTEGER
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      WITH RECURSIVE weeks (start, finish, week) AS (
        SELECT s.start, s.finish, s.week
          FROM (SELECT MIN(fishing_date) AS start,
                       MAX(fishing_date) AS finish,
                       TO_CHAR(MIN(fishing_date), 'IYYY-IW') AS week
                  FROM fish1."Rows"
                 LIMIT 1) AS s
     UNION ALL 
        SELECT w.start + INTERVAL '1 WEEK' AS start, 
               w.finish, 
               TO_CHAR(w.start + INTERVAL '1 WEEK', 'IYYY-IW') AS week
          FROM weeks AS w
         WHERE start < finish
      )
      SELECT t.week, t.animal_name, AVG(t.weight), 1 AS anon
        FROM (
              SELECT r.device_id, ww.week, r.animal_name, SUM(r.weight) AS weight
                FROM weeks AS ww
           LEFT JOIN (SELECT device_id, TO_CHAR(fishing_date, 'IYYY-IW') AS week, animal_name, COALESCE(f.weight, 0) AS weight
                        FROM fish1."Rows" AS f
                  INNER JOIN entities."Animals" USING (animal_id)
                  INNER JOIN fish1."Headers" USING (header_id)
                  INNER JOIN "Uploads" USING (upload_id)
                  INNER JOIN "Devices" USING (device_id)
                       WHERE (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
                     ) AS r USING (week)
            GROUP BY r.device_id, ww.week, r.animal_name) AS t
    GROUP BY t.week, t.animal_name
    ORDER BY t.week, t.animal_name;
  
  -- user isn't fisher with no fish1 data
  ELSE
    RETURN QUERY
      WITH RECURSIVE weeks (start, finish, week) AS (
        SELECT s.start, s.finish, s.week
          FROM (SELECT COALESCE(in_min_date, MIN(fishing_date)) AS start,
                       COALESCE(in_max_date, MAX(fishing_date)) AS finish,
                       TO_CHAR(COALESCE(in_min_date, MIN(fishing_date)), 'IYYY-IW') AS week
                  FROM fish1."Rows"
                 LIMIT 1) AS s
     UNION ALL 
        SELECT w.start + INTERVAL '1 WEEK' AS start, 
               w.finish, 
               TO_CHAR(w.start + INTERVAL '1 WEEK', 'IYYY-IW') AS week
          FROM weeks AS w
         WHERE start < finish
      )
      SELECT ww.week, r.animal_name, SUM(r.weight), 0 AS anon
        FROM weeks AS ww
   LEFT JOIN (SELECT TO_CHAR(fishing_date, 'IYYY-IW') AS week, animal_name, f.weight
                FROM fish1."Rows" AS f
          INNER JOIN entities."Animals" USING (animal_id)
          INNER JOIN fish1."Headers" USING (header_id)
          INNER JOIN "Uploads" USING (upload_id)
          INNER JOIN "Devices" USING (device_id)
          INNER JOIN "Vessels" USING (vessel_id)
           LEFT JOIN "UserVessels" USING (vessel_id)
           LEFT JOIN "Users" AS u1 USING (user_id)
           LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
           LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
               WHERE (
                      user_type_name IN ('admin', 'researcher')
                   OR u1.user_id = in_user_id
                     )
                 AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
                 AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
                 AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
                 AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
                 AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
                 AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
    ) AS r USING (week)
    GROUP BY ww.week, r.animal_name
    ORDER BY ww.week, r.animal_name;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels with fish 1 forms
CREATE OR REPLACE FUNCTION vesselsFish1 ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_pln VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN ut.user_type_name IN ('admin', 'fisher') THEN v.vessel_pln 
                WHEN ut.user_type_name IN ('researcher', 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM fish1."Headers"
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher') -- see all vessels
        OR u1.user_id = in_user_id -- just see own vessel/s
  GROUP BY ut.user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get first/last dates for fish 1 data
CREATE OR REPLACE FUNCTION datesForVesselFish1 ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  min_date DATE,
  max_date DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(fishing_date)::DATE, MAX(fishing_date)::DATE
      FROM fish1."Rows"
INNER JOIN fish1."Headers" USING (header_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Vessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get ports of departure from fish1 forms
CREATE OR REPLACE FUNCTION portOfDeparture ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  port_id INTEGER,
  port_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Headers" AS h
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_departure_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get ports of landing from fish1 forms
CREATE OR REPLACE FUNCTION portOfLanding ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  port_id INTEGER,
  port_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Headers" AS h
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_landing_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get fishery offices from fish1 forms
CREATE OR REPLACE FUNCTION fisheryOffice ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  fo_id INTEGER,
  fo_town TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town
      FROM fish1."Headers"
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" USING (vessel_id)
INNER JOIN entities."FisheryOffices" AS f USING (fo_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY f.fo_id, f.fo_town
  ORDER BY f.fo_town
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get species from fish 1 forms
CREATE OR REPLACE FUNCTION catchSpecies ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  animal_id INTEGER,
  animal_name TEXT
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      SELECT a.animal_id, a.animal_name
        FROM fish1."Headers"
  INNER JOIN fish1."Rows" USING (header_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
    GROUP BY a.animal_id, a.animal_name
    ORDER BY a.animal_name;
  
  -- user isn't fisher without fish1 data
  ELSE
    RETURN QUERY
      SELECT a.animal_id, a.animal_name
        FROM fish1."Headers"
  INNER JOIN fish1."Rows" USING (header_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
  INNER JOIN "Uploads" USING (upload_id)
  INNER JOIN "Devices" USING (device_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE user_type_name IN ('admin', 'researcher')
          OR u1.user_id = in_user_id
    GROUP BY a.animal_id, a.animal_name
    ORDER BY a.animal_name;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- what track data is available for user
CREATE OR REPLACE FUNCTION trackDataAvailable ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  estimates INTEGER
)
AS $FUNC$
BEGIN
  -- see if user is admin/researcher/fo
   PERFORM 1
      FROM "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id 
       AND user_type_name IN ('admin', 'researcher', 'fishery officer')
;

  IF FOUND THEN
    RETURN QUERY
      SELECT 1;
  ELSE
    RETURN QUERY
      SELECT EXISTS (
        SELECT 1
          FROM "UserVessels"
    INNER JOIN "Devices" USING (vessel_id)
    INNER JOIN "Trips" USING (device_id)
    INNER JOIN "Tracks" USING (trip_id)
    INNER JOIN analysis."TrackAnalysis" USING (track_id)
    INNER JOIN entities."Activities" USING (activity_id)
         WHERE user_id = in_user_id
           AND activity_name = 'hauling'
         )::INTEGER;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- what fishing events are available for user
CREATE OR REPLACE FUNCTION fishingEventsAvailable ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  event VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT DISTINCT activity_name
      FROM entities."Activities"
INNER JOIN analysis."FishingEvents" USING (activity_id)
INNER JOIN "Tracks" USING (track_id)
INNER JOIN "Trips" using (trip_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get start/end dates for tracks
CREATE OR REPLACE FUNCTION datesForTracks ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  min_date DATE,
  max_date DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(trip_date), MAX(trip_date)
      FROM "Trips"
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get locations of fishing activity for heat map
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
    SELECT t.trip_id, latitude, longitude
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get all tracks for heat map (for fishers)
CREATE OR REPLACE FUNCTION heatMapDataFisher ( --{{{
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
    SELECT t.trip_id, latitude, longitude
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
--INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get counts for grids entered while fishing
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
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN analysis."Grids" AS g USING (grid_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
  GROUP BY g.grid_id
    HAVING COUNT(*) > 1
  ORDER BY COUNT(*) ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get estimates for trips
CREATE OR REPLACE FUNCTION tripEstimates ( --{{{
  in_user_id INTEGER,
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
    SELECT t.trip_id, 
           (COALESCE(
             CASE WHEN user_type_name IN ('admin', 'fisher') THEN vessel_pln || ' ' || device_name::VARCHAR(32)
                  WHEN user_type_name IN ('researcher', 'fishery officer') THEN vessel_code::VARCHAR(16)
             END,
             'no vessel'
           ) || ' - ' || TO_CHAR(trip_date::DATE, 'dd-mm-yyyy'))::VARCHAR(255), 
           MAX(low.estimate_value)::INTEGER, 
           MAX(high.estimate_value)::INTEGER, 
           (MAX(dist.estimate_value) / 1000)::INTEGER
      FROM "Tracks"
INNER JOIN "Trips" AS t USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN entities."UniqueDevices" USING (unique_device_id)
 LEFT JOIN analysis."Estimates" AS low ON (t.trip_id = low.trip_id AND low.estimate_type_id = 1)
 LEFT JOIN analysis."Estimates" AS high ON (t.trip_id = high.trip_id AND high.estimate_type_id = 2)
 LEFT JOIN analysis."Estimates" AS dist ON (t.trip_id = dist.trip_id AND dist.estimate_type_id = 3)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND (
            in_vessels IS NULL 
         OR in_vessels = '{}' 
         OR vessel_id = ANY(in_vessels)
           )
       AND trip_date BETWEEN in_min_date AND in_max_date
  GROUP BY ut.user_type_name, t.trip_id, device_name, v.vessel_id
    HAVING COUNT(*) > 1 -- exclude trips with only 1 track
  ORDER BY trip_date DESC, vessel_pln ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get most recent positions for each vessel today
CREATE OR REPLACE FUNCTION latestPoints ( --{{{
  in_user_id INTEGER,
  in_trips INTEGER[]
)
RETURNS TABLE (
  trip_id INTEGER,
  vessel_name VARCHAR(255),
  time_stamp TIMESTAMP WITH TIME ZONE,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, 
           COALESCE(
             CASE WHEN user_type_name IN ('admin', 'fisher') THEN vessel_pln
                  WHEN user_type_name IN ('researcher', 'fishery officer') THEN vessel_code::VARCHAR(16)
             END,
             'no vessel') AS vessel_name, 
           "Tracks".time_stamp, "Tracks".latitude, "Tracks".longitude
      FROM "Tracks"
INNER JOIN "Trips" AS t USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN (SELECT device_id, MAX(trptm.time_stamp) AS time_stamp
              FROM (SELECT "Trips".trip_id, device_id, MAX("Tracks".time_stamp) AS time_stamp
                      FROM "Trips"
                INNER JOIN "Tracks" USING (trip_id)
                     WHERE "Trips".trip_id = ANY(in_trips)
                       AND DATE_TRUNC('day', trip_date) = DATE_TRUNC('day', NOW())
                       AND is_valid = 1
                  GROUP BY "Trips".trip_id) AS trptm
         GROUP BY device_id) AS dvtm 
     USING (device_id, time_stamp)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND t.trip_id = ANY(in_trips)
       AND DATE_TRUNC('day', trip_date) = DATE_TRUNC('day', NOW())
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels with tracks
CREATE OR REPLACE FUNCTION trackVessels ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_pln VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN user_type_name IN ('admin', 'fisher') THEN v.vessel_pln
                WHEN user_type_name IN ('researcher' , 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM "Trips" AS t
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get tracks for given trips
CREATE OR REPLACE FUNCTION tracksFromTrips ( --{{{
  in_user_id INTEGER,
  in_trips INTEGER[]
)
RETURNS TABLE (
  trip_id INTEGER,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  activity INTEGER
)
AS $FUNC$
DECLARE
  temp_factor INTEGER;
BEGIN
  -- put data into temp table
  CREATE TEMPORARY TABLE temp_tracks AS
    SELECT t.trip_id, tr.latitude, tr.longitude, COALESCE(activity_id, 1) AS activity, -- not fishing when no activity present
           t.trip_date, tr.time_stamp, ROW_NUMBER() OVER (ORDER BY t.trip_date, tr.time_stamp)
      FROM "Trips" AS t
INNER JOIN "Tracks" AS tr USING (trip_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN analysis."TrackAnalysis" USING (track_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_trips IS NULL OR in_trips = '{}' OR t.trip_id = ANY(in_trips)) 
       AND is_valid = 1
;

  -- get number of rows
  SELECT (COUNT(*) / 1000)::INTEGER FROM temp_tracks INTO temp_factor;

  -- decide if temp_tracks needs to be thinned
  IF temp_factor > 1 THEN
    DELETE 
      FROM temp_tracks AS t
     WHERE MOD(t.row_number, temp_factor) <> 0 -- thin using modulo of row number
       AND t.activity = 1; -- and no fishing activity
  END IF;

  -- send back (possibly) thinned data
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude, t.activity
      FROM temp_tracks AS t
  ORDER BY t.trip_date, t.time_stamp
;

  -- finished with temp table
  DROP TABLE temp_tracks
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get analysed tracks for given trips
CREATE OR REPLACE FUNCTION analysedTracksFromTrips ( --{{{
  in_user_id INTEGER,
  in_trips INTEGER[]
)
RETURNS TABLE (
  trip_id INTEGER,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  activity INTEGER
)
AS $FUNC$
DECLARE
  temp_factor INTEGER;
BEGIN
  -- put data into temp table
  CREATE TEMPORARY TABLE temp_tracks AS
    SELECT t.trip_id, tr.latitude, tr.longitude, COALESCE(activity_id, 1) AS activity, -- not fishing when no activity present
           t.trip_date, tr.time_stamp, ROW_NUMBER() OVER (ORDER BY t.trip_date, tr.time_stamp)
      FROM "Trips" AS t
INNER JOIN analysis."AnalysedTracks" AS tr USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN analysis."TrackAnalysis" USING (track_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_trips IS NULL OR in_trips = '{}' OR t.trip_id = ANY(in_trips)) 
;

  -- get number of rows
  SELECT (COUNT(*) / 1000)::INTEGER FROM temp_tracks INTO temp_factor;

  -- decide if temp_tracks needs to be thinned
  IF temp_factor > 1 THEN
    DELETE 
      FROM temp_tracks AS t
     WHERE MOD(t.row_number, temp_factor) <> 0 -- thin using modulo of row number
       AND t.activity = 1; -- and no fishing activity
  END IF;

  -- send back (possibly) thinned data
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude, t.activity
      FROM temp_tracks AS t
  ORDER BY t.trip_date, t.time_stamp
;

  -- finished with temp table
  DROP TABLE temp_tracks
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get events for given trips
CREATE OR REPLACE FUNCTION eventsFromTrips ( --{{{
  in_user_id INTEGER,
  in_trips INTEGER[],
  in_events VARCHAR(32)[]
)
RETURNS TABLE (
  trip_id INTEGER,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  activity_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, tr.latitude, tr.longitude, a.activity_name
      FROM "Trips" AS t
INNER JOIN "Tracks" AS tr USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN analysis."FishingEvents" USING (track_id)
INNER JOIN entities."Activities" AS a USING (activity_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_trips IS NULL OR in_trips = '{}' OR t.trip_id = ANY(in_trips))
       AND (in_events IS NULL OR in_events = '{}' OR a.activity_name = ANY(in_events))
       AND is_valid = 1
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get Scottish Marine Regions
CREATE OR REPLACE FUNCTION scottishMarineRegions ( --{{{
)
RETURNS TABLE (
  objnam VARCHAR(255),
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.objnam, ST_Simplify(g.geom, 0.009)
      FROM geography."ScottishMarineRegions" AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get RIFGs
CREATE OR REPLACE FUNCTION RIFGs ( --{{{
)
RETURNS TABLE (
  rifg VARCHAR(32),
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.rifg, ST_Simplify(g.geom, 0.009)
      FROM geography."RIFGs" AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get 3 mile limit
CREATE OR REPLACE FUNCTION threeMileLimit ( --{{{
)
RETURNS TABLE (
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT ST_Simplify(g.geom, 0.009)
      FROM geography."ThreeMileLimit" AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get 6 mile limit
CREATE OR REPLACE FUNCTION sixMileLimit ( --{{{
)
RETURNS TABLE (
  geom GEOMETRY(MULTILINESTRING, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT ST_Simplify(g.geom, 0.009)
      FROM geography."SixMileLimit" AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get first/last dates for fish 1 effort data
CREATE OR REPLACE FUNCTION datesForEffort ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  min_date DATE,
  max_date DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(week_start), MAX(week_start)
      FROM fish1."WeeklyEffort"
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get IDs and names of vessels with effort data
CREATE OR REPLACE FUNCTION effortVessels ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_pln VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN user_type_name IN ('admin', 'fisher') THEN v.vessel_pln
                WHEN user_type_name IN ('researcher', 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM fish1."WeeklyEffort"
INNER JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get species from effort data
CREATE OR REPLACE FUNCTION effortSpecies ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  animal_id INTEGER,
  animal_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT a.animal_id, a.animal_name
      FROM fish1."WeeklyEffort"
INNER JOIN fish1."WeeklyEffortSpecies" USING (weekly_effort_id)
INNER JOIN entities."Animals" AS a USING (animal_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY a.animal_id
  ORDER BY a.animal_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort measured by distance travelled
CREATE OR REPLACE FUNCTION effortDistance ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_animals INTEGER[]
)
RETURNS TABLE (
  week_start DATE,
  catch NUMERIC(20,12),
  animal_name TEXT,
  effort NUMERIC(20,12),
  anon INTEGER
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user has no effort data, so show averages
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, AVG(es.catch), a.animal_name, AVG(distance) / 1000, 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- user is not user with no effort data, so show real values
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(distance) / 1000, 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date) 
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort measured by creels deployed
CREATE OR REPLACE FUNCTION effortCreels ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_animals INTEGER[]
)
RETURNS TABLE (
  week_start DATE,
  catch NUMERIC(20,12),
  animal_name TEXT,
  effort NUMERIC(20,12),
  anon INTEGER
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user with no effort data
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, AVG(es.catch), a.animal_name, AVG(total_pots_fishing), 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- not user with no effort data
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(total_pots_fishing), 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date)
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get effort measured by trips made per week
-- BUG maybe use MAX instead of SUM
CREATE OR REPLACE FUNCTION effortTrips ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_min_date DATE,
  in_max_date DATE,
  in_animals INTEGER[]
)
RETURNS TABLE (
  week_start DATE,
  catch NUMERIC(20,12),
  animal_name TEXT,
  effort NUMERIC(20,12),
  anon INTEGER
)
AS $FUNC$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user with no effort data
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(es.trips)::NUMERIC(20,12), 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- not user with no effort data
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(es.trips)::NUMERIC(20,12), 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date)
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get hauls per day (geography tab)
CREATE OR REPLACE FUNCTION geographyHauls ( --{{{
)
RETURNS TABLE (
  combined DOUBLE PRECISION,
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.combined, ST_Simplify(g.geom, 0.009)
      FROM geography."Hauls" AS g
     WHERE g.combined > 0.5
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels (geography tab)
CREATE OR REPLACE FUNCTION geographyVessels ( --{{{
)
RETURNS TABLE (
  vessel_count INTEGER,
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.vessel_count::INTEGER, ST_Simplify(g.geom, 0.009)
      FROM geography."CreelVessels" AS g
     WHERE g.vessel_count IS NOT NULL
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get minke entanglements (geography tab)
CREATE OR REPLACE FUNCTION geographyMinke ( --{{{
)
RETURNS TABLE (
  "year" INTEGER,
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g."year", ST_Simplify(g.geom, 0.009)
      FROM geography."Minke" AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get observations from mobile app (geography tab)
CREATE OR REPLACE FUNCTION geographyObservations ( --{{{
)
RETURNS TABLE (
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  animal_name TEXT,
  animal_group TEXT,
  observation_count BIGINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.latitude, g.longitude, a1.animal_name,
           COALESCE(a2.animal_name, a1.animal_name),
           SUM(g.observed_count)
      FROM geography."Observations" AS g
INNER JOIN entities."Animals" AS a1 ON g.animal_id = a1.animal_id
 LEFT JOIN entities."Animals" AS a2 ON a1.subclass_of = a2.animal_id
  GROUP BY g.latitude, g.longitude, a1.animal_id, a2.animal_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get creel sightings (HWDT) (geography tab)
CREATE OR REPLACE FUNCTION geographySightings ( --{{{
  in_year INTEGER
)
RETURNS TABLE (
  geom GEOMETRY(POINT, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.geom
      FROM geography."HWDTCreels" AS g
     WHERE hwdt_year = in_year
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get bathymetry
CREATE OR REPLACE FUNCTION geographyBathymetry ( --{{{
)
RETURNS TABLE (
  dn INTEGER,
  geom GEOMETRY(MULTIPOLYGON, 4326)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.dn, ST_Simplify(g.geom, 0.009)
      FROM geography.bathymetry AS g
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}


-- get vessels with attributes (admin only)
CREATE OR REPLACE FUNCTION attributeVessels ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_pln VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_pln
      FROM "Attributes" AS a2
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
         , "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
  GROUP BY v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get attributes of device/track
CREATE OR REPLACE FUNCTION getAttributes ( --{{{
)
RETURNS TABLE (
  attribute_id INTEGER,
  attribute_name VARCHAR(32),
  attribute_display TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT a.attribute_id, a.attribute_name, a.attribute_display
      FROM entities."AttributeTypes" AS a
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get first/last dates for attributes for given vessel/s
CREATE OR REPLACE FUNCTION datesForAttributes ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[]
)
RETURNS TABLE (
  min_date DATE,
  max_date DATE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(time_stamp)::DATE, MAX(time_stamp)::DATE
      FROM "Attributes"
INNER JOIN "Devices" USING (device_id),
           "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get attribute values for given vessels between given dates
-- TODO change distance attributes, so that they only return max per day
CREATE OR REPLACE FUNCTION attributePlotData ( --{{{
  in_user_id INTEGER,
  in_vessels INTEGER[],
  in_start_date DATE,
  in_end_date DATE,
  in_attributes INTEGER[]
)
RETURNS TABLE (
  vessel_pln VARCHAR(16),
  attribute_name VARCHAR(32),
  attribute_value NUMERIC,
  time_stamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
DECLARE
  max_rows INTEGER := 500;
  factor INTEGER := 1;
  rec RECORD;
BEGIN
  -- put all data into temp table
  CREATE TEMPORARY TABLE attrib_plot_data AS
    SELECT ROW_NUMBER() OVER (ORDER BY v.vessel_id, a1.attribute_id, a2.time_stamp) AS row_num, 
           v.vessel_id, v.vessel_pln, 
           a1.attribute_id, a1.attribute_name, 
           CASE 
             WHEN a1.attribute_name = 'distance' OR a1.attribute_name = 'totalDistance' THEN
               (a2.attribute_value / 1000)::INTEGER -- convert to km
             ELSE
               a2.attribute_value
           END,
           a2.time_stamp
      FROM "Attributes" AS a2
INNER JOIN entities."AttributeTypes" AS a1 USING (attribute_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
         , "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
       AND vessel_id = ANY(in_vessels)
       AND a2.time_stamp BETWEEN in_start_date AND in_end_date
       AND a2.attribute_id = ANY(in_attributes)
;

        FOR rec
  IN SELECT t.vessel_id, t.attribute_id, COUNT(*) AS rc
       FROM attrib_plot_data AS t
   GROUP BY t.vessel_id, t.attribute_id
       LOOP
         -- work out how many rows to thin out of total
         IF rec.rc > max_rows THEN
           SELECT (rec.rc / max_rows)::INTEGER INTO factor;
         ELSE
           SELECT 1 INTO factor;
         END IF;
         
         -- thin data in temp table for this vessel/attribute
         IF factor > 1 THEN
           DELETE
             FROM attrib_plot_data AS t
           WHERE MOD(t.row_num, factor) <> 0
             AND t.vessel_id = rec.vessel_id 
             AND t.attribute_id = rec.attribute_id;
         END IF;
   END LOOP;
  
  -- select remaining data from temp table
  RETURN QUERY
    SELECT t.vessel_pln, t.attribute_name, t.attribute_value, t.time_stamp
      FROM attrib_plot_data AS t
  ORDER BY t.time_stamp ASC;
  
  -- finished with temp table
  DROP TABLE attrib_plot_data;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
