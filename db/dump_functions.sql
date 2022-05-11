-- -*- sql92 -*-

-- get trip data between given dates
CREATE OR REPLACE FUNCTION dumpTrip ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  trip_date DATE,
  vessel_id INTEGER,
  pln VARCHAR(16),
  device_id INTEGER,
  unique_device_id INTEGER,
  imei TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, t.trip_date, 
           d.vessel_id, v.vessel_pln, d.device_id, 
           u.unique_device_id, u.device_string
      FROM "Trips" AS t
INNER JOIN "Devices" AS d USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
INNER JOIN entities."UniqueDevices" AS u USING (unique_device_id)
     WHERE t.trip_date BETWEEN in_start_date AND in_end_date
       AND d.from_date <= in_start_date
       AND (d.to_date IS NULL OR d.to_date >= in_end_date)
  ORDER BY t.trip_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get trip estimates between given dates
CREATE OR REPLACE FUNCTION dumpTripEstimates ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  estimate_value NUMERIC,
  estimate_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, e.estimate_value, et.estimate_name
      FROM "Trips" AS t
INNER JOIN analysis."Estimates" AS e USING (trip_id)
INNER JOIN entities."EstimateTypes" AS et USING (estimate_type_id)
     WHERE t.trip_date BETWEEN in_start_date and in_end_date
  ORDER BY t.trip_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get track data for trips between given dates
CREATE OR REPLACE FUNCTION dumpTracks ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  track_id INTEGER,
  trip_id INTEGER,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  is_valid SMALLINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.track_id, t.trip_id, t.latitude, t.longitude, t.time_stamp, t.is_valid
      FROM "Tracks" AS t
INNER JOIN "Trips" AS tr USING (trip_id)
     WHERE tr.trip_date BETWEEN in_start_date and in_end_date
  ORDER BY tr.trip_id, t.time_stamp;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get track data plus other attributes for trips between given dates
CREATE OR REPLACE FUNCTION dumpTracksWithAttributes ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  track_id INTEGER,
  trip_id INTEGER,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  is_valid SMALLINT,
  power NUMERIC,
  battery NUMERIC
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.track_id, t.trip_id, t.latitude, t.longitude, t.time_stamp, t.is_valid, 
           p.attribute_value, b.attribute_value
      FROM "Tracks" AS t
INNER JOIN "Trips" AS tr USING (trip_id)
 LEFT JOIN "Attributes" AS p ON (p.device_id = tr.device_id AND p.time_stamp = t.time_stamp AND p.attribute_id = 1)
 LEFT JOIN "Attributes" AS b ON (p.device_id = tr.device_id AND p.time_stamp = t.time_stamp AND p.attribute_id = 5)
     WHERE tr.trip_date BETWEEN in_start_date and in_end_date
  ORDER BY tr.trip_id, t.time_stamp;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get analysed track data for trips between given dates
CREATE OR REPLACE FUNCTION dumpTrackAnalysis ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  track_id INTEGER,
  trip_id INTEGER,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITHOUT TIME ZONE,
  grid_id INTEGER,
  activity_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.track_id, t.trip_id, t.latitude, t.longitude, t.time_stamp, ta.grid_id, a.activity_name
      FROM analysis."AnalysedTracks" AS t
INNER JOIN analysis."TrackAnalysis" AS ta USING (track_id)
INNER JOIN "Trips" AS tr USING (trip_id)
INNER JOIN entities."Activities" AS a USING (activity_id)
     WHERE tr.trip_date BETWEEN in_start_date and in_end_date
  ORDER BY tr.trip_id, t.time_stamp;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessel data
CREATE OR REPLACE FUNCTION dumpVessels () --{{{
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name TEXT,
  vessel_code VARCHAR(32),
  vessel_pln VARCHAR(16),
  owner_name TEXT,
  fo_town TEXT,
  vessel_length NUMERIC(6, 3),
  gear_name VARCHAR(32),
  animal_name TEXT,
  animal_code VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name, v.vessel_code, v.vessel_pln,
           o.owner_name, fo.fo_town,
           v.vessel_length, g.gear_name, a.animal_name, a.animal_code
      FROM "Vessels" AS v
INNER JOIN "VesselOwners" AS o USING (owner_id)
INNER JOIN entities."FisheryOffices" AS fo USING (fo_id)
INNER JOIN entities."Gears" AS g USING (gear_id)
INNER JOIN entities."Animals" AS a USING (animal_id);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get grid square data
CREATE OR REPLACE FUNCTION dumpGrids () --{{{
RETURNS TABLE (
  grid_id INTEGER,
  longitude1 NUMERIC(15, 12),
  latitude1 NUMERIC(15, 12),
  longitude2 NUMERIC(15, 12),
  latitude2 NUMERIC(15, 12)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT g.grid_id, g.longitude1, g.latitude1, g.longitude2, g.latitude2
      FROM analysis."Grids" AS g;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get app creel data
CREATE OR REPLACE FUNCTION dumpAppCreels ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  user_name TEXT,
  activitydate TIMESTAMP WITHOUT TIME ZONE,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  notes TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_name, c.activitydate, c.lat, c.lng, c.notes
      FROM app.wicreels AS c
INNER JOIN app.wirawdata USING (ingest_id)
 LEFT JOIN "Users" AS u USING (user_id)
     WHERE c.activitydate BETWEEN in_start_date and in_end_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get app catch data
CREATE OR REPLACE FUNCTION dumpAppCatch ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  user_name TEXT,
  catch_date TIMESTAMP WITHOUT TIME ZONE,
  animal_name TEXT,
  caught INTEGER,
  retained INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_name, c.catch_date, a.animal_name, c.caught, c.retained
      FROM app.wicatch AS c
INNER JOIN app.wirawdata USING (ingest_id)
INNER JOIN entities."Animals" AS a USING (animal_id)
 LEFT JOIN "Users" AS u USING (user_id)
     WHERE c.catch_date BETWEEN in_start_date and in_end_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get app observation data
CREATE OR REPLACE FUNCTION dumpAppObservations ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  user_name TEXT,
  obs_date TIMESTAMP WITHOUT TIME ZONE,
  animal_name TEXT,
  obs_count INTEGER,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  behaviour TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_name, o.obs_date, a.animal_name, o.obs_count, o.lat, o.lng,
           STRING_AGG(b.behaviour, ';') AS behaviour
      FROM app.wiobservations AS o
INNER JOIN app.wirawdata USING (ingest_id)
INNER JOIN entities."Animals" AS a USING (animal_id)
 LEFT JOIN "Users" AS u USING (user_id)
 LEFT JOIN app.wiobservationbehaviours AS b USING (observation_id)
     WHERE o.obs_date BETWEEN in_start_date and in_end_date
  GROUP BY o.observation_id, u.user_name, a.animal_name;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get coin data and closest location for devices
CREATE OR REPLACE FUNCTION dumpCoinData ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  device_name TEXT,
  vessel_name TEXT,
  coin_uuid VARCHAR(6),
  start_time TIMESTAMP WITH TIME ZONE,
  signal INTEGER,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.device_name, v.vessel_name, 
           SUBSTRING(co.coin_uuid, 27)::VARCHAR(6) AS coin_uuid, 
           cr.start_time, cr.signal,
           tr.latitude, tr.longitude, tr.time_stamp
      FROM entities."Coins" AS co
INNER JOIN "CoinDevice" USING (coin_id)
INNER JOIN "CoinReadings" AS cr USING (coin_device_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN entities."UniqueDevices" as u USING (unique_device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
INNER JOIN "Trips" AS t USING (device_id)
INNER JOIN LATERAL (
  SELECT tra.latitude, tra.longitude, 
         ABS(EXTRACT(EPOCH FROM (cr.start_time - tra.time_stamp))) AS diff, tra.time_stamp,
         tra.trip_id
    FROM "Tracks" AS tra
   WHERE trip_id = t.trip_id
ORDER BY diff ASC
   LIMIT 1) AS tr USING (trip_id)
     WHERE to_date IS NULL -- only want devices on vessels
       AND t.trip_date = cr.start_time::DATE -- trip from same day as coin reading
       AND cr.start_time BETWEEN in_start_date AND in_end_date
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
