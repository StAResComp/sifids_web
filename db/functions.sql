-- -*- pgsql -*-

-- stored procedures for SIFIDS

-- insert a row in the track table
CREATE OR REPLACE FUNCTION insertTrack ( --{{{
  in_upload_id INTEGER,
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_fishing INTEGER,
  in_lat NUMERIC,
  in_lon NUMERIC,
  OUT out_upload_id INTEGER
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO tracks (upload_id, time_stamp, fishing, lat, lon)
       VALUES (in_upload_id, in_time_stamp, in_fishing, in_lat, in_lon);
        
  -- return upload ID - just to return something
RETURN QUERY
  SELECT in_upload_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- make sure that vessel with given name exists
-- adding it if necessary
CREATE OR REPLACE FUNCTION insertVessel ( --{{{
  in_vessel_name TEXT,
  OUT out_vessel_id BIGINT
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  -- first see if vessel already exists
  SELECT vessel_id
    INTO out_vessel_id
    FROM vessels
   WHERE vessel_name = in_vessel_name;
   
   -- doesn't exist
   IF (NOT FOUND) THEN
     -- insert it
     INSERT INTO vessels (vessel_name)
          VALUES (in_vessel_name);
     -- get last insert id
     SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('vessels', 'vessel_id'))
       INTO out_vessel_id;
   END IF;
        
  -- return vessel ID
RETURN QUERY
  SELECT out_vessel_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- insert row in upload table
CREATE OR REPLACE FUNCTION insertUpload ( --{{{
  in_vessel_id INTEGER,
  OUT out_upload_id BIGINT
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  INSERT INTO uploads (vessel_id)
       VALUES (in_vessel_id);
        
  -- return upload ID
RETURN QUERY
  SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('uploads', 'upload_id'));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
