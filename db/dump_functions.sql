-- -*- sql92 -*-

-- get trip data between given dates
CREATE OR REPLACE FUNCTION dumpTrip ( --{{{
  in_start_date DATE,
  in_end_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  trip_date DATE,
  vessel_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, t.trip_date, d.vessel_id
      FROM "Trips" AS t
INNER JOIN "Devices" AS d USING (device_id)
     WHERE t.trip_date BETWEEN in_start_date and in_end_date
  ORDER BY t.trip_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

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
