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
  element JSONB;
  user_id INTEGER;
BEGIN
  -- get user ID using email
  SELECT u.user_id
    INTO user_id
    FROM "Users" AS u
   WHERE u.user_email = in_user_email;
   
  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
    
  -- get first element from JSON array
  element := in_json -> 0;
  
  -- catch data
  IF element ? 'caught' THEN
    INSERT 
      INTO app.WIRawCatch
           (user_id, raw_json)
    VALUES (user_id, in_json);
  -- observation data
  ELSIF element ? 'behaviour' THEN
    INSERT 
      INTO app.WIRawObservations
           (user_id, raw_json)
    VALUES (user_id, in_json);
  -- fishing activity
  ELSIF element ? 'activityDate' THEN
    INSERT 
      INTO app.WIRawFishingActivity
           (user_id, raw_json)
    VALUES (user_id, in_json);
  -- consent data
  ELSIF in_json ? 'understoodSheet' THEN
    INSERT 
      INTO app.WIRawConsent
           (user_id, raw_json)
    VALUES (user_id, in_json);
  END IF;
  
  RETURN QUERY
    SELECT FOUND;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

/****f* wi_app_functions.sql/WIObservationInsert
 * NAME
 * WIObservationInsert
 * SYNOPSIS
 * Trigger function for inserting observation data
 * RETURN VALUE
 * NULL - row already inserted in parent table, so just return NULL.
 ******
 */
CREATE OR REPLACE FUNCTION WIObservationInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
DECLARE 
  obs_id INTEGER;
  r RECORD;
BEGIN
  -- loop over objects in observation array
  FOR r IN 
    SELECT a.animal_id, j.description, j."date", j.num,
           j.latitude AS lat, j.longitude AS lng, 
           j.notes, j.behaviour
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           (animal VARCHAR(32), species VARCHAR(32), 
            description TEXT, "date" TIMESTAMP, num INTEGER,
            latitude NUMERIC(15, 12), longitude NUMERIC(15, 12),
            notes TEXT, behaviour JSON)
INNER JOIN entities."Animals" AS a
        ON a.animal_name = j.species
      LOOP
      -- insert single observation, getting observation ID
           INSERT 
             INTO app.WIObservations
                  (ingest_id, animal_id, obs_count, description, obs_date, 
                   lat, lng, notes)
           VALUES (NEW.ingest_id, r.animal_id, r.num, r.description, r."date", 
                   r.lat, r.lng, r.notes)
        RETURNING observation_id
             INTO obs_id;
             
      -- insert behaviours associated with observation, using observation ID
           INSERT 
             INTO app.WIObservationBehaviours
                  (observation_id, behaviour)
           SELECT obs_id, "value"::VARCHAR(64)
             FROM JSON_ARRAY_ELEMENTS_TEXT(r.behaviour);
  END LOOP;
  
    RETURN NULL;
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

/****f* wi_app_functions.sql/WIConsentInsert
 * NAME
 * WIConsentInsert
 * SYNOPSIS
 * Trigger function for inserting consent data
 * RETURN VALUE
 * NULL - row already inserted in parent table, so just return NULL.
 ******
 */
CREATE OR REPLACE FUNCTION WIConsentInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
BEGIN
    INSERT
      INTO app.WIConsent
           (ingest_id, understoodSheet, questionsOpportunity, questionsAnswered,
           understandWithdrawal, understandCoding, agreeArchiving, awareRisks,
           agreeTakePart, agreePhotoTaken, agreePhotoPublished, agreePhotoFutureUse,
           consent_date, consent_name)
    SELECT NEW.ingest_id, 
           j.understoodSheet, j.questionsOpportunity, j.questionsAnswered,
           j.understandWithdrawal, j.understandCoding, 
           (j.secondary ->> 'agreeArchiving')::BOOLEAN, 
           (j.secondary ->> 'awareRisks')::BOOLEAN,
           (j.secondary ->> 'agreeTakePart')::BOOLEAN, 
           (j.photography ->> 'agreePhotoTaken')::BOOLEAN, 
           (j.photography ->> 'agreePhotoPublished')::BOOLEAN, 
           (j.photography ->> 'agreePhotoFutureUse')::BOOLEAN,
           j.consent_date, j.consent_name
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           (understoodSheet BOOLEAN, questionsOpportunity BOOLEAN, questionsAnswered BOOLEAN,
            understandWithdrawal BOOLEAN, understandCoding BOOLEAN, 
            secondary JSON, photography JSON,
            consent_date TIMESTAMP, consent_name TEXT);
  
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
CREATE OR REPLACE FUNCTION WIFishingActivityInsert () --{{{
RETURNS TRIGGER
AS $FUNC$
BEGIN
    INSERT
      INTO app.WIFishingActivity
           (ingest_id, activity_date, lat, lng, gear_id, mesh_size, animal_id,
            state_id, presentation_id, weight, dis, bms, pots_hauled, 
            landing_date, buyer_transporter)
    SELECT NEW.ingest_id, j.activityDate::TIMESTAMP, j.latitude AS lat, j.longitude AS lng,
           g.gear_id, m.mesh_id, a.animal_id, s.state_id, p.presentation_id,
           j.weight, j.DIS, j.BMS, 
           j.numPotsHauled, j.landingDiscardDate, 
           j.buyerTransporterRegLandedToKeeps
      FROM JSON_TO_RECORDSET(NEW.raw_json) AS j
           (activityDate VARCHAR(32), latitude NUMERIC(15, 12), longitude NUMERIC(15, 12),
            gear VARCHAR(32), meshSize VARCHAR(16), species TEXT, state VARCHAR(32),
            presentation VARCHAR(32), weight NUMERIC(6, 2), DIS BOOLEAN, BMS BOOLEAN,
            numPotsHauled INTEGER, landingDiscardDate TIMESTAMP, 
            buyerTransporterRegLandedToKeeps TEXT)
LEFT JOIN entities."Gears" AS g ON (g.gear_name = j.gear)
LEFT JOIN entities."MeshSizes" AS m ON (m.mesh_size_name = j.meshSize)
LEFT JOIN entities."Animals" AS a ON (a.animal_name = j.species)
LEFT JOIN entities."States" AS s ON (s.state_name = j.state)
LEFT JOIN entities."Presentations" AS p ON (p.presentation_name = j.presentation);

    RETURN NULL;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- trigger to populate observation tables when observation JSON inserted into raw table
DROP TRIGGER IF EXISTS WIobservation_insert ON app.WIRawObservations;

CREATE TRIGGER WIobservation_insert AFTER INSERT ON app.WIRawObservations
FOR EACH ROW EXECUTE PROCEDURE WIObservationInsert();

-- trigger to populate catch table when catch JSON inserted into raw table
DROP TRIGGER IF EXISTS WIcatch_insert ON app.WIRawCatch;

CREATE TRIGGER WIcatch_insert AFTER INSERT ON app.WIRawCatch
FOR EACH ROW EXECUTE PROCEDURE WICatchInsert();

-- trigger to populate consent table when consent JSON inserted into raw table
DROP TRIGGER IF EXISTS WIconsent_insert ON app.WIRawConsent;

CREATE TRIGGER WIconsent_insert AFTER INSERT ON app.WIRawConsent
FOR EACH ROW EXECUTE PROCEDURE WIConsentInsert();

-- trigger to populate fishing activity table when activity JSON inserted into raw table
DROP TRIGGER IF EXISTS WIactivity_insert ON app.WIRawFishingActivity;

CREATE TRIGGER WIactivity_insert AFTER INSERT ON app.WIRawFishingActivity
FOR EACH ROW EXECUTE PROCEDURE WIFishingActivityInsert();
