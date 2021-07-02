/****f* wi_app_functions.sql/WIAppInsert
 * NAME
 * WIAppInsert
 * SYNOPSIS
 * Called from Django to insert JSON data from app
 * ARGUMENTS
 *   * user_email - VARCHAR - identifies user
 *   * json - JSON - data from app
 * RETURN VALUE
 * 
 ******
 */
CREATE OR REPLACE FUNCTION WIAppInsert ( --{{{
  in_user_email VARCHAR(255),
  in_json JSON
)
RETURNS TABLE (
  inserted BOOLEAN
)
AS $FUNC$
DECLARE
  new_ingest_id INTEGER;
  obs_id INTEGER;
  r RECORD;
BEGIN
   -- record raw json data and link to user
   INSERT
     INTO app.WiRawData
          (user_id, raw_json)
   SELECT u.user_id, in_json
     FROM "Users" AS u
    WHERE u.user_email = in_user_email
RETURNING ingest_id 
     INTO new_ingest_id;

  -- finished if user not found/insert failed
  IF NOT FOUND THEN
    RETURN QUERY
      SELECT FALSE;
    RETURN;
  END IF;

  RAISE NOTICE 'in proc';
  
  -- catch data
  IF in_json::JSONB ? 'catches' THEN
    INSERT
      INTO app.WICatch
           (ingest_id, catch_date, animal_id, caught, retained)
    SELECT new_ingest_id, j."date", a.animal_id, j.caught, j.retained
      FROM JSON_TO_RECORDSET(in_json -> 'catches') AS j
           ("id" INTEGER, "date" TIMESTAMP, species VARCHAR(32), 
            caught INTEGER, retained INTEGER)
INNER JOIN entities."Animals" AS a 
        ON j.species = a.animal_name;
        
    RETURN QUERY
      SELECT FOUND;
      
  -- observations
-- {"observations":[{"id":2,"num":1,"behaviour":["Approaching the vessel","other"],
--                   "date":"2021-06-29T15:34:41.069Z","animal":"Seal",
--                   "species":"Harbour (Common) Seal",
--                   "latitude":56.31369283184135,"longitude":-3.0216615602865473,
--                   "notes":"this is a test"}]}
  ELSIF in_json::JSONB ? 'observations' THEN
    -- loop over objects in observation array
    FOR r IN 
      SELECT a.animal_id, j.num, j.behaviour, j."date",
             j.latitude AS lat, j.longitude AS lng, 
             j.notes
        FROM JSON_TO_RECORDSET(in_json -> 'observations') AS j
             (id INTEGER, num INTEGER, behaviour JSON,
              "date" TIMESTAMP, animal TEXT, species TEXT, 
              latitude NUMERIC(15, 12), longitude NUMERIC(15, 12),
              notes TEXT)
   LEFT JOIN entities."Animals" AS a
          ON a.animal_name ILIKE j.species
        LOOP
        -- insert single observation, getting observation ID
             INSERT 
               INTO app.WIObservations
                    (ingest_id, animal_id, obs_count, obs_date, lat, lng, notes)
             VALUES (new_ingest_id, r.animal_id, r.num, r."date", r.lat, r.lng, r.notes)
          RETURNING observation_id
               INTO obs_id;
             
        -- insert behaviours associated with observation, using observation ID
             INSERT 
               INTO app.WIObservationBehaviours
                    (observation_id, behaviour)
             SELECT obs_id, "value"::VARCHAR(64)
               FROM JSON_ARRAY_ELEMENTS_TEXT(r.behaviour);
    END LOOP;

    RETURN QUERY
      SELECT FOUND;
    
  END IF;
  
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

/****f* wi_app_functions.sql/WICatchInsert
 * NAME
 * WICatchInsert
 * SYNOPSIS
 * Trigger function for inserting catch data
 * RETURN VALUE
 * NULL - row already inserted in parent table, so just return NULL.
 ******
 */
-- {​"catches":[{​"id":4,"date":"2021-06-29T15:18:36.073Z",
--              "species":"Brown Crab","caught":2,"retained":1}​]}​
CREATE OR REPLACE FUNCTION WICatchInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
BEGIN
    INSERT
      INTO app.WICatch
           (ingest_id, catch_date, animal_id, caught, retained)
    SELECT NEW.ingest_id, j."date", a.animal_id, j.caught, j.retained
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           ("date" TIMESTAMP, species VARCHAR(32), 
            caught INTEGER, retained INTEGER)
INNER JOIN entities."Animals" AS a 
        ON j.species = a.animal_name;
  
    RETURN NULL;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

/****f* wi_app_functions.sql/WIFishing ActivityInsert
 * NAME
 * WIFishingActivityInsert
 * SYNOPSIS
 * Trigger function for inserting fishing activity data
 * RETURN VALUE
 * NULL - row already inserted in parent table, so just return NULL.
 ******
 */
-- {​"entries":[{​"id":1,"DIS":false,"BMS":false,"activityDate":"2021-06-29T15:35:35.394Z",
--              "latitude":56.31359297361409,"longitude":-3.021656163422738,
--              "gear":" Pots/traps FPO ","meshSize":" 80mm ","species":" Brown Crab ",
--              "state":" Live ","presentation":" Whole ","weight":10,
--              "numPotsHauled":2,"landingDiscardDate":"2021-06-29T15:36:06.000Z",
--              "buyerTransporterRegLandedToKeeps":"this is a test"}​]}​
CREATE OR REPLACE FUNCTION WIFishingActivityInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
BEGIN
    INSERT
      INTO app.WIFishingActivity
           (ingest_id, activity_date, lat, lng, gear_id, mesh_id, animal_id,
            state_id, presentation_id, weight, dis, bms, pots_hauled, 
            landing_date, buyer_transporter)
    SELECT NEW.ingest_id, j."activityDate" AS activity_date, 
           j.latitude AS lat, j.longitude AS lng,
           g.gear_id, m.mesh_id, a.animal_id, s.state_id, p.presentation_id,
           j.weight, j."DIS" AS dis, j."BMS" AS bms, 
           j."numPotsHauled" AS pots_hauled, j."landingDiscardDate" AS landing_date, 
           j."buyerTransporterRegLandedToKeeps"
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           ("activityDate" TIMESTAMP, 
            latitude NUMERIC(15, 12), longitude NUMERIC(15, 12),
            gear VARCHAR(32), "meshSize" VARCHAR(16), species TEXT, state VARCHAR(32),
            presentation VARCHAR(32), weight NUMERIC(6, 2), "DIS" BOOLEAN, "BMS" BOOLEAN,
            "numPotsHauled" INTEGER, "landingDiscardDate" TIMESTAMP, 
            "buyerTransporterRegLandedToKeeps" TEXT)
LEFT JOIN entities."Gears" AS g ON (g.gear_name = j.gear)
LEFT JOIN entities."MeshSizes" AS m ON (m.mesh_size_name = j."meshSize")
LEFT JOIN entities."Animals" AS a ON (a.animal_name = j.species)
LEFT JOIN entities."States" AS s ON (s.state_name = j.state)
LEFT JOIN entities."Presentations" AS p ON (p.presentation_name = j.presentation);

    RETURN NULL;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

/****f* wi_app_functions.sql/WICreels
 * NAME
 * WICreels
 * SYNOPSIS
 * Trigger function for inserting creel data
 * RETURN VALUE
 * NULL - row already inserted in parent table, so just return NULL.
 ******
 */
-- {​"creels":[{​"id":4,"date":"2021-06-29T15:18:55.344Z",
--             "latitude":56.31364200762157,"longitude":-3.0216440354900453,
--             "notes":"this is a test"}​]}​
CREATE OR REPLACE FUNCTION WICreelsInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
BEGIN
    INSERT
      INTO app.WICreels
           (ingest_id, activityDate, lat, lng, notes)
    SELECT NEW.ingest_id, j."date", j.latitude, j.longitude, j.notes
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           ("date" TIMESTAMP, lat NUMERIC(15, 12), lng NUMERIC(15, 12),
            notes TEXT);
    RETURN NULL;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

/****f* wi_app_functions.sql/WIAppUserRegistered
 * NAME
 * WIAppUserRegistered
 * SYNOPSIS
 * Called from Django to add app user to database
 * ARGUMENTS
 *   * in_user_name - TEXT - full name of user
 *   * in_user_email - VARCHAR(255) - email address of user
 * RETURN VALUE
 * Boolean - true when success
 ******
 */
CREATE OR REPLACE FUNCTION WIAppUserRegistered ( --{{{
  in_user_name TEXT,
  in_user_email VARCHAR(255)
)
RETURNS TABLE (
  inserted BOOLEAN
)
AS $FUNC$
BEGIN
  -- make sure that user doesn't already exist
  PERFORM user_id
     FROM "Users"
    WHERE user_email = in_user_email;
    
  -- not found, so add user
  IF NOT FOUND THEN
    INSERT
      INTO "Users" (user_name, user_email, user_type_id)
    VALUES (in_user_name, in_user_email, 2); -- 2 is fisher user type id
  END IF;
  
  RETURN QUERY
    SELECT FOUND;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
