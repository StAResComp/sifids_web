-- get attributes of device/track
CREATE OR REPLACE FUNCTION getTripsForTania ( --{{{
  in_trip_id INTEGER
)
RETURNS TABLE (
  trip_id INTEGER,
  track_id INTEGER,
  time_stamp TIMESTAMP WITH TIME ZONE,
  x DOUBLE PRECISION,
  y DOUBLE PRECISION
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT in_trip_id, 
           MIN(tks.track_id), -- pick first track ID
           tks.time_stamp,
           ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 32630)) AS x, 
           ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 32630)) AS y 
      FROM "Tracks" AS tks
     WHERE tks.trip_id = in_trip_id
       AND longitude < -0.5 -- 1 - remove wrong lats and longs
       AND is_valid = 1
       AND NOT EXISTS (
                       SELECT 1
                         FROM geography.scotlandmap2
                        WHERE ST_Contains(buffer, ST_SetSRID(ST_MakePoint(tks.longitude, tks.latitude), 4326)) -- 3, 4 - remove points too close to land and on land
                      )
  GROUP BY tks.time_stamp, tks.latitude, tks.longitude -- 2 - remove duplicates
  ORDER BY time_stamp ASC;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}



