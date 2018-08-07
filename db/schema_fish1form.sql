-- -*- pgsql -*-

-- schema for SIFIDS fish 1 form

DROP TABLE IF EXISTS fish1_header CASCADE;
CREATE TABLE fish1_header (
  upload_id INTEGER PRIMARY KEY,
  vessel_id INTEGER,
  fishery_office TEXT,
  email TEXT,
  port_of_departure TEXT,
  port_of_landing TEXT,
  vessel_name TEXT,
  owner_master TEXT,
  address TEXT,
  total_pots_fishing INTEGER
);

DROP TABLE IF EXISTS fish1_row CASCADE;
CREATE TABLE fish1_row (
  upload_id INTEGER,
  fishing_activity_date TIMESTAMP WITH TIME ZONE,
  lat_lang VARCHAR(16),
  stat_rect_ices_area VARCHAR(8),
  gear INTEGER,
  mesh_size INTEGER,
  species TEXT,
  state TEXT,
  presentation TEXT,
  weight NUMERIC,
  dis SMALLINT,
  bms SMALLINT,
  number_of_pots_hauled INTEGER,
  landing_or_discard_date TIMESTAMP WITH TIME ZONE,
  transporter_reg TEXT
);
