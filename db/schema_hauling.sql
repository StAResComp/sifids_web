-- schema for Tania's analysis on activity and effort

-- activities identified, e.g. hauling, not hauling
DROP TABLE IF EXISTS tm_activities CASCADE;
CREATE TABLE tm_activities (
  activity_id SERIAL PRIMARY KEY,
  activity VARCHAR(255)
);

-- vessels from Tania's cleaned up data
DROP TABLE IF EXISTS tm_vessels CASCADE;
CREATE TABLE tm_vessels (
  vessel_id SERIAL PRIMARY KEY,
  vessel_name VARCHAR(255)
);

-- trips from Tania's cleaned up data
DROP TABLE IF EXISTS tm_trips CASCADE;
CREATE TABLE tm_trips (
  trip_id SERIAL PRIMARY KEY,
  vessel_id INTEGER REFERENCES tm_vessels (vessel_id) ON DELETE CASCADE,
  trip_name VARCHAR(255),
  creels_low INTEGER,
  creels_high INTEGER,
  distance NUMERIC(20,12)
);

CREATE INDEX trip_vessel_idx ON tm_trips (vessel_id);
CREATE INDEX trip_name_idx ON tm_trips (trip_name);

-- grid squares that have been entered by vessels
DROP TABLE IF EXISTS tm_grid;
CREATE TABLE tm_grid (
  grid_id SERIAL PRIMARY KEY,
  latitude1 NUMERIC(15, 12),
  longitude1 NUMERIC(15, 12),
  latitude2 NUMERIC(15, 12),
  longitude2 NUMERIC(15, 12)
);

-- tracks from Tania's cleaned up data
DROP TABLE IF EXISTS tm_tracks;
CREATE TABLE tm_tracks (
  trip_id INTEGER REFERENCES tm_trips (trip_id) ON DELETE CASCADE,
  latitude NUMERIC(15, 12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  activity_id INTEGER REFERENCES tm_activities(activity_id),
  segment INTEGER,
  dummy INTEGER DEFAULT 0,
  grid_id INTEGER
);

CREATE INDEX tracks_trip ON tm_tracks (trip_id, time_stamp, latitude, longitude);
CREATE INDEX tracks_coords ON tm_tracks (time_stamp, latitude, longitude);

-- effort (distance, creels, trips) and catch
DROP TABLE IF EXISTS tm_effort;
CREATE TABLE tm_effort (
  vessel_week VARCHAR(255),
  vessel_id INTEGER REFERENCES tm_vessels (vessel_id) ON DELETE CASCADE,
  distance NUMERIC(20,12),
  creels NUMERIC(20,12),
  species VARCHAR(255),
  catch NUMERIC(20,12),
  trips INTEGER,
  midweek DATE
);

CREATE INDEX effort_week ON tm_effort (midweek);
CREATE INDEX effort_vessel_week ON tm_effort(vessel_id, midweek);
