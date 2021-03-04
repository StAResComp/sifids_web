-- table for raw observation data
DROP TABLE WIRawObservations;
CREATE TABLE WIRawObservations (
  ingest_id SERIAL PRIMARY KEY,
  user_id INTEGER,
  ingest_time TIMESTAMP DEFAULT NOW(),
  raw_json JSON
);

-- table for processed observation data
DROP TABLE WIObservations;
CREATE TABLE WIObservations (
  observation_id SERIAL PRIMARY KEY,
  ingest_id INTEGER,
  animal_id INTEGER,
  obs_count INTEGER,
  description TEXT,
  obs_date TIMESTAMP,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  notes TEXT
);

-- table for behaviour from observations
DROP TABLE WIObservationBehaviours;
CREATE TABLE WIObservationBehaviours (
  observation_id INTEGER,
  behaviour VARCHAR(64)
);

-- table for raw catch data
DROP TABLE WIRawCatch;
CREATE TABLE WIRawCatch (
  ingest_id SERIAL PRIMARY KEY,
  user_id INTEGER,
  ingest_time TIMESTAMP DEFAULT NOW(),
  raw_json JSON
);

-- table for processed catch data
DROP TABLE WICatch;
CREATE TABLE WICatch (
  ingest_id INTEGER,
  catch_date TIMESTAMP,
  animal_id INTEGER,
  caught INTEGER,
  retained INTEGER
);

-- table for raw fishing activity
DROP TABLE WIRawFishingActivity;
CREATE TABLE WIRawFishingActivity (
  ingest_id SERIAL PRIMARY KEY,
  user_id INTEGER,
  ingest_time TIMESTAMP DEFAULT NOW(),
  raw_json JSON
);

DROP TABLE WIFishingActivity;
CREATE TABLE WIFishingActivity (
  ingest_id INTEGER,
  activity_date TIMESTAMP,
  lat NUMERIC(15, 12),
  lng NUMERIC(15, 12),
  gear_id INTEGER,
  mesh_size VARCHAR(16),
  animal_id INTEGER,
  state_id INTEGER,
  presentation_id INTEGER,
  weight NUMERIC(6, 2),
  dis BOOLEAN,
  bms BOOLEAN,
  pots_hauled INTEGER,
  landing_date TIMESTAMP,
  buyer_transporter TEXT
);

-- table for raw consent forms
DROP TABLE WIRawConsent;
CREATE TABLE WIRawConsent (
  ingest_id SERIAL PRIMARY KEY,
  user_id INTEGER,
  ingest_time TIMESTAMP DEFAULT NOW(),
  raw_json JSON
);

-- table for storing consent options chosen by app user
DROP TABLE WIConsent;
CREATE TABLE WIConsent (
  ingest_id INTEGER,
  understoodSheet BOOLEAN,
  questionsOpportunity BOOLEAN,
  questionsAnswered BOOLEAN,
  understandWithdrawal BOOLEAN,
  understandCoding BOOLEAN,
  agreeArchiving BOOLEAN,
  awareRisks BOOLEAN,
  agreeTakePart BOOLEAN,
  agreePhotoTaken BOOLEAN,
  agreePhotoPublished BOOLEAN,
  agreePhotoFutureUse BOOLEAN,
  consent_date TIMESTAMP,
  consent_name TEXT
);

