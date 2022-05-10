-- -*- pgsql -*-

CREATE TABLE entities."Coins" (
  coin_id SERIAL PRIMARY KEY,
  coin_uuid VARCHAR(32) UNIQUE,
  coin_major VARCHAR(4),
  coin_minor VARCHAR(4),
  added TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE CoinDevice (
  coin_device_id SERIAL PRIMARY KEY,
  coin_id INTEGER REFERENCES entities."Coins" (coin_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  device_id INTEGER REFERENCES "Devices" (device_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  paired_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE "CoinReadings" (
  coin_device_id INTEGER REFERENCES "CoinDevice" (coin_device_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  signal INTEGER
);

