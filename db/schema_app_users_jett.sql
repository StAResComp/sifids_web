-- schema for users of the Shiny app

DROP TABLE IF EXISTS app_users;
CREATE TABLE app_users (
  user_id SERIAL PRIMARY KEY,
  user_name TEXT UNIQUE,
  user_password TEXT,
  user_role CHAR(1),
  vessel_id INTEGER REFERENCES tm_vessels (vessel_id) ON DELETE CASCADE ON UPDATE CASCADE
);

