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


