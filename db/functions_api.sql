-- stored procedures for admin API

-- get details on user
CREATE OR REPLACE FUNCTION apiGetUser ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  user_id INTEGER,
  user_name TEXT,
  user_email VARCHAR(255),
  user_type_id INTEGER,
  user_active SMALLINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_name, u.user_email, u.user_type_id, u.user_active
      FROM "Users" AS u
     WHERE u.user_id = in_user_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all users
CREATE OR REPLACE FUNCTION apiGetUsers ( --{{{
)
RETURNS TABLE (
  user_id INTEGER,
  user_name TEXT,
  user_email VARCHAR(255),
  user_type_id INTEGER,
  user_active SMALLINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_name, u.user_email, u.user_type_id, u.user_active
      FROM "Users" AS u
  ORDER BY u.user_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on device
CREATE OR REPLACE FUNCTION apiGetDevice ( --{{{
  in_device_id INTEGER
)
RETURNS TABLE (
  device_id INTEGER,
  vessel_id INTEGER,
  device_name TEXT,
  device_string TEXT,
  serial_number VARCHAR(255),
  model_id INTEGER,
  telephone VARCHAR(255),
  device_power_id INTEGER,
  device_active SMALLINT,
  engineer_notes TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.device_id, d.vessel_id, 
           d.device_name, d.device_string, d.serial_number, 
           d.model_id, d.telephone, d.device_power_id, 
           d.device_active, d.engineer_notes
      FROM "Devices" AS d
     WHERE d.device_id = in_device_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all devices
CREATE OR REPLACE FUNCTION apiGetDevices ( --{{{
)
RETURNS TABLE (
  device_id INTEGER,
  vessel_id INTEGER,
  device_name TEXT,
  device_string TEXT,
  serial_number VARCHAR(255),
  model_id INTEGER,
  telephone VARCHAR(255),
  device_power_id INTEGER,
  device_active SMALLINT,
  engineer_notes TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.device_id, d.vessel_id, 
           d.device_name, d.device_string, d.serial_number, 
           d.model_id, d.telephone, d.device_power_id, 
           d.device_active, d.engineer_notes
      FROM "Devices" AS d
  ORDER BY d.device_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on vessel
CREATE OR REPLACE FUNCTION apiGetVessel ( --{{{
  in_vessel_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name TEXT,
  vessel_code VARCHAR(255),
  vessel_pln VARCHAR(16),
  owner_id INTEGER,
  fo_id INTEGER,
  vessel_active SMALLINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name, v.vessel_code, v.vessel_pln, v.owner_id, v.fo_id, v.vessel_active
      FROM "Vessels" AS v
     WHERE v.vessel_id = in_vessel_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all vessels
CREATE OR REPLACE FUNCTION apiGetVessels ( --{{{
)
RETURNS TABLE (
  vessel_id INTEGER,
  vessel_name TEXT,
  vessel_code VARCHAR(255),
  vessel_pln VARCHAR(16),
  owner_id INTEGER,
  fo_id INTEGER,
  vessel_active SMALLINT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_pln || ' (' || v.vessel_name || ')' AS vessel_name, v.vessel_code, v.vessel_pln, v.owner_id, v.fo_id, v.vessel_active
      FROM "Vessels" AS v
  ORDER BY v.vessel_pln ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on project
CREATE OR REPLACE FUNCTION apiGetProject ( --{{{
  in_project_id INTEGER
)
RETURNS TABLE (
  project_id INTEGER,
  project_code VARCHAR(16),
  project_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.project_id, p.project_code, p.project_name
      FROM entities."Projects" AS p
     WHERE p.project_id = in_project_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all projects
CREATE OR REPLACE FUNCTION apiGetProjects ( --{{{
)
RETURNS TABLE (
  project_id INTEGER,
  project_code VARCHAR(16),
  project_name TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.project_id, p.project_code, p.project_name
      FROM entities."Projects" AS p
  ORDER BY p.project_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on fishery office
CREATE OR REPLACE FUNCTION apiGetFisheryOffice ( --{{{
  in_fo_id INTEGER
)
RETURNS TABLE (
  fo_id INTEGER,
  fo_town TEXT,
  fo_address TEXT,
  fo_email TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town, f.fo_address, f.fo_email
      FROM entities."FisheryOffices" AS f
     WHERE f.fo_id = in_fo_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all fishery offices
CREATE OR REPLACE FUNCTION apiGetFisheryOffices ( --{{{
)
RETURNS TABLE (
  fo_id INTEGER,
  fo_town TEXT,
  fo_address TEXT,
  fo_email TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town, f.fo_address, f.fo_email
      FROM entities."FisheryOffices" AS f
  ORDER BY f.fo_town ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on device power options
CREATE OR REPLACE FUNCTION apiGetDevicePower ( --{{{
  in_device_power_id INTEGER
)
RETURNS TABLE (
  device_power_id INTEGER,
  device_power_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.devce_power_id, d.device_power_name
      FROM entities."DevicePower" AS d
     WHERE d.devce_power_id = in_device_power_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all device power optionss
CREATE OR REPLACE FUNCTION apiGetDevicePowers ( --{{{
)
RETURNS TABLE (
  device_power_id INTEGER,
  device_power_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT d.devce_power_id, d.device_power_name
      FROM entities."DevicePower" AS d
  ORDER BY d.device_power_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on protocol
CREATE OR REPLACE FUNCTION apiGetProtocol ( --{{{
  in_protocol_id INTEGER
)
RETURNS TABLE (
  protocol_id INTEGER,
  protocol_name TEXT,
  protocol_code VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
     WHERE p.protocol_id = in_protocol_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all protocols
CREATE OR REPLACE FUNCTION apiGetProtocols ( --{{{
)
RETURNS TABLE (
  protocol_id INTEGER,
  protocol_name TEXT,
  protocol_code VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
  ORDER BY p.protocol_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on protocol
CREATE OR REPLACE FUNCTION apiGetProtocol ( --{{{
  in_protocol_id INTEGER
)
RETURNS TABLE (
  protocol_id INTEGER,
  protocol_name TEXT,
  protocol_code VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
     WHERE p.protocol_id = in_protocol_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on device model
CREATE OR REPLACE FUNCTION apiGetDeviceModel ( --{{{
  in_model_id INTEGER
)
RETURNS TABLE (
  model_id INTEGER,
  model_family VARCHAR(255),
  model_name VARCHAR(255),
  protocol_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT m.model_id, m.model_family, m.model_name, m.protocol_id
      FROM entities."DeviceModels" AS m
     WHERE m.model_id = in_model_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all device models
CREATE OR REPLACE FUNCTION apiGetDeviceModels ( --{{{
)
RETURNS TABLE (
  model_id INTEGER,
  model_family VARCHAR(255),
  model_name VARCHAR(255),
  protocol_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT m.model_id, m.model_family, m.model_name, m.protocol_id
      FROM entities."DeviceModels" AS m
  ORDER BY m.model_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on device protocol
CREATE OR REPLACE FUNCTION apiGetDeviceProtocol ( --{{{
  in_protocol_id INTEGER
)
RETURNS TABLE (
  protocol_id INTEGER,
  protocol_name TEXT,
  protocol_code VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
     WHERE p.protocol_id = in_protocol_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all device protocols
CREATE OR REPLACE FUNCTION apiGetDeviceProtocols ( --{{{
)
RETURNS TABLE (
  protocol_id INTEGER,
  protocol_name TEXT,
  protocol_code VARCHAR(255)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
  ORDER BY p.protocol_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on user type
CREATE OR REPLACE FUNCTION apiGetUserType ( --{{{
  in_user_type_id INTEGER
)
RETURNS TABLE (
  user_type_id INTEGER,
  user_type_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_type_id, u.user_type_name
      FROM entities."UserTypes" AS u
     WHERE u.user_type_id = in_user_type_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all user types
CREATE OR REPLACE FUNCTION apiGetUserTypes ( --{{{
)
RETURNS TABLE (
  user_type_id INTEGER,
  user_type_name VARCHAR(32)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_type_id, u.user_type_name
      FROM entities."UserTypes" AS u
  ORDER BY u.user_type_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on user project
CREATE OR REPLACE FUNCTION apiGetUserProject ( --{{{
  in_user_id INTEGER,
  in_project_id INTEGER
)
RETURNS TABLE (
  user_id INTEGER,
  project_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.project_id
      FROM "UserProjects" AS u
     WHERE u.user_id = in_user_id
       AND u.project_id = in_project_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all projects for user
CREATE OR REPLACE FUNCTION apiGetUserProjects ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  user_id INTEGER,
  project_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.project_id
      FROM "UserProjects" AS u
     WHERE u.user_id = in_user_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all fishery offices for user
CREATE OR REPLACE FUNCTION apiGetUserFisheryOffices ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  user_id INTEGER,
  fo_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.fo_id
      FROM "UserFisheryOffices" AS u
     WHERE u.user_id = in_user_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on vessel project
CREATE OR REPLACE FUNCTION apiGetVesselProject ( --{{{
  in_vessel_id INTEGER,
  in_project_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  project_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.project_id
      FROM "VesselProjects" AS v
     WHERE v.vessel_id = in_vessel_id
       AND v.project_id = in_project_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all projects for vessel
CREATE OR REPLACE FUNCTION apiGetVesselProjects ( --{{{
  in_vessel_id INTEGER
)
RETURNS TABLE (
  vessel_id INTEGER,
  project_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.project_id
      FROM "VesselProjects" AS v
     WHERE v.vessel_id = in_vessel_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on vessel owner
CREATE OR REPLACE FUNCTION apiGetVesselOwner ( --{{{
  in_owner_id INTEGER
)
RETURNS TABLE (
  owner_id INTEGER,
  owner_name TEXT,
  owner_address TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.owner_id, v.owner_name, v.owner_address
      FROM "VesselOwners" AS v
     WHERE v.owner_id = in_owner_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get details on all vessel owners
CREATE OR REPLACE FUNCTION apiGetVesselOwners ( --{{{
)
RETURNS TABLE (
  owner_id INTEGER,
  owner_name TEXT,
  owner_address TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.owner_id, v.owner_name, v.owner_address
      FROM "VesselOwners" AS v
  ORDER BY v.owner_name ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessels associated with user
CREATE OR REPLACE FUNCTION apiGetUserVessels ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  user_id INTEGER,
  vessel_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT v.user_id, v.vessel_id
      FROM "UserVessels" AS v
     WHERE v.user_id = in_user_id
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- update user details (with password)
CREATE OR REPLACE FUNCTION apiUpdateUser ( --{{{
  in_user_id INTEGER,
  in_user_name TEXT,
  in_user_email VARCHAR(255),
  in_user_password TEXT,
  in_user_type_id INTEGER,
  in_user_active SMALLINT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE "Users"
     SET user_name = in_user_name,
         user_email = in_user_email,
         user_password = CRYPT(in_user_password, GEN_SALT('bf')),
         user_type_id = in_user_type_id,
         user_active = in_user_active
   WHERE user_id = in_user_id;
   
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update user details (without password)
CREATE OR REPLACE FUNCTION apiUpdateUser ( --{{{
  in_user_id INTEGER,
  in_user_name TEXT,
  in_user_email VARCHAR(255),
  in_user_type_id INTEGER,
  in_user_active SMALLINT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE "Users"
     SET user_name = in_user_name,
         user_email = in_user_email,
         user_type_id = in_user_type_id,
         user_active = in_user_active
   WHERE user_id = in_user_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update user projects
CREATE OR REPLACE FUNCTION apiUpdateUserProjects ( --{{{
  in_user_id INTEGER,
  in_user_projects INTEGER[]
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  -- clear out any previous user/projects
  DELETE 
    FROM "UserProjects"
   WHERE user_id = in_user_id;
  
  -- create new user/project pairs
  INSERT INTO "UserProjects" (user_id, project_id)
  SELECT in_user_id, UNNEST(in_user_projects);
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update user vessels
CREATE OR REPLACE FUNCTION apiUpdateUserVessels ( --{{{
  in_user_id INTEGER,
  in_user_vessels INTEGER[]
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  -- clear out any previous user/vessels
  DELETE 
    FROM "UserVessels"
   WHERE user_id = in_user_id;
  
  -- create new user/vessel pairs
  INSERT INTO "UserVessels" (user_id, vessel_id)
  SELECT in_user_id, UNNEST(in_user_vessels);
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update user fishery offices
CREATE OR REPLACE FUNCTION apiUpdateUserFisheryOffices ( --{{{
  in_user_id INTEGER,
  in_user_fos INTEGER[]
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  -- clear out any previous user/fos
  DELETE 
    FROM "UserFisheryOffices"
   WHERE user_id = in_user_id;
  
  -- create new user/vessel pairs
  INSERT INTO "UserFisheryOffices" (user_id, fo_id)
  SELECT in_user_id, UNNEST(in_user_fos);
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update vessel
CREATE OR REPLACE FUNCTION apiUpdateVessel ( --{{{
  in_vessel_id INTEGER,
  in_vessel_name TEXT,
  in_vessel_code VARCHAR(32),
  in_vessel_pln VARCHAR(16),
  in_owner_id INTEGER,
  in_fo_id INTEGER,
  in_vessel_active SMALLINT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE "Vessels"
     SET vessel_name = in_vessel_name,
         vessel_code = in_vessel_code,
         vessel_pln = in_vessel_pln,
         owner_id = in_owner_id,
         fo_id = in_fo_id,
         vessel_active = in_vessel_active
   WHERE vessel_id = in_vessel_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update vessel projects
CREATE OR REPLACE FUNCTION apiUpdateVesselProjects ( --{{{
  in_vessel_id INTEGER,
  in_vessel_projects INTEGER[]
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  -- clear out any previous vessel/projects
  DELETE 
    FROM "VesselProjects"
   WHERE vessel_id = in_vessel_id;
  
  -- create new vessel/project pairs
  INSERT INTO "VesselProjects" (vessel_id, project_id)
  SELECT in_vessel_id, UNNEST(in_vessel_projects);
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update device
CREATE OR REPLACE FUNCTION apiUpdateDevice ( --{{{
  in_device_id INTEGER,
  in_vessel_id INTEGER,
  in_device_name TEXT,
  in_device_string TEXT,
  in_serial_number VARCHAR(255),
  in_model_id INTEGER,
  in_telephone VARCHAR(255),
  in_device_power_id INTEGER,
  in_device_active SMALLINT,
  in_engineer_notes TEXT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE "Devices"
     SET vessel_id = in_vessel_id,
         device_name = in_device_name,
         device_string = in_device_string,
         serial_number = in_serial_number,
         model_id = in_model_id,
         telephone = in_telephone,
         device_power_id = in_device_power_id,
         device_active = in_device_active,
         engineer_notes = in_engineer_notes
   WHERE device_id = in_device_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update vessel owner
CREATE OR REPLACE FUNCTION apiUpdateVesselOwner ( --{{{
  in_owner_id INTEGER,
  in_owner_name TEXT,
  in_owner_address TEXT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE "VesselOwners"
     SET owner_name = in_owner_name,
         owner_address = in_owner_address
   WHERE owner_id = in_owner_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update device protocol
CREATE OR REPLACE FUNCTION apiUpdateProtocol ( --{{{
  in_protocol_id INTEGER,
  in_protocol_name TEXT,
  in_protocol_code VARCHAR(255)
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE entities."Protocols"
     SET protocol_name = in_protocol_name,
         protocol_code = in_protocol_code
   WHERE protocol_id = in_protocol_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update device model
CREATE OR REPLACE FUNCTION apiUpdateDeviceModel ( --{{{
  in_model_id INTEGER,
  in_model_family VARCHAR(255),
  in_model_name VARCHAR(255),
  in_protocol_id INTEGER
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE entities."DeviceModels"
     SET model_family = in_model_family,
         model_name = in_model_name,
         protocol_id = in_protocol_id
   WHERE model_id = in_model_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update project
CREATE OR REPLACE FUNCTION apiUpdateProject ( --{{{
  in_project_id INTEGER,
  in_project_code VARCHAR(255),
  in_project_name TEXT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE entities."Projects"
     SET project_code = in_project_code,
         project_name = in_project_name
   WHERE project_id = in_project_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- update fishery office
CREATE OR REPLACE FUNCTION apiUpdateFisheryOffice ( --{{{
  in_fo_id INTEGER,
  in_fo_town TEXT,
  in_fo_address TEXT,
  in_fo_email TEXT
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
BEGIN
  UPDATE entities."FisheryOffices"
     SET fo_town = in_fo_town,
         fo_address = in_fo_address,
         fo_email = in_fo_email
   WHERE fo_id = in_fo_id;
  
  -- get number of updated rows
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add new user
CREATE OR REPLACE FUNCTION apiAddUser ( --{{{
  in_user_name TEXT,
  in_user_email VARCHAR(255),
  in_user_password TEXT,
  in_user_type_id INTEGER,
  in_user_active SMALLINT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO "Users" (user_name, user_email, user_password, user_type_id, user_active)
         VALUES (in_user_name, in_user_email, CRYPT(in_user_password, GEN_SALT('bf')), in_user_type_id, in_user_active)
      RETURNING user_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add new vesse;
CREATE OR REPLACE FUNCTION apiAddVessel ( --{{{
  in_vessel_name TEXT,
  in_vessel_code VARCHAR(32),
  in_vessel_pln VARCHAR(16),
  in_owner_id INTEGER,
  in_fo_id INTEGER,
  in_vessel_active SMALLINT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO "Vessels" (vessel_name, vessel_code, vessel_pln, owner_id, fo_id, vessel_active)
         VALUES (in_vessel_name, in_vessel_code, in_vessel_pln, in_owner_id, in_fo_id, in_vessel_active)
      RETURNING vessel_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add device
CREATE OR REPLACE FUNCTION apiAddDevice ( --{{{
  in_vessel_id INTEGER,
  in_device_name TEXT,
  in_device_string TEXT,
  in_serial_number VARCHAR(255),
  in_model_id INTEGER,
  in_telephone VARCHAR(255),
  in_device_power_id INTEGER,
  in_device_active SMALLINT,
  in_engineer_notes TEXT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO "Devices" (vessel_id, device_name, device_string, serial_number, model_id, telephone, device_power_id, device_active, engineer_notes)
         VALUES (in_vessel_id, in_device_name, in_device_string, in_serial_number, in_model_id, in_telephone, in_device_power_id, in_device_active, in_engineer_notes)
      RETURNING device_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add vessel owner
CREATE OR REPLACE FUNCTION apiAddVesselOwner ( --{{{
  in_owner_name TEXT,
  in_owner_address TEXT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO "VesselOwners" (owner_name, owner_address)
         VALUES (in_owner_name, in_owner_address)
      RETURNING owner_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add device protocol
CREATE OR REPLACE FUNCTION apiAddProtocol ( --{{{
  in_protocol_name TEXT,
  in_protocol_code VARCHAR(255)
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO entities."Protocols" (protocol_name, protocol_code)
         VALUES (in_protocol_name, in_protocol_code)
      RETURNING protocol_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add device model
CREATE OR REPLACE FUNCTION apiAddDeviceModel ( --{{{
  model_family VARCHAR(255),
  model_name VARCHAR(255),
  protocol_id INTEGER
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO entities."DeviceModels" (model_family, model_name, protocol_id)
         VALUES (model_family, model_name, protocol_id)
      RETURNING model_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add project
CREATE OR REPLACE FUNCTION apiAddProject ( --{{{
  in_project_code VARCHAR(255),
  in_project_name TEXT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO entities."Projects" (project_code, project_name)
         VALUES (in_project_code, in_project_name)
      RETURNING project_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add fishery office
CREATE OR REPLACE FUNCTION apiAddFisheryOffice ( --{{{
  in_fo_town TEXT,
  in_fo_address TEXT,
  in_fo_email TEXT
)
RETURNS TABLE (
  inserted INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT INTO entities."FisheryOffices" (fo_town, fo_address, fo_email)
         VALUES (in_fo_town, in_fo_address, in_fo_email)
      RETURNING fo_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete user
CREATE OR REPLACE FUNCTION apiDeleteUser ( --{{{
  in_user_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM "Users"
   WHERE user_id = in_user_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete vessel
CREATE OR REPLACE FUNCTION apiDeleteVessel ( --{{{
  in_vessel_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM "Vessels"
   WHERE vessel_id = in_vessel_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete device
CREATE OR REPLACE FUNCTION apiDeleteDevice ( --{{{
  in_device_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM "Devices"
   WHERE device_id = in_device_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete vessel owner
CREATE OR REPLACE FUNCTION apiDeleteVesselOwner ( --{{{
  in_owner_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM "VesselOwners"
   WHERE owner_id = in_owner_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete device protocol
CREATE OR REPLACE FUNCTION apiDeleteProtocol ( --{{{
  in_protocol_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM entities."Protocols"
   WHERE protocol_id = in_protocol_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete device model
CREATE OR REPLACE FUNCTION apiDeleteDeviceIModel ( --{{{
  in_model_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM entities."DeviceModels"
   WHERE model_id = in_model_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete project
CREATE OR REPLACE FUNCTION apiDeleteProject ( --{{{
  in_project_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM entities."Projects"
   WHERE project_id = in_project_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete fishery office
CREATE OR REPLACE FUNCTION apiDeleteFisheryOffice ( --{{{
  in_fo_id INTEGER
)
RETURNS TABLE (
  deleted INTEGER
)
AS $FUNC$
BEGIN
  DELETE
    FROM entities."FisheryOffices"
   WHERE fo_id = in_fo_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

