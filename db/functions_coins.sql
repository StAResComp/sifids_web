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
