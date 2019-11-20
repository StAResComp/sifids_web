-- schema for users of the Shiny app

DROP TABLE IF EXISTS app_users;
CREATE TABLE app_users (
  user_id SERIAL PRIMARY KEY,
  user_name TEXT UNIQUE,
  user_password TEXT,
  user_role CHAR(1),
  vessel_id INTEGER REFERENCES tm_vessels (vessel_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- stored procedure for checking user details
CREATE OR REPLACE FUNCTION appLogin ( --{{{
  in_username TEXT,
  in_password TEXT
)
RETURNS TABLE (
  user_id INTEGER,
  user_role CHAR(1),
  vessel_id INTEGER,
  vessel_name VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_role, v.vessel_id, v.vessel_name
      FROM app_users AS u
 LEFT JOIN tm_vessels AS v USING (vessel_id)
     WHERE user_name = in_username
       AND user_password = CRYPT(in_password, user_password);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
