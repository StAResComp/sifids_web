-- -*- pgsql -*-

-- functions for FISH 1 form

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
