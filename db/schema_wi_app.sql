-- table for raw JSON data
-- links data to user
DROP TABLE IF EXISTS app.WIRawData CASCADE;
CREATE TABLE app.WIRawData (
  ingest_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES "Users" (user_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  ingest_time TIMESTAMP DEFAULT NOW(),
  raw_json JSON
);

-- table for processed observation data
DROP TABLE IF EXISTS app.WIObservations CASCADE;
CREATE TABLE app.WIObservations (
  observation_id SERIAL PRIMARY KEY,
  ingest_id INTEGER REFERENCES app.WIRawData (ingest_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  animal_id INTEGER REFERENCES entities."Animals" (animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  obs_count INTEGER,
  description TEXT,
  obs_date TIMESTAMP,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  notes TEXT
);

-- table for behaviour from observations
DROP TABLE IF EXISTS app.WIObservationBehaviours CASCADE;
CREATE TABLE app.WIObservationBehaviours (
  observation_id INTEGER REFERENCES app.WiObservations (observation_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  behaviour VARCHAR(64)
);

-- table for processed catch data
DROP TABLE IF EXISTS app.WICatch CASCADE;
CREATE TABLE app.WICatch (
  ingest_id INTEGER REFERENCES app.WIRawData (ingest_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  catch_date TIMESTAMP,
  animal_id INTEGER REFERENCES entities."Animals" (animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  caught INTEGER,
  retained INTEGER
);

DROP TABLE IF EXISTS app.WIFishingActivity CASCADE;
CREATE TABLE app.WIFishingActivity (
  ingest_id INTEGER REFERENCES app.WIRawData (ingest_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  activity_date TIMESTAMP,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  gear_id INTEGER REFERENCES entities."Gears" (gear_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  mesh_id INTEGER REFERENCES entities."MeshSizes" (mesh_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  animal_id INTEGER REFERENCES entities."Animals" (animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  state_id INTEGER REFERENCES entities."States" (state_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  presentation_id INTEGER REFERENCES entities."Presentations" (presentation_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  weight NUMERIC(6, 2),
  dis BOOLEAN,
  bms BOOLEAN,
  pots_hauled INTEGER,
  landing_date TIMESTAMP,
  buyer_transporter TEXT
);

-- table for processed creel data
DROP TABLE IF EXISTS app.WICreels CASCADE;
CREATE TABLE app.WICreels (
  ingest_id INTEGER REFERENCES app.WIRawData (ingest_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  activityDate TIMESTAMP,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  notes TEXT
);
