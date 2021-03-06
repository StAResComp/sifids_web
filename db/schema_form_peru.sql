-- -*- pgsql -*-

-- schema for SIFIDS Peru form

SET SCHEMA 'peru';

-- form header
DROP TABLE IF EXISTS form_header CASCADE;
CREATE TABLE form_header (
  upload_id INTEGER PRIMARY KEY REFERENCES uploads(upload_id) ON DELETE CASCADE ON UPDATE CASCADE,
  vessel_id INTEGER,
  port_of_departure TEXT,
  port_of_landing TEXT,
  vessel_name TEXT,
  owner_master TEXT,
  address TEXT
);

-- row in form
DROP TABLE IF EXISTS form_row CASCADE;
CREATE TABLE form_row (
  form_row_id SERIAL PRIMARY KEY,
  upload_id INTEGER REFERENCES form_header(upload_id) ON DELETE CASCADE ON UPDATE CASCADE,
  fishing_activity_date TIMESTAMP WITH TIME ZONE,
  lat_lang VARCHAR(16),
  gear TEXT,
  landing_or_discard_date TIMESTAMP WITH TIME ZONE,
  comments TEXT,
  mesh_size INTEGER,
  net_size INTEGER
);

-- row for each fish in row
DROP TABLE IF EXISTS form_row_fish CASCADE;
CREATE TABLE form_row_fish (
  form_row_id BIGINT REFERENCES form_row(form_row_id) ON DELETE CASCADE ON UPDATE CASCADE,
  species_id INTEGER REFERENCES species(species_id),
  species_weight NUMERIC,
  PRIMARY KEY (form_row_id, species_id)
);