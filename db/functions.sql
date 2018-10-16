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
  in_accuracy NUMERIC,
  OUT out_upload_id INTEGER
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO tracks (upload_id, time_stamp, fishing, lat, lon, accuracy)
       VALUES (in_upload_id, in_time_stamp, in_fishing, in_lat, in_lon, in_accuracy);
        
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
  -- first see if vessel already exists
  SELECT vessel_id
    INTO out_vessel_id
    FROM consent
   WHERE vessel_id = in_vessel_id
     AND consent_email = in_consent_email;
   
   -- doesn't exist
   IF (NOT FOUND) THEN
     INSERT INTO consent (vessel_id, consent_name, consent_email, consent_phone, pref_vessel_name, pref_owner_master_name)
          VALUES (in_vessel_id, in_consent_name, in_consent_email, in_consent_phone, in_pref_vessel_name, in_pref_owner_master_name);
   END IF;
        
  -- return vessel ID - just to return something
RETURN QUERY
  SELECT in_vessel_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- record header of Fish 1 form
CREATE OR REPLACE FUNCTION addFish1FormHeader ( --{{{
  in_upload_id INTEGER,
  in_fishery_office TEXT,
  in_email TEXT,
  in_port_of_departure TEXT,
  in_port_of_landing TEXT,
  in_vessel_id INTEGER,
  in_vessel_name TEXT,
  in_owner_master TEXT,
  in_address TEXT,
  in_total_pots_fishing INTEGER,
  in_comments TEXT
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO fish1_header (upload_id, vessel_id, fishery_office, email, port_of_departure, port_of_landing, vessel_name, owner_master, address, total_pots_fishing, comments)
       VALUES (in_upload_id, in_vessel_id, in_fishery_office, in_email, in_port_of_departure, in_port_of_landing, in_vessel_name, in_owner_master, in_address, in_total_pots_fishing, in_comments);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- record row of Fish 1 form
CREATE OR REPLACE FUNCTION addFish1FormRow ( --{{{
  in_upload_id INTEGER,
  in_fishing_activity_date TIMESTAMP WITH TIME ZONE,
  in_lat_lang VARCHAR(16),
  in_stat_rect_ices_area VARCHAR(8),
  in_gear TEXT,
  in_mesh_size INTEGER,
  in_species TEXT,
  in_state TEXT,
  in_presentation TEXT,
  in_weight NUMERIC,
  in_dis SMALLINT,
  in_bms SMALLINT,
  in_number_of_pots_hauled INTEGER,
  in_landing_or_discard_date TIMESTAMP WITH TIME ZONE,
  in_transporter_reg TEXT
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO fish1_row (upload_id, fishing_activity_date, lat_lang, stat_rect_ices_area, gear, mesh_size, species, state, presentation, weight, dis, bms, number_of_pots_hauled, landing_or_discard_date, transporter_reg)
       VALUES (in_upload_id, in_fishing_activity_date, in_lat_lang, in_stat_rect_ices_area, in_gear, in_mesh_size, in_species, in_state, in_presentation, in_weight, in_dis, in_bms, in_number_of_pots_hauled, in_landing_or_discard_date, in_transporter_reg);
  RETURN QUERY
    SELECT in_upload_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
