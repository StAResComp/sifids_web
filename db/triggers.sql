-- -*- pgsql -*-

-- triggers for SIFIDS schema

-- procedure for setting geom column in tracks
CREATE OR REPLACE FUNCTION set_geom_for_track (
)
RETURNS TRIGGER
AS $FUNC$
BEGIN
  UPDATE tracks 
     SET geom = ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat), 4326)
   WHERE upload_id = NEW.upload_id 
     AND time_stamp = NEW.time_stamp;
   
   RETURN NEW;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;

-- procedure for setting geom column in observations
CREATE OR REPLACE FUNCTION set_geom_for_observation (
)
RETURNS TRIGGER
AS $FUNC$
BEGIN
  UPDATE observations
     SET geom = ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat), 4326)
   WHERE upload_id = NEW.upload_id 
     AND time_stamp = NEW.time_stamp;
   
   RETURN NEW;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;

CREATE TRIGGER set_geom_for_track_tgr
AFTER INSERT ON tracks
FOR EACH ROW EXECUTE PROCEDURE set_geom_for_track();

CREATE TRIGGER set_geom_for_observation_tgr
AFTER INSERT ON observations
FOR EACH ROW EXECUTE PROCEDURE set_geom_for_observation();
