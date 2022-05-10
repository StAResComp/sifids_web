-- coin data coming in
CREATE OR REPLACE FUNCTION addCoinData ( --{{{
  in_device_id INTEGER,
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_uuid VARCHAR(32),
  in_major VARCHAR(4),
  in_minor VARCHAR(4),
  in_signal INTEGER
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
DECLARE
  coinid INTEGER;
  coindeviceid INTEGER;
BEGIN
  -- look up coin to see if it exists already
  SELECT coin_id
    INTO coinid
    FROM entities."Coins"
   WHERE coin_uuid = in_uuid;
  
  IF coinid IS NULL THEN
    INSERT
      INTO entities."Coins"
           (coin_uuid, coin_major, coin_minor)
    VALUES (in_uuid, in_major, in_minor)
 RETURNING coin_id
      INTO coinid;
  END IF;
  
  -- see if coin has already been paired with device
  SELECT coin_device_id
    INTO coindeviceid
    FROM "CoinDevice"
   WHERE coin_id = coinid
     AND device_id = in_device_id;
  
  IF coindeviceid IS NULL THEN
    INSERT 
      INTO "CoinDevice"
           (coin_id, device_id)
    VALUES (coinid, in_device_id)
 RETURNING coin_device_id
      INTO coindeviceid;
  END IF;
  
  -- have coin/device ID, so can record time and signal strength
  INSERT
    INTO "CoinReadings"
         (coin_device_id, start_time, signal)
  VALUES (coindeviceid, in_time_stamp, in_signal);
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get coin data and closest location for devices
CREATE OR REPLACE FUNCTION getCoinData ( --{{{
)
RETURNS TABLE (
  device_name TEXT,
  vessel_name TEXT,
  coin_uuid VARCHAR(6),
  start_time TIMESTAMP WITH TIME ZONE,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15, 12),
  time_stamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.device_name, v.vessel_name, 
           SUBSTRING(co.coin_uuid, 27) AS coin_uuid, cr.start_time,
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
       AND trip_date = start_time::DATE -- trip from same day as coin reading
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
