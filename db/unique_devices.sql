-- adding table in entities schema for unique devices

CREATE TABLE entities."UniqueDevices" (
  unique_device_id SERIAL PRIMARY KEY,
  device_name TEXT UNIQUE,
  device_string TEXT UNIQUE,
  serial_number VARCHAR(255),
  model_id INTEGER REFERENCES entities."DeviceModels" (model_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  telephone VARCHAR(255), -- not unique, as SIMs may be moved around
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- copy details from "Devices" to entities."UniqueDevices"
INSERT INTO entities."UniqueDevices"
            (unique_device_id, device_name, device_string, serial_number, model_id, telephone, created)
     SELECT device_id, device_name, device_string, serial_number, model_id, telephone, created
       FROM "Devices"
   ORDER BY device_id;

-- add columns to "Devices"
ALTER TABLE "Devices"
  ADD COLUMN unique_device_id INTEGER REFERENCES entities."UniqueDevices" (unique_device_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  ADD COLUMN from_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN to_date TIMESTAMP WITH TIME ZONE;

-- update "Devices" to have unique_device_ids from entities."UniqueDevices"
UPDATE "Devices"
   SET unique_device_id = device_id;

-- set from_date where known using timestamps from tracks and fish1 forms
UPDATE "Devices"
   SET from_date = fd
  FROM (SELECT device_id, MIN(time_stamp) AS fd 
          FROM "Tracks" 
    INNER JOIN "Trips" USING (trip_id) 
      GROUP BY device_id) AS t 
 WHERE "Devices".device_id = t.device_id;

UPDATE "Devices" 
   SET from_date = fd
  FROM (SELECT device_id, MIN(fishing_date) AS fd 
          FROM "Uploads" 
    INNER JOIN fish1."Headers" USING (upload_id) 
    INNER JOIN fish1."Rows" USING (header_id) 
      GROUP BY device_id) AS t 
 WHERE "Devices".device_id = t.device_id;

-- remove columns from "Devices"
ALTER TABLE "Devices"
  DROP COLUMN device_name,
  DROP COLUMN device_string,
  DROP COLUMN serial_number,
  DROP COLUMN model_id,
  DROP COLUMN telephone,
  DROP COLUMN created;