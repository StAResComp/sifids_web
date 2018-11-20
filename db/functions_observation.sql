-- -*- pgsql -*-

-- functions for original app observations

-- insert row in observation upload table
CREATE OR REPLACE FUNCTION insertObservationUpload ( --{{{
  in_vessel_id INTEGER,
  OUT out_upload_id BIGINT
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  INSERT INTO observation_uploads (vessel_id)
       VALUES (in_vessel_id);
        
  -- return upload ID
RETURN QUERY
  SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('observation_uploads', 'upload_id'));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- insert a row in the observation table
-- returning the upload ID
CREATE OR REPLACE FUNCTION insertObservation ( --{{{
  in_upload_id INTEGER,
  in_time_stamp TIMESTAMP WITH TIME ZONE,
  in_lat NUMERIC,
  in_lon NUMERIC,
  in_animal_id INTEGER,
  in_species_id INTEGER,
  in_count INTEGER,
  in_notes TEXT,
  OUT out_upload_id INTEGER
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO observations (upload_id, time_stamp, lat, lon, animal_id, species_id, observed_count, notes)
       VALUES (in_upload_id, in_time_stamp, in_lat, in_lon, in_animal_id, in_species_id, in_count, in_notes);
        
  -- return upload ID - just to return something
RETURN QUERY
  SELECT in_upload_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
