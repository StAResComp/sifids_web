-- stored procedures for adding data from Traccar

-- get device ID using device string
CREATE OR REPLACE FUNCTION getDeviceID ( --{{{
  in_device_string TEXT
)
RETURNS TABLE (
  device_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.device_id 
      FROM "Devices" AS d
INNER JOIN entities."UniqueDevices" AS ud USING (unique_device_id)
     WHERE ud.device_string = in_device_string
       AND (from_date IS NULL OR from_date < NOW()) -- from date not set, or in the past
       AND (to_date IS NULL OR to_date > NOW()) -- to date not set, or in the future
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- add attribute related to track
CREATE OR REPLACE FUNCTION addAttribute ( --{{{
  in_attribute_name VARCHAR(32),
  in_attribute_value NUMERIC,
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_device_id INTEGER
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  INSERT INTO "Attributes" (attribute_id, device_id, time_stamp, attribute_value)
       SELECT a.attribute_id, in_device_id, in_time_stamp, in_attribute_value
         FROM entities."AttributeTypes" AS a
        WHERE a.attribute_name = in_attribute_name
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS inserted = ROW_COUNT;
  
  RETURN QUERY
    SELECT inserted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get trip ID for current trip, or new trip if new day
CREATE OR REPLACE FUNCTION getTripID ( --{{{
  in_device_id INTEGER,
  in_time_stamp TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  -- get ID of trip matching device and date in time stamp
    SELECT t.trip_id
      INTO trip_id
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
     WHERE t.device_id = in_device_id
       AND t.trip_date = in_time_stamp::DATE
  GROUP BY t.trip_id
  ORDER BY COUNT(*) DESC
     LIMIT 1
;
   
   -- if nothing found, insert new trip
   IF trip_id IS NULL THEN
     INSERT INTO "Trips" AS t (device_id, trip_date)
          SELECT in_device_id, in_time_stamp::DATE
       RETURNING t.trip_id INTO trip_id;
   END IF;
   
   RETURN QUERY
     SELECT trip_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add track point
-- returns 0 when current point is same as previous one, otherwise new track id
CREATE OR REPLACE FUNCTION addTraccarTrack ( --{{{
  in_trip_id INTEGER,
  in_latitude NUMERIC(15,12),
  in_longitude NUMERIC(15,12),
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_is_valid SMALLINT
)
RETURNS TABLE (
  track_id INTEGER
)
AS $FUNC$
DECLARE
  old_latitude NUMERIC(15,12);
  old_longitude NUMERIC(15,12);
BEGIN
  -- record most recent track point for device
  INSERT
    INTO "LastPointsForDevices"
         (device_id, time_stamp, latitude, longitude)
  SELECT device_id, in_time_stamp, in_latitude, in_longitude
    FROM "Trips"
   WHERE trip_id = in_trip_id
      ON CONFLICT (device_id) DO 
  UPDATE 
     SET time_stamp = EXCLUDED.time_stamp,
         latitude = EXCLUDED.latitude,
         longitude = EXCLUDED.longitude;
                                                                                 

  -- get most recent point from track
    SELECT t.latitude, t.longitude
      INTO old_latitude, old_longitude
      FROM "Tracks" AS t
     WHERE trip_id = in_trip_id
  ORDER BY time_stamp DESC
     LIMIT 1;
     
  -- see if device has moved since last point
    IF old_latitude = in_latitude AND old_longitude = in_longitude THEN
      RETURN QUERY
           SELECT 0; -- not moved, so send back 0
    ELSE
      RETURN QUERY
      INSERT INTO "Tracks" AS t (latitude, longitude, time_stamp, trip_id, is_valid, geog)
           VALUES (in_latitude, in_longitude, in_time_stamp, in_trip_id, in_is_valid,
                   CAST(ST_SetSRID( ST_Point(in_longitude, in_latitude), 4326) as geography))
        RETURNING t.track_id;
    END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
