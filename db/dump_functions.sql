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