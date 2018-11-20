-- -*- pgsql -*-

-- common tables used by both apps

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
