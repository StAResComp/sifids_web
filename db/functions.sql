-- -*- pgsql -*-

-- stored procedures for SIFIDS

-- insert a row in the track table
-- returning the upload ID
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

-- make sure that animal with given name exists
-- adding it if necessary
CREATE OR REPLACE FUNCTION insertAnimal ( --{{{
  in_animal_name TEXT,
  OUT out_animal_id BIGINT
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  -- first see if animal already exists
  SELECT animal_id
    INTO out_animal_id
    FROM animals
   WHERE animal_name = in_animal_name;
   
   -- doesn't exist
   IF (NOT FOUND) THEN
     -- insert it
     INSERT INTO animals (animal_name)
          VALUES (in_animal_name);
     -- get last insert id
     SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('animals', 'animal_id'))
       INTO out_animal_id;
   END IF;
        
  -- return animal ID
RETURN QUERY
  SELECT out_animal_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- make sure that species with given name exists
-- adding it if necessary
CREATE OR REPLACE FUNCTION insertSpecies ( --{{{
  in_species_name TEXT,
  OUT out_species_id BIGINT
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  -- first see if species already exists
  SELECT species_id
    INTO out_species_id
    FROM species
   WHERE species_name = in_species_name;
   
   -- doesn't exist
   IF (NOT FOUND) THEN
     -- insert it
     INSERT INTO species (species_name)
          VALUES (in_species_name);
     -- get last insert id
     SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('species', 'species_id'))
       INTO out_species_id;
   END IF;
        
  -- return species ID
RETURN QUERY
  SELECT out_species_id;
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

-- insert a row in the consent table
-- returning the vessel ID
CREATE OR REPLACE FUNCTION insertConsent ( --{{{
  in_vessel_id INTEGER,
  in_consent_name TEXT,
  in_consent_email TEXT,
  in_consent_phone TEXT,
  in_pref_vessel_name TEXT,
  in_pref_owner_master_name TEXT,
  OUT out_vessel_id INTEGER
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO consent (vessel_id, consent_name, consent_email, consent_phone, pref_vessel_name, pref_owner_master_name)
       VALUES (in_vessel_id, in_consent_name, in_consent_email, in_consent_phone, in_pref_vessel_name, in_pref_owner_master_name);
        
  -- return vessel ID - just to return something
RETURN QUERY
  SELECT in_vessel_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
