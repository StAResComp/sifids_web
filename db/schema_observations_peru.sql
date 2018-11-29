-- -*- pgsql -*-

-- tables for Peru app observations

SET SCHEMA 'peru';

DROP TABLE IF EXISTS observation_uploads CASCADE;
CREATE TABLE observation_uploads (
  upload_id SERIAL PRIMARY KEY,
  vessel_id INTEGER REFERENCES vessels (vessel_id) ON DELETE CASCADE ON UPDATE CASCADE,
  time_stamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DROP TABLE IF EXISTS observations CASCADE;
CREATE TABLE observations (
  upload_id INTEGER REFERENCES observation_uploads (upload_id) ON DELETE CASCADE ON UPDATE CASCADE,
  species_id INTEGER REFERENCES species (species_id),
  observed_count INTEGER,
  observed_weight NUMERIC
);
