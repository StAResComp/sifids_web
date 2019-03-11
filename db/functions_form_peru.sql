-- -*- pgsql -*-

-- functions for Peru form
SET SCHEMA 'peru';

-- record header of form
CREATE OR REPLACE FUNCTION addFormHeader ( --{{{
  in_upload_id INTEGER,
  in_port_of_departure TEXT,
  in_port_of_landing TEXT,
  in_vessel_id INTEGER,
  in_vessel_name TEXT,
  in_owner_master TEXT,
  in_address TEXT
)
RETURNS SETOF INTEGER
AS $FUNC$
BEGIN
  INSERT INTO form_header (upload_id, vessel_id, port_of_departure, port_of_landing, vessel_name, owner_master, address)
       VALUES (in_upload_id, in_vessel_id, in_port_of_departure, in_port_of_landing, in_vessel_name, in_owner_master, in_address);
       
  RETURN QUERY
    SELECT in_upload_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- record row of Fish 1 form
CREATE OR REPLACE FUNCTION addFormRow ( --{{{
  in_upload_id INTEGER,
  in_fishing_activity_date TIMESTAMP WITH TIME ZONE,
  in_lat_lang VARCHAR(16),
  in_gear TEXT,
  in_landing_or_discard_date TIMESTAMP WITH TIME ZONE,
  in_comments TEXT,
  in_mesh_size INTEGER,
  in_net_size INTEGER
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  INSERT INTO form_row (upload_id, fishing_activity_date, lat_lang, gear, landing_or_discard_date, comments, mesh_size, net_size)
       VALUES (in_upload_id, in_fishing_activity_date, in_lat_lang, in_gear, in_landing_or_discard_date, in_comments, in_mesh_size, in_net_size);
       
  RETURN QUERY
    SELECT CURRVAL(PG_GET_SERIAL_SEQUENCE('form_row', 'form_row_id'));
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- record one species of fish from row in form
CREATE OR REPLACE FUNCTION addFormRowFish ( --{{{
  in_form_row_id BIGINT,
  in_species_id INTEGER,
  in_species_weight NUMERIC
)
RETURNS SETOF BIGINT
AS $FUNC$
BEGIN
  INSERT INTO form_row_fish (form_row_id, species_id, species_weight)
       VALUES (in_form_row_id, in_species_id, in_species_weight);
       
  RETURN QUERY
    SELECT in_form_row_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
