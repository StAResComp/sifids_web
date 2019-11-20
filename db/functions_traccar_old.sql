-- -*- pgsql -*-

-- stored procedures for dealing with Traccar data
-- old - don't use


SET SCHEMA 'traccar';

-- add device to database - do nothing if already present
CREATE OR REPLACE FUNCTION addDevice ( --{{{
  in_name VARCHAR(255),
  in_string VARCHAR(255),
  in_protocol VARCHAR(255)
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  -- try insert
  PERFORM device_string
     FROM traccar_devices
    WHERE device_string = in_string;
  
  IF NOT FOUND THEN
    INSERT INTO traccar_devices (device_name, device_string, protocol)
         VALUES (in_name, in_string, in_protocol);
  END IF;
  
  -- return ID of device
RETURN QUERY
  SELECT device_id
    FROM traccar_devices
   WHERE device_string = in_string;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add attribute value to database
-- adding attribute name if not already present
CREATE OR REPLACE FUNCTION addAttribute ( --{{{
  in_name VARCHAR(255),
  in_value FLOAT,
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_device_id INTEGER
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  -- try insert of new attribute
  PERFORM attribute_name
     FROM traccar_attribute_names
    WHERE attribute_name = in_name;
   
  IF NOT FOUND THEN
    INSERT INTO traccar_attribute_names (attribute_name)
         VALUES (in_name);
  END IF;
  
  -- insert attribute value and return ID of attribute
RETURN QUERY
  INSERT INTO traccar_attributes (attribute_id, device_id, attribute_value, time_stamp)
       SELECT attribute_id, in_device_id, in_value, in_time_stamp
         FROM traccar_attribute_names
        WHERE attribute_name = in_name
    RETURNING attribute_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add track point to database
CREATE OR REPLACE FUNCTION addTrack ( --{{{
  in_device_id INTEGER,
  in_latitude NUMERIC(15,12),
  in_longitude NUMERIC(15,12),
  in_time_stamp TIMESTAMP WITH TIME ZONE
)
RETURNS SETOF INTEGER
AS $FUNC$
DECLARE
  new_trip_id INTEGER;
  old_lat NUMERIC(15,12);
  old_long NUMERIC(15,12);
  old_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- get most recent track for this device
    SELECT t.trip_id, t.latitude, t.longitude, t.time_stamp
      INTO new_trip_id, old_lat, old_long, old_time
      FROM traccar_track AS t
INNER JOIN traccar_trips USING (trip_id)
     WHERE device_id = in_device_id
  ORDER BY t.time_stamp DESC
     LIMIT 1;
  
  -- if device not moved since last track point, don't insert
  IF in_latitude = old_lat AND in_longitude = old_long THEN
    RETURN;
  END IF;
  
  -- need new trip
    IF (new_trip_id IS NULL) -- no previous trip by this vessel
    OR DATE_TRUNC('day', in_time_stamp) <> DATE_TRUNC('day', old_time) -- different days
--    OR (EXTRACT(EPOCH FROM in_time_stamp - old_time) > 600) -- previous point is too far in the past
--    OR (SQRT(POWER((old_lat - in_latitude) * 111111, 2) + POWER((old_long - in_longitude) * 111111 * COS(RADIANS(in_latitude)) ,2)) > 900) --previous point is too far away in distance
  THEN
       INSERT INTO traccar_trips (device_id)
            VALUES (in_device_id)
         RETURNING trip_id INTO new_trip_id;
END IF;
  
  RETURN QUERY
    INSERT INTO traccar_track (trip_id, latitude, longitude, time_stamp)
         VALUES (new_trip_id, in_latitude, in_longitude, in_time_stamp)
      RETURNING new_trip_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get devices which have tracks
CREATE OR REPLACE FUNCTION getDevices (
  in_user_id INTEGER
) --{{{
RETURNS TABLE (
  device_id INTEGER, 
  device_name VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.device_id, d.device_name
      FROM traccar_devices AS d
     WHERE EXISTS (SELECT 1
                     FROM traccar_track
               INNER JOIN traccar_trips AS tr USING (trip_id)
                    WHERE tr.device_id = d.device_id)
       AND in_user_id = 1
  ORDER BY device_name;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get min and max dates for tracks, possibly limited to given devices
CREATE OR REPLACE FUNCTION getDates (
  in_user_id INTEGER,
  in_vessels INTEGER[]
) --{{{
RETURNS TABLE (
  min_date TIMESTAMP WITH TIME ZONE, 
  max_date TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT MIN(time_stamp) AS min_date, MAX(time_stamp) AS max_date
      FROM traccar_track
INNER JOIN traccar_trips USING (trip_id)
     WHERE in_user_id = 1 
       AND (in_vessels IS NULL OR device_id = ANY(in_vessels));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- trips for selected vessels
CREATE OR REPLACE FUNCTION getTrips (
  in_user_id INTEGER,
  in_vessels INTEGER[],
  min_date TIMESTAMP WITH TIME ZONE,
  max_date TIMESTAMP WITH TIME ZONE
) --{{{
RETURNS TABLE (
  trip_id INTEGER,
  device_name VARCHAR(255),
  trip_label VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, d.device_name, 
           (TO_CHAR(MIN(t.time_stamp), 'YYYY-MM-DD HH24:MI') || ' - ' || TO_CHAR(MAX(t.time_stamp), 'HH24:MI'))::VARCHAR(255) AS trip_label
      FROM traccar_track AS t
INNER JOIN traccar_trips USING (trip_id)
INNER JOIN traccar_devices AS d USING (device_id)
     WHERE in_user_id = 1
       AND ((min_date IS NULL OR max_date IS NULL) OR DATE_TRUNC('day', t.time_stamp) BETWEEN min_date AND max_date)
       AND (in_vessels IS NULL OR device_id = ANY(in_vessels))
  GROUP BY d.device_id, d.device_name, t.trip_id
    HAVING COUNT(*) > 150
  ORDER BY d.device_id, t.trip_id, MIN(t.time_stamp);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}


-- tracks for selected tracks
CREATE OR REPLACE FUNCTION getTracks (
  in_user_id INTEGER,
  in_trips INTEGER[]
) --{{{
RETURNS TABLE (
  trip_id INTEGER,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude, t.time_stamp
      FROM traccar_track AS t
     WHERE in_user_id = 1
       AND t.trip_id = ANY(in_trips)
  ORDER BY t.trip_id, t.time_stamp;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
