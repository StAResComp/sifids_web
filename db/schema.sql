-- -*- pgsql -*-

-- schema for SIFIDS observations

--CREATE EXTENSION postgis; -- only needed once really

DROP TABLE IF EXISTS vessels CASCADE;
CREATE TABLE vessels (
  vessel_id SERIAL PRIMARY KEY,
  vessel_name TEXT UNIQUE,
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  active INTEGER DEFAULT 1
);

DROP TABLE IF EXISTS uploads CASCADE;
CREATE TABLE uploads (
  upload_id SERIAL PRIMARY KEY,
  vessel_id INTEGER REFERENCES vessels (vessel_id),
  time_stamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DROP TABLE IF EXISTS tracks;
CREATE TABLE tracks (
  upload_id INTEGER REFERENCES uploads (upload_id),
  time_stamp TIMESTAMP WITH TIME ZONE,
  fishing INTEGER DEFAULT 0,
  lat NUMERIC,
  lon NUMERIC,
  accuracy NUMERIC
--  geom GEOMETRY(POINT, 4326),
--  PRIMARY KEY (upload_id, time_stamp)
);

CREATE INDEX track_time_stamp_idx ON tracks (time_stamp);
--CREATE INDEX track_gist_idx ON tracks USING GIST(geom);

DROP TABLE IF EXISTS animals CASCADE;
CREATE TABLE animals (
  animal_id SERIAL PRIMARY KEY,
  animal_name TEXT
);

DROP TABLE IF EXISTS species CASCADE;
CREATE TABLE species (
  species_id SERIAL PRIMARY KEY,
  species_name TEXT
);

DROP TABLE IF EXISTS observation_uploads CASCADE;
CREATE TABLE observation_uploads (
  upload_id SERIAL PRIMARY KEY,
  vessel_id INTEGER REFERENCES vessels (vessel_id),
  time_stamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DROP TABLE IF EXISTS observations CASCADE;
CREATE TABLE observations (
  upload_id INTEGER REFERENCES observation_uploads (upload_id),
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
