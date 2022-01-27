-- get track data plus attributes
CREATE OR REPLACE FUNCTION getTrackAndAttributes ( --{{{
  in_device_id INTEGER,
  in_from_date DATE,
  in_to_date DATE
)
RETURNS TABLE (
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  trip_id INTEGER,
  device_id INTEGER,
  power NUMERIC,
  x_axis NUMERIC,
  y_axis NUMERIC,
  z_axis NUMERIC,
  speed NUMERIC,
  course NUMERIC
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.latitude, t.longitude, t.time_stamp,
           tr.trip_id, tr.device_id,
           p.attribute_value, x.attribute_value, y.attribute_value, z.attribute_value,
           s.attribute_value, c.attribute_value
      FROM "Trips" AS tr
INNER JOIN "Tracks" AS t USING (trip_id)
 LEFT JOIN "Attributes" AS p ON p.attribute_id = 1 AND p.device_id = tr.device_id AND p.time_stamp = t.time_stamp
 LEFT JOIN "Attributes" AS x ON x.attribute_id = 8 AND x.device_id = tr.device_id AND x.time_stamp = t.time_stamp
 LEFT JOIN "Attributes" AS y ON y.attribute_id = 9 AND y.device_id = tr.device_id AND y.time_stamp = t.time_stamp
 LEFT JOIN "Attributes" AS z ON z.attribute_id = 10 AND z.device_id = tr.device_id AND z.time_stamp = t.time_stamp
 LEFT JOIN "Attributes" AS s ON s.attribute_id = 11 AND s.device_id = tr.device_id AND s.time_stamp = t.time_stamp
 LEFT JOIN "Attributes" AS c ON c.attribute_id = 12 AND c.device_id = tr.device_id AND c.time_stamp = t.time_stamp
     WHERE (in_device_id IS NULL OR tr.device_id = in_device_id)
       AND (in_from_date IS NULL OR t.time_stamp > in_from_date)
       AND (in_to_date IS NULL OR t.time_stamp < in_to_date)
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
