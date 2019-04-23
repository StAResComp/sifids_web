-- -*- pgsql -*-

SET SCHEMA 'traccar';

-- table definitions for data coming from Traccar

-- devices from traccar
DROP TABLE IF EXISTS traccar_devices CASCADE;
CREATE TABLE traccar_devices (
  device_id SERIAL PRIMARY KEY,
  device_name VARCHAR(255) UNIQUE,
  device_string VARCHAR(255) UNIQUE,
  protocol VARCHAR(255)
);

-- trips made by devices
DROP TABLE IF EXISTS traccar_trips CASCADE;
CREATE TABLE traccar_trips (
  trip_id SERIAL PRIMARY KEY,
  device_id INTEGER REFERENCES traccar_devices (device_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- tracks from traccar
DROP TABLE IF EXISTS traccar_track;
CREATE TABLE traccar_track (
  trip_id INTEGER REFERENCES traccar_trips (trip_id) ON DELETE CASCADE ON UPDATE CASCADE,
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE
);

CREATE INDEX track_time_idx ON traccar_track (time_stamp, latitude, longitude);

-- different attributes from devices
DROP TABLE IF EXISTS traccar_attribute_names CASCADE;
CREATE TABLE traccar_attribute_names (
  attribute_id SERIAL PRIMARY KEY,
  attribute_name VARCHAR(255) UNIQUE
);

-- attribute values from devices
DROP TABLE IF EXISTS traccar_attributes;
CREATE TABLE traccar_attributes (
  attribute_id INTEGER REFERENCES traccar_attribute_names (attribute_id) ON DELETE CASCADE ON UPDATE CASCADE,
  device_id INTEGER REFERENCES traccar_devices (device_id) ON DELETE CASCADE ON UPDATE CASCADE,
  attribute_value FLOAT,
  time_stamp TIMESTAMP WITH TIME ZONE
);

CREATE INDEX attribute_device_idx ON traccar_attributes (device_id, time_stamp, attribute_id);
