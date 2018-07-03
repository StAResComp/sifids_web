-- -*- pgsql -*-

-- schema for SIFIDS consent form

DROP TABLE IF EXISTS consent CASCADE;
CREATE TABLE consent (
  vessel_id INTEGER PRIMARY KEY,
  consent_name TEXT,
  consent_email TEXT,
  consent_phone TEXT,
  pref_vessel_name TEXT,
  pref_owner_master_name TEXT,
  consent_read_understand BOOLEAN DEFAULT TRUE,
  consent_questions_opportunity BOOLEAN DEFAULT TRUE,
  consent_questions_answered BOOLEAN DEFAULT TRUE,
  consent_can_withdraw BOOLEAN DEFAULT TRUE,
  consent_confidential BOOLEAN DEFAULT TRUE,
  consent_data_archiving BOOLEAN DEFAULT TRUE,
  consent_risks BOOLEAN DEFAULT TRUE,
  consent_take_part BOOLEAN DEFAULT TRUE,
  consent_photography_capture BOOLEAN DEFAULT TRUE,
  consent_photography_publication BOOLEAN DEFAULT TRUE,
  consent_photography_future_studies BOOLEAN DEFAULT TRUE,
  consent_fish_1 BOOLEAN DEFAULT TRUE,
  time_stamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
