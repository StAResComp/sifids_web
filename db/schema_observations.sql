-- -*- pgsql -*-

-- tables for original app observations

DROP TABLE IF EXISTS observation_uploads CASCADE;
CREATE TABLE observation_uploads (
  upload_id SERIAL PRIMARY KEY,
  vessel_id INTEGER REFERENCES vessels (vessel_id) ON DELETE CASCADE ON UPDATE CASCADE,
  time_stamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DROP TABLE IF EXISTS observations CASCADE;
CREATE TABLE observations (
  upload_id INTEGER REFERENCES observation_uploads (upload_id) ON DELETE CASCADE ON UPDATE CASCADE,
  time_stamp TIMESTAMP WITH TIME ZONE,
  animal_id INTEGER REFERENCES animals (animal_id),
  species_id INTEGER REFERENCES species (species_id),
  lat NUMERIC,
  lon NUMERIC,
--  geom GEOMETRY(POINT, 4326),
  observed_count INTEGER,
  notes TEXT,
  PRIMARY KEY (upload_id, time_stamp)
);

CREATE INDEX observation_time_stamp_idx ON observations (time_stamp);
--CREATE INDEX observation_gist_idx ON observations USING GIST(geom);
