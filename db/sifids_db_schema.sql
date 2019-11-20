--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5 (Debian 11.5-1+deb10u1)
-- Dumped by pg_dump version 12.1 (Debian 12.1-1.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: analysis; Type: SCHEMA; Schema: -; Owner: sifids_w
--

CREATE SCHEMA analysis;


ALTER SCHEMA analysis OWNER TO sifids_w;

--
-- Name: entities; Type: SCHEMA; Schema: -; Owner: sifids_w
--

CREATE SCHEMA entities;


ALTER SCHEMA entities OWNER TO sifids_w;

--
-- Name: fish1; Type: SCHEMA; Schema: -; Owner: sifids_w
--

CREATE SCHEMA fish1;


ALTER SCHEMA fish1 OWNER TO sifids_w;

--
-- Name: geography; Type: SCHEMA; Schema: -; Owner: sifids_w
--

CREATE SCHEMA geography;


ALTER SCHEMA geography OWNER TO sifids_w;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: addattribute(character varying, numeric, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.addattribute(in_attribute_name character varying, in_attribute_value numeric, in_time_stamp timestamp with time zone, in_device_id integer) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO "Attributes" (attribute_id, device_id, time_stamp, attribute_value)
       SELECT a.attribute_id, in_device_id, in_time_stamp, in_attribute_value
         FROM entities."AttributeTypes" AS a
        WHERE a.attribute_name = in_attribute_name;

  GET DIAGNOSTICS inserted = ROW_COUNT;
  
  RETURN QUERY
    SELECT inserted;
END;
$$;


ALTER FUNCTION public.addattribute(in_attribute_name character varying, in_attribute_value numeric, in_time_stamp timestamp with time zone, in_device_id integer) OWNER TO sifids_w;

--
-- Name: addtraccartrack(integer, numeric, numeric, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.addtraccartrack(in_trip_id integer, in_latitude numeric, in_longitude numeric, in_time_stamp timestamp with time zone) RETURNS TABLE(track_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  old_latitude NUMERIC(15,12);
  old_longitude NUMERIC(15,12);
BEGIN
  -- get most recent point from track
    SELECT t.latitude, t.longitude
      INTO old_latitude, old_longitude
      FROM "Tracks" AS t
     WHERE trip_id = in_trip_id
  ORDER BY time_stamp DESC
     LIMIT 1;
     
  -- see if device has moved since last point
    IF old_latitude = in_latitude AND old_longitude = in_longitude THEN
      RETURN QUERY
           SELECT 0; -- not moved, so send back 0
    ELSE
      RETURN QUERY
      INSERT INTO "Tracks" AS t (latitude, longitude, time_stamp, trip_id)
           VALUES (in_latitude, in_longitude, in_time_stamp, in_trip_id)
        RETURNING t.track_id;
    END IF;
END;
$$;


ALTER FUNCTION public.addtraccartrack(in_trip_id integer, in_latitude numeric, in_longitude numeric, in_time_stamp timestamp with time zone) OWNER TO sifids_w;

--
-- Name: addtraccartrack(integer, numeric, numeric, timestamp with time zone, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.addtraccartrack(in_trip_id integer, in_latitude numeric, in_longitude numeric, in_time_stamp timestamp with time zone, in_is_valid smallint) RETURNS TABLE(track_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  old_latitude NUMERIC(15,12);
  old_longitude NUMERIC(15,12);
BEGIN
  -- get most recent point from track
    SELECT t.latitude, t.longitude
      INTO old_latitude, old_longitude
      FROM "Tracks" AS t
     WHERE trip_id = in_trip_id
  ORDER BY time_stamp DESC
     LIMIT 1;
     
  -- see if device has moved since last point
    IF old_latitude = in_latitude AND old_longitude = in_longitude THEN
      RETURN QUERY
           SELECT 0; -- not moved, so send back 0
    ELSE
      RETURN QUERY
      INSERT INTO "Tracks" AS t (latitude, longitude, time_stamp, trip_id, is_valid)
           VALUES (in_latitude, in_longitude, in_time_stamp, in_trip_id, in_is_valid)
        RETURNING t.track_id;
    END IF;
END;
$$;


ALTER FUNCTION public.addtraccartrack(in_trip_id integer, in_latitude numeric, in_longitude numeric, in_time_stamp timestamp with time zone, in_is_valid smallint) OWNER TO sifids_w;

--
-- Name: apiadddevice(integer, text, text, character varying, integer, character varying, integer, smallint, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiadddevice(in_vessel_id integer, in_device_name text, in_device_string text, in_serial_number character varying, in_model_id integer, in_telephone character varying, in_device_power_id integer, in_device_active smallint, in_engineer_notes text) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO "Devices" (vessel_id, device_name, device_string, serial_number, model_id, telephone, device_power_id, device_active, engineer_notes)
         VALUES (in_vessel_id, in_device_name, in_device_string, in_serial_number, in_model_id, in_telephone, in_device_power_id, in_device_active, in_engineer_notes)
      RETURNING device_id;
END;
$$;


ALTER FUNCTION public.apiadddevice(in_vessel_id integer, in_device_name text, in_device_string text, in_serial_number character varying, in_model_id integer, in_telephone character varying, in_device_power_id integer, in_device_active smallint, in_engineer_notes text) OWNER TO sifids_w;

--
-- Name: apiadddevicemodel(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiadddevicemodel(model_family character varying, model_name character varying, protocol_id integer) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO entities."DeviceModels" (model_family, model_name, protocol_id)
         VALUES (model_family, model_name, protocol_id)
      RETURNING model_id;
END;
$$;


ALTER FUNCTION public.apiadddevicemodel(model_family character varying, model_name character varying, protocol_id integer) OWNER TO sifids_w;

--
-- Name: apiaddfisheryoffice(text, text, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiaddfisheryoffice(in_fo_town text, in_fo_address text, in_fo_email text) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO entities."FisheryOffices" (fo_town, fo_address, fo_email)
         VALUES (in_fo_town, in_fo_address, in_fo_email)
      RETURNING fo_id;
END;
$$;


ALTER FUNCTION public.apiaddfisheryoffice(in_fo_town text, in_fo_address text, in_fo_email text) OWNER TO sifids_w;

--
-- Name: apiaddproject(character varying, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiaddproject(in_project_code character varying, in_project_name text) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO entities."Projects" (project_code, project_name)
         VALUES (in_project_code, in_project_name)
      RETURNING project_id;
END;
$$;


ALTER FUNCTION public.apiaddproject(in_project_code character varying, in_project_name text) OWNER TO sifids_w;

--
-- Name: apiaddprotocol(text, character varying); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiaddprotocol(in_protocol_name text, in_protocol_code character varying) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO entities."Protocols" (protocol_name, protocol_code)
         VALUES (in_protocol_name, in_protocol_code)
      RETURNING protocol_id;
END;
$$;


ALTER FUNCTION public.apiaddprotocol(in_protocol_name text, in_protocol_code character varying) OWNER TO sifids_w;

--
-- Name: apiadduser(text, character varying, text, integer, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiadduser(in_user_name text, in_user_email character varying, in_user_password text, in_user_type_id integer, in_user_active smallint) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO "Users" (user_name, user_email, user_password, user_type_id, user_active)
         VALUES (in_user_name, in_user_email, CRYPT(in_user_password, GEN_SALT('bf')), in_user_type_id, in_user_active)
      RETURNING user_id;
END;
$$;


ALTER FUNCTION public.apiadduser(in_user_name text, in_user_email character varying, in_user_password text, in_user_type_id integer, in_user_active smallint) OWNER TO sifids_w;

--
-- Name: apiaddvessel(text, character varying, character varying, integer, integer, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiaddvessel(in_vessel_name text, in_vessel_code character varying, in_vessel_pln character varying, in_owner_id integer, in_fo_id integer, in_vessel_active smallint) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO "Vessels" (vessel_name, vessel_code, vessel_pln, owner_id, fo_id, vessel_active)
         VALUES (in_vessel_name, in_vessel_code, in_vessel_pln, in_owner_id, in_fo_id, in_vessel_active)
      RETURNING vessel_id;
END;
$$;


ALTER FUNCTION public.apiaddvessel(in_vessel_name text, in_vessel_code character varying, in_vessel_pln character varying, in_owner_id integer, in_fo_id integer, in_vessel_active smallint) OWNER TO sifids_w;

--
-- Name: apiaddvesselowner(text, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiaddvesselowner(in_owner_name text, in_owner_address text) RETURNS TABLE(inserted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    INSERT INTO "VesselOwners" (owner_name, owner_address)
         VALUES (in_owner_name, in_owner_address)
      RETURNING owner_id;
END;
$$;


ALTER FUNCTION public.apiaddvesselowner(in_owner_name text, in_owner_address text) OWNER TO sifids_w;

--
-- Name: apideletedevice(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideletedevice(in_device_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM "Devices"
   WHERE device_id = in_device_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideletedevice(in_device_id integer) OWNER TO sifids_w;

--
-- Name: apideletedeviceimodel(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideletedeviceimodel(in_model_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM entities."DeviceModels"
   WHERE model_id = in_model_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideletedeviceimodel(in_model_id integer) OWNER TO sifids_w;

--
-- Name: apideletefisheryoffice(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideletefisheryoffice(in_fo_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM entities."FisheryOffices"
   WHERE fo_id = in_fo_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideletefisheryoffice(in_fo_id integer) OWNER TO sifids_w;

--
-- Name: apideleteproject(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideleteproject(in_project_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM entities."Projects"
   WHERE project_id = in_project_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideleteproject(in_project_id integer) OWNER TO sifids_w;

--
-- Name: apideleteprotocol(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideleteprotocol(in_protocol_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM entities."Protocols"
   WHERE protocol_id = in_protocol_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideleteprotocol(in_protocol_id integer) OWNER TO sifids_w;

--
-- Name: apideleteuser(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideleteuser(in_user_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM "Users"
   WHERE user_id = in_user_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideleteuser(in_user_id integer) OWNER TO sifids_w;

--
-- Name: apideletevessel(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideletevessel(in_vessel_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM "Vessels"
   WHERE vessel_id = in_vessel_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideletevessel(in_vessel_id integer) OWNER TO sifids_w;

--
-- Name: apideletevesselowner(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apideletevesselowner(in_owner_id integer) RETURNS TABLE(deleted integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE
    FROM "VesselOwners"
   WHERE owner_id = in_owner_id;
   
  -- get number of deleted rows
  GET DIAGNOSTICS deleted = ROW_COUNT;
  
  RETURN QUERY
    SELECT deleted;
END;
$$;


ALTER FUNCTION public.apideletevesselowner(in_owner_id integer) OWNER TO sifids_w;

--
-- Name: apigetdevice(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevice(in_device_id integer) RETURNS TABLE(device_id integer, vessel_id integer, device_name text, device_string text, serial_number character varying, model_id integer, telephone character varying, device_power_id integer, device_active smallint, engineer_notes text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apigetdevice(in_device_id integer) OWNER TO sifids_w;

--
-- Name: apigetdevicemodel(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevicemodel(in_model_id integer) RETURNS TABLE(model_id integer, model_family character varying, model_name character varying, protocol_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT m.model_id, m.model_family, m.model_name, m.protocol_id
      FROM entities."DeviceModels" AS m
     WHERE m.model_id = in_model_id
;
END;
$$;


ALTER FUNCTION public.apigetdevicemodel(in_model_id integer) OWNER TO sifids_w;

--
-- Name: apigetdevicemodels(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevicemodels() RETURNS TABLE(model_id integer, model_family character varying, model_name character varying, protocol_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT m.model_id, m.model_family, m.model_name, m.protocol_id
      FROM entities."DeviceModels" AS m
  ORDER BY m.model_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetdevicemodels() OWNER TO sifids_w;

--
-- Name: apigetdevicepower(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevicepower(in_device_power_id integer) RETURNS TABLE(device_power_id integer, device_power_name character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT d.devce_power_id, d.device_power_name
      FROM entities."DevicePower" AS d
     WHERE d.devce_power_id = in_device_power_id
;
END;
$$;


ALTER FUNCTION public.apigetdevicepower(in_device_power_id integer) OWNER TO sifids_w;

--
-- Name: apigetdevicepowers(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevicepowers() RETURNS TABLE(device_power_id integer, device_power_name character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT d.devce_power_id, d.device_power_name
      FROM entities."DevicePower" AS d
  ORDER BY d.device_power_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetdevicepowers() OWNER TO sifids_w;

--
-- Name: apigetdeviceprotocol(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdeviceprotocol(in_protocol_id integer) RETURNS TABLE(protocol_id integer, protocol_name text, protocol_code character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
     WHERE p.protocol_id = in_protocol_id
;
END;
$$;


ALTER FUNCTION public.apigetdeviceprotocol(in_protocol_id integer) OWNER TO sifids_w;

--
-- Name: apigetdeviceprotocols(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdeviceprotocols() RETURNS TABLE(protocol_id integer, protocol_name text, protocol_code character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
  ORDER BY p.protocol_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetdeviceprotocols() OWNER TO sifids_w;

--
-- Name: apigetdevices(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetdevices() RETURNS TABLE(device_id integer, vessel_id integer, device_name text, device_string text, serial_number character varying, model_id integer, telephone character varying, device_power_id integer, device_active smallint, engineer_notes text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apigetdevices() OWNER TO sifids_w;

--
-- Name: apigetfisheryoffice(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetfisheryoffice(in_fo_id integer) RETURNS TABLE(fo_id integer, fo_town text, fo_address text, fo_email text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town, f.fo_address, f.fo_email
      FROM entities."FisheryOffices" AS f
     WHERE f.fo_id = in_fo_id
;
END;
$$;


ALTER FUNCTION public.apigetfisheryoffice(in_fo_id integer) OWNER TO sifids_w;

--
-- Name: apigetfisheryoffices(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetfisheryoffices() RETURNS TABLE(fo_id integer, fo_town text, fo_address text, fo_email text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town, f.fo_address, f.fo_email
      FROM entities."FisheryOffices" AS f
  ORDER BY f.fo_town ASC
;
END;
$$;


ALTER FUNCTION public.apigetfisheryoffices() OWNER TO sifids_w;

--
-- Name: apigetproject(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetproject(in_project_id integer) RETURNS TABLE(project_id integer, project_code character varying, project_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.project_id, p.project_code, p.project_name
      FROM entities."Projects" AS p
     WHERE p.project_id = in_project_id
;
END;
$$;


ALTER FUNCTION public.apigetproject(in_project_id integer) OWNER TO sifids_w;

--
-- Name: apigetprojects(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetprojects() RETURNS TABLE(project_id integer, project_code character varying, project_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.project_id, p.project_code, p.project_name
      FROM entities."Projects" AS p
  ORDER BY p.project_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetprojects() OWNER TO sifids_w;

--
-- Name: apigetprotocol(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetprotocol(in_protocol_id integer) RETURNS TABLE(protocol_id integer, protocol_name text, protocol_code character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
     WHERE p.protocol_id = in_protocol_id
;
END;
$$;


ALTER FUNCTION public.apigetprotocol(in_protocol_id integer) OWNER TO sifids_w;

--
-- Name: apigetprotocols(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetprotocols() RETURNS TABLE(protocol_id integer, protocol_name text, protocol_code character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.protocol_id, p.protocol_name, p.protocol_code
      FROM entities."Protocols" AS p
  ORDER BY p.protocol_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetprotocols() OWNER TO sifids_w;

--
-- Name: apigetuser(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetuser(in_user_id integer) RETURNS TABLE(user_id integer, user_name text, user_email character varying, user_type_id integer, user_active smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_name, u.user_email, u.user_type_id, u.user_active
      FROM "Users" AS u
     WHERE u.user_id = in_user_id
;
END;
$$;


ALTER FUNCTION public.apigetuser(in_user_id integer) OWNER TO sifids_w;

--
-- Name: apigetuserfisheryoffices(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetuserfisheryoffices(in_user_id integer) RETURNS TABLE(user_id integer, fo_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.fo_id
      FROM "UserFisheryOffices" AS u
     WHERE u.user_id = in_user_id
;
END;
$$;


ALTER FUNCTION public.apigetuserfisheryoffices(in_user_id integer) OWNER TO sifids_w;

--
-- Name: apigetuserproject(integer, integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetuserproject(in_user_id integer, in_project_id integer) RETURNS TABLE(user_id integer, project_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.project_id
      FROM "UserProjects" AS u
     WHERE u.user_id = in_user_id
       AND u.project_id = in_project_id
;
END;
$$;


ALTER FUNCTION public.apigetuserproject(in_user_id integer, in_project_id integer) OWNER TO sifids_w;

--
-- Name: apigetuserprojects(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetuserprojects(in_user_id integer) RETURNS TABLE(user_id integer, project_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.project_id
      FROM "UserProjects" AS u
     WHERE u.user_id = in_user_id
;
END;
$$;


ALTER FUNCTION public.apigetuserprojects(in_user_id integer) OWNER TO sifids_w;

--
-- Name: apigetusers(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetusers() RETURNS TABLE(user_id integer, user_name text, user_email character varying, user_type_id integer, user_active smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_id, u.user_name, u.user_email, u.user_type_id, u.user_active
      FROM "Users" AS u
  ORDER BY u.user_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetusers() OWNER TO sifids_w;

--
-- Name: apigetusertype(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetusertype(in_user_type_id integer) RETURNS TABLE(user_type_id integer, user_type_name character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_type_id, u.user_type_name
      FROM entities."UserTypes" AS u
     WHERE u.user_type_id = in_user_type_id
;
END;
$$;


ALTER FUNCTION public.apigetusertype(in_user_type_id integer) OWNER TO sifids_w;

--
-- Name: apigetusertypes(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetusertypes() RETURNS TABLE(user_type_id integer, user_type_name character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT u.user_type_id, u.user_type_name
      FROM entities."UserTypes" AS u
  ORDER BY u.user_type_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetusertypes() OWNER TO sifids_w;

--
-- Name: apigetuservessels(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetuservessels(in_user_id integer) RETURNS TABLE(user_id integer, vessel_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.user_id, v.vessel_id
      FROM "UserVessels" AS v
     WHERE v.user_id = in_user_id
;
END;
$$;


ALTER FUNCTION public.apigetuservessels(in_user_id integer) OWNER TO sifids_w;

--
-- Name: apigetvessel(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvessel(in_vessel_id integer) RETURNS TABLE(vessel_id integer, vessel_name text, vessel_code character varying, vessel_pln character varying, owner_id integer, fo_id integer, vessel_active smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_name, v.vessel_code, v.vessel_pln, v.owner_id, v.fo_id, v.vessel_active
      FROM "Vessels" AS v
     WHERE v.vessel_id = in_vessel_id
;
END;
$$;


ALTER FUNCTION public.apigetvessel(in_vessel_id integer) OWNER TO sifids_w;

--
-- Name: apigetvesselowner(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvesselowner(in_owner_id integer) RETURNS TABLE(owner_id integer, owner_name text, owner_address text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.owner_id, v.owner_name, v.owner_address
      FROM "VesselOwners" AS v
     WHERE v.owner_id = in_owner_id
;
END;
$$;


ALTER FUNCTION public.apigetvesselowner(in_owner_id integer) OWNER TO sifids_w;

--
-- Name: apigetvesselowners(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvesselowners() RETURNS TABLE(owner_id integer, owner_name text, owner_address text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.owner_id, v.owner_name, v.owner_address
      FROM "VesselOwners" AS v
  ORDER BY v.owner_name ASC
;
END;
$$;


ALTER FUNCTION public.apigetvesselowners() OWNER TO sifids_w;

--
-- Name: apigetvesselproject(integer, integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvesselproject(in_vessel_id integer, in_project_id integer) RETURNS TABLE(vessel_id integer, project_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.project_id
      FROM "VesselProjects" AS v
     WHERE v.vessel_id = in_vessel_id
       AND v.project_id = in_project_id
;
END;
$$;


ALTER FUNCTION public.apigetvesselproject(in_vessel_id integer, in_project_id integer) OWNER TO sifids_w;

--
-- Name: apigetvesselprojects(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvesselprojects(in_vessel_id integer) RETURNS TABLE(vessel_id integer, project_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.project_id
      FROM "VesselProjects" AS v
     WHERE v.vessel_id = in_vessel_id
;
END;
$$;


ALTER FUNCTION public.apigetvesselprojects(in_vessel_id integer) OWNER TO sifids_w;

--
-- Name: apigetvessels(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apigetvessels() RETURNS TABLE(vessel_id integer, vessel_name text, vessel_code character varying, vessel_pln character varying, owner_id integer, fo_id integer, vessel_active smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_pln || ' (' || v.vessel_name || ')' AS vessel_name, v.vessel_code, v.vessel_pln, v.owner_id, v.fo_id, v.vessel_active
      FROM "Vessels" AS v
  ORDER BY v.vessel_pln ASC
;
END;
$$;


ALTER FUNCTION public.apigetvessels() OWNER TO sifids_w;

--
-- Name: apiupdatedevice(integer, integer, text, text, character varying, integer, character varying, integer, smallint, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatedevice(in_device_id integer, in_vessel_id integer, in_device_name text, in_device_string text, in_serial_number character varying, in_model_id integer, in_telephone character varying, in_device_power_id integer, in_device_active smallint, in_engineer_notes text) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatedevice(in_device_id integer, in_vessel_id integer, in_device_name text, in_device_string text, in_serial_number character varying, in_model_id integer, in_telephone character varying, in_device_power_id integer, in_device_active smallint, in_engineer_notes text) OWNER TO sifids_w;

--
-- Name: apiupdatedevicemodel(integer, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatedevicemodel(in_model_id integer, in_model_family character varying, in_model_name character varying, in_protocol_id integer) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatedevicemodel(in_model_id integer, in_model_family character varying, in_model_name character varying, in_protocol_id integer) OWNER TO sifids_w;

--
-- Name: apiupdatefisheryoffice(integer, text, text, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatefisheryoffice(in_fo_id integer, in_fo_town text, in_fo_address text, in_fo_email text) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatefisheryoffice(in_fo_id integer, in_fo_town text, in_fo_address text, in_fo_email text) OWNER TO sifids_w;

--
-- Name: apiupdateproject(integer, character varying, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateproject(in_project_id integer, in_project_code character varying, in_project_name text) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateproject(in_project_id integer, in_project_code character varying, in_project_name text) OWNER TO sifids_w;

--
-- Name: apiupdateprotocol(integer, text, character varying); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateprotocol(in_protocol_id integer, in_protocol_name text, in_protocol_code character varying) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateprotocol(in_protocol_id integer, in_protocol_name text, in_protocol_code character varying) OWNER TO sifids_w;

--
-- Name: apiupdateuser(integer, text, character varying, integer, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateuser(in_user_id integer, in_user_name text, in_user_email character varying, in_user_type_id integer, in_user_active smallint) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateuser(in_user_id integer, in_user_name text, in_user_email character varying, in_user_type_id integer, in_user_active smallint) OWNER TO sifids_w;

--
-- Name: apiupdateuser(integer, text, character varying, text, integer, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateuser(in_user_id integer, in_user_name text, in_user_email character varying, in_user_password text, in_user_type_id integer, in_user_active smallint) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateuser(in_user_id integer, in_user_name text, in_user_email character varying, in_user_password text, in_user_type_id integer, in_user_active smallint) OWNER TO sifids_w;

--
-- Name: apiupdateuserfisheryoffices(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateuserfisheryoffices(in_user_id integer, in_user_fos integer[]) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateuserfisheryoffices(in_user_id integer, in_user_fos integer[]) OWNER TO sifids_w;

--
-- Name: apiupdateuserprojects(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateuserprojects(in_user_id integer, in_user_projects integer[]) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateuserprojects(in_user_id integer, in_user_projects integer[]) OWNER TO sifids_w;

--
-- Name: apiupdateuservessels(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdateuservessels(in_user_id integer, in_user_vessels integer[]) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdateuservessels(in_user_id integer, in_user_vessels integer[]) OWNER TO sifids_w;

--
-- Name: apiupdatevessel(integer, text, character varying, character varying, integer, integer, smallint); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatevessel(in_vessel_id integer, in_vessel_name text, in_vessel_code character varying, in_vessel_pln character varying, in_owner_id integer, in_fo_id integer, in_vessel_active smallint) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatevessel(in_vessel_id integer, in_vessel_name text, in_vessel_code character varying, in_vessel_pln character varying, in_owner_id integer, in_fo_id integer, in_vessel_active smallint) OWNER TO sifids_w;

--
-- Name: apiupdatevesselowner(integer, text, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatevesselowner(in_owner_id integer, in_owner_name text, in_owner_address text) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatevesselowner(in_owner_id integer, in_owner_name text, in_owner_address text) OWNER TO sifids_w;

--
-- Name: apiupdatevesselprojects(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.apiupdatevesselprojects(in_vessel_id integer, in_vessel_projects integer[]) RETURNS TABLE(updated integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.apiupdatevesselprojects(in_vessel_id integer, in_vessel_projects integer[]) OWNER TO sifids_w;

--
-- Name: applogin(text, text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.applogin(in_username text, in_password text) RETURNS TABLE(user_id integer, user_role character varying, vessel_ids integer, vessel_names text, vessel_codes character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
     SELECT u.user_id, ut.user_type_name, 
            v.vessel_id, v.vessel_name || ' (' || v.vessel_pln || ')', v.vessel_code
       FROM "Users" AS u
 INNER JOIN entities."UserTypes" AS ut USING (user_type_id),
            "Vessels" AS v
      WHERE u.user_name = in_username
        AND u.user_password = CRYPT(in_password, u.user_password)
        -- fisher, so join to just their vessel/s
        AND (
             (ut.user_type_name = 'fisher' 
          AND v.vessel_id IN (SELECT vessel_id 
                               FROM "Vessels" 
                         INNER JOIN "UserVessels" AS uv USING (vessel_id) 
                              WHERE uv.user_id = u.user_id)
             )
        -- admin/researcher, so get all vessels
          OR (ut.user_type_name IN ('admin', 'researcher')))
;
END;
$$;


ALTER FUNCTION public.applogin(in_username text, in_password text) OWNER TO sifids_w;

--
-- Name: attributeplotdata(integer, integer[], date, date, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.attributeplotdata(in_user_id integer, in_vessels integer[], in_start_date date, in_end_date date, in_attributes integer[]) RETURNS TABLE(vessel_pln character varying, attribute_name character varying, attribute_value numeric, time_stamp timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  max_rows INTEGER := 500;
  factor INTEGER := 1;
  rec RECORD;
BEGIN
  -- put all data into temp table
  CREATE TEMPORARY TABLE attrib_plot_data AS
    SELECT ROW_NUMBER() OVER (ORDER BY v.vessel_id, a1.attribute_id, a2.time_stamp) AS row_num, 
           v.vessel_id, v.vessel_pln, 
           a1.attribute_id, a1.attribute_name, 
           CASE 
             WHEN a1.attribute_name = 'distance' OR a1.attribute_name = 'totalDistance' THEN
               (a2.attribute_value / 1000)::INTEGER -- convert to km
             ELSE
               a2.attribute_value
           END,
           a2.time_stamp
      FROM "Attributes" AS a2
INNER JOIN entities."AttributeTypes" AS a1 USING (attribute_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
         , "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
       AND vessel_id = ANY(in_vessels)
       AND a2.time_stamp BETWEEN in_start_date AND in_end_date
       AND a2.attribute_id = ANY(in_attributes)
;

        FOR rec
  IN SELECT t.vessel_id, t.attribute_id, COUNT(*) AS rc
       FROM attrib_plot_data AS t
   GROUP BY t.vessel_id, t.attribute_id
       LOOP
         -- work out how many rows to thin out of total
         IF rec.rc > max_rows THEN
           SELECT (rec.rc / max_rows)::INTEGER INTO factor;
         ELSE
           SELECT 1 INTO factor;
         END IF;
         
         -- thin data in temp table for this vessel/attribute
         IF factor > 1 THEN
           DELETE
             FROM attrib_plot_data AS t
           WHERE MOD(t.row_num, factor) <> 0
             AND t.vessel_id = rec.vessel_id 
             AND t.attribute_id = rec.attribute_id;
         END IF;
   END LOOP;
  
  -- select remaining data from temp table
  RETURN QUERY
    SELECT t.vessel_pln, t.attribute_name, t.attribute_value, t.time_stamp
      FROM attrib_plot_data AS t
  ORDER BY t.time_stamp ASC;
  
  -- finished with temp table
  DROP TABLE attrib_plot_data;
END;
$$;


ALTER FUNCTION public.attributeplotdata(in_user_id integer, in_vessels integer[], in_start_date date, in_end_date date, in_attributes integer[]) OWNER TO sifids_w;

--
-- Name: attributevessels(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.attributevessels(in_user_id integer) RETURNS TABLE(vessel_id integer, vessel_pln character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, v.vessel_pln
      FROM "Attributes" AS a2
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
         , "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
  GROUP BY v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$$;


ALTER FUNCTION public.attributevessels(in_user_id integer) OWNER TO sifids_w;

--
-- Name: catchperspecies(integer, integer[], date, date, integer, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.catchperspecies(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(species text, weight numeric, anon integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      SELECT t.animal_name, AVG(t.weight), 1 AS anon
        FROM (
              SELECT device_id, animal_name, SUM(f.weight) AS weight
                FROM fish1."Rows" AS f
          INNER JOIN entities."Animals" USING (animal_id)
          INNER JOIN fish1."Headers" USING (header_id)
          INNER JOIN "Uploads" USING (upload_id)
          INNER JOIN "Devices" USING (device_id)
               WHERE (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
            GROUP BY device_id, animal_name) AS t
    GROUP BY animal_name
    ORDER BY animal_name;
  
  -- otherwise return fish1 data for user/all/some users
  ELSE
    RETURN QUERY
      SELECT animal_name, SUM(f.weight), 0 AS anon
        FROM fish1."Rows" AS f
  INNER JOIN entities."Animals" USING (animal_id)
  INNER JOIN fish1."Headers" USING (header_id)
  INNER JOIN "Uploads" USING (upload_id)
  INNER JOIN "Devices" USING (device_id)
  INNER JOIN "Vessels" USING (vessel_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher') 
           OR u1.user_id = in_user_id
             )
         AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
         AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
         AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
         AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing)
         AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo)
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
    GROUP BY animal_name
    ORDER BY animal_name;
  END IF;
END;
$$;


ALTER FUNCTION public.catchperspecies(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

--
-- Name: catchperspeciesweek(integer, integer[], date, date, integer, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.catchperspeciesweek(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(week text, species text, weight numeric, anon integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      WITH RECURSIVE weeks (start, finish, week) AS (
        SELECT s.start, s.finish, s.week
          FROM (SELECT MIN(fishing_date) AS start,
                       MAX(fishing_date) AS finish,
                       TO_CHAR(MIN(fishing_date), 'IYYY-IW') AS week
                  FROM fish1."Rows"
                 LIMIT 1) AS s
     UNION ALL 
        SELECT w.start + INTERVAL '1 WEEK' AS start, 
               w.finish, 
               TO_CHAR(w.start + INTERVAL '1 WEEK', 'IYYY-IW') AS week
          FROM weeks AS w
         WHERE start < finish
      )
      SELECT t.week, t.animal_name, AVG(t.weight), 1 AS anon
        FROM (
              SELECT r.device_id, ww.week, r.animal_name, SUM(r.weight) AS weight
                FROM weeks AS ww
           LEFT JOIN (SELECT device_id, TO_CHAR(fishing_date, 'IYYY-IW') AS week, animal_name, COALESCE(f.weight, 0) AS weight
                        FROM fish1."Rows" AS f
                  INNER JOIN entities."Animals" USING (animal_id)
                  INNER JOIN fish1."Headers" USING (header_id)
                  INNER JOIN "Uploads" USING (upload_id)
                  INNER JOIN "Devices" USING (device_id)
                       WHERE (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species))
                     ) AS r USING (week)
            GROUP BY r.device_id, ww.week, r.animal_name) AS t
    GROUP BY t.week, t.animal_name
    ORDER BY t.week, t.animal_name;
  
  -- user isn't fisher with no fish1 data
  ELSE
    RETURN QUERY
      WITH RECURSIVE weeks (start, finish, week) AS (
        SELECT s.start, s.finish, s.week
          FROM (SELECT COALESCE(in_min_date, MIN(fishing_date)) AS start,
                       COALESCE(in_max_date, MAX(fishing_date)) AS finish,
                       TO_CHAR(COALESCE(in_min_date, MIN(fishing_date)), 'IYYY-IW') AS week
                  FROM fish1."Rows"
                 LIMIT 1) AS s
     UNION ALL 
        SELECT w.start + INTERVAL '1 WEEK' AS start, 
               w.finish, 
               TO_CHAR(w.start + INTERVAL '1 WEEK', 'IYYY-IW') AS week
          FROM weeks AS w
         WHERE start < finish
      )
      SELECT ww.week, r.animal_name, SUM(r.weight), 0 AS anon
        FROM weeks AS ww
   LEFT JOIN (SELECT TO_CHAR(fishing_date, 'IYYY-IW') AS week, animal_name, f.weight
                FROM fish1."Rows" AS f
          INNER JOIN entities."Animals" USING (animal_id)
          INNER JOIN fish1."Headers" USING (header_id)
          INNER JOIN "Uploads" USING (upload_id)
          INNER JOIN "Devices" USING (device_id)
          INNER JOIN "Vessels" USING (vessel_id)
           LEFT JOIN "UserVessels" USING (vessel_id)
           LEFT JOIN "Users" AS u1 USING (user_id)
           LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
           LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
               WHERE (
                      user_type_name IN ('admin', 'researcher')
                   OR u1.user_id = in_user_id
                     )
                 AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
                 AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
                 AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
                 AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
                 AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
                 AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
    ) AS r USING (week)
    GROUP BY ww.week, r.animal_name
    ORDER BY ww.week, r.animal_name;
  END IF;
END;
$$;


ALTER FUNCTION public.catchperspeciesweek(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

--
-- Name: catchspecies(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.catchspecies(in_user_id integer) RETURNS TABLE(animal_id integer, animal_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no fish1 data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."Headers"
      INNER JOIN "Uploads" USING (upload_id)
      INNER JOIN "Devices" USING (device_id)
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user is fisher with no fish1 data
  IF FOUND THEN
    RETURN QUERY
      SELECT a.animal_id, a.animal_name
        FROM fish1."Headers"
  INNER JOIN fish1."Rows" USING (header_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
    GROUP BY a.animal_id, a.animal_name
    ORDER BY a.animal_name;
  
  -- user isn't fisher without fish1 data
  ELSE
    RETURN QUERY
      SELECT a.animal_id, a.animal_name
        FROM fish1."Headers"
  INNER JOIN fish1."Rows" USING (header_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
  INNER JOIN "Uploads" USING (upload_id)
  INNER JOIN "Devices" USING (device_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE user_type_name IN ('admin', 'researcher')
          OR u1.user_id = in_user_id
    GROUP BY a.animal_id, a.animal_name
    ORDER BY a.animal_name;
  END IF;
END;
$$;


ALTER FUNCTION public.catchspecies(in_user_id integer) OWNER TO sifids_w;

--
-- Name: datesforattributes(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.datesforattributes(in_user_id integer, in_vessels integer[]) RETURNS TABLE(min_date date, max_date date)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT MIN(time_stamp)::DATE, MAX(time_stamp)::DATE
      FROM "Attributes"
INNER JOIN "Devices" USING (device_id),
           "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id
       AND user_type_name = 'admin'
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$$;


ALTER FUNCTION public.datesforattributes(in_user_id integer, in_vessels integer[]) OWNER TO sifids_w;

--
-- Name: datesforeffort(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.datesforeffort(in_user_id integer) RETURNS TABLE(min_date date, max_date date)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT MIN(week_start), MAX(week_start)
      FROM fish1."WeeklyEffort"
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
;
END;
$$;


ALTER FUNCTION public.datesforeffort(in_user_id integer) OWNER TO sifids_w;

--
-- Name: datesfortracks(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.datesfortracks(in_user_id integer, in_vessels integer[]) RETURNS TABLE(min_date date, max_date date)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT MIN(trip_date), MAX(trip_date)
      FROM "Trips"
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$$;


ALTER FUNCTION public.datesfortracks(in_user_id integer, in_vessels integer[]) OWNER TO sifids_w;

--
-- Name: datesforvesselfish1(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.datesforvesselfish1(in_user_id integer, in_vessels integer[]) RETURNS TABLE(min_date date, max_date date)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT MIN(fishing_date)::DATE, MAX(fishing_date)::DATE
      FROM fish1."Rows"
INNER JOIN fish1."Headers" USING (header_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Vessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$$;


ALTER FUNCTION public.datesforvesselfish1(in_user_id integer, in_vessels integer[]) OWNER TO sifids_w;

--
-- Name: datesforvesselfish1(integer, integer[], integer, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.datesforvesselfish1(in_user_id integer, in_vessels integer[], in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(min_date date, max_date date)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT MIN(fishing_date)::DATE, MAX(fishing_date)::DATE
      FROM fish1."Rows"
INNER JOIN fish1."Headers" USING (header_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Vessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
       AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
       AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
       AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
;
END;
$$;


ALTER FUNCTION public.datesforvesselfish1(in_user_id integer, in_vessels integer[], in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

--
-- Name: effortcreels(integer, integer[], date, date, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.effortcreels(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) RETURNS TABLE(week_start date, catch numeric, animal_name text, effort numeric, anon integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user with no effort data
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, AVG(es.catch), a.animal_name, AVG(total_pots_fishing), 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- not user with no effort data
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(total_pots_fishing), 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date)
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$$;


ALTER FUNCTION public.effortcreels(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) OWNER TO sifids_w;

--
-- Name: effortdistance(integer, integer[], date, date, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.effortdistance(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) RETURNS TABLE(week_start date, catch numeric, animal_name text, effort numeric, anon integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));
  
  -- user has no effort data, so show averages
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, AVG(es.catch), a.animal_name, AVG(distance) / 1000, 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- user is not user with no effort data, so show real values
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(distance) / 1000, 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date) 
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$$;


ALTER FUNCTION public.effortdistance(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) OWNER TO sifids_w;

--
-- Name: effortspecies(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.effortspecies(in_user_id integer) RETURNS TABLE(animal_id integer, animal_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT a.animal_id, a.animal_name
      FROM fish1."WeeklyEffort"
INNER JOIN fish1."WeeklyEffortSpecies" USING (weekly_effort_id)
INNER JOIN entities."Animals" AS a USING (animal_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY a.animal_id
  ORDER BY a.animal_id
;
END;
$$;


ALTER FUNCTION public.effortspecies(in_user_id integer) OWNER TO sifids_w;

--
-- Name: efforttrips(integer, integer[], date, date, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.efforttrips(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) RETURNS TABLE(week_start date, catch numeric, animal_name text, effort numeric, anon integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- query to see if user is fisher with no effort data
    PERFORM user_id
       FROM "Users"
 INNER JOIN entities."UserTypes" USING (user_type_id)
      WHERE user_type_name = 'fisher'
        AND user_id = in_user_id
        AND user_id NOT IN (
          SELECT user_id
            FROM fish1."WeeklyEffort"
      INNER JOIN "UserVessels" USING (vessel_id));

  -- user with no effort data
  IF FOUND THEN
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(es.trips)::NUMERIC(20,12), 1 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
       WHERE (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  
  -- not user with no effort data
  ELSE
    RETURN QUERY
      SELECT e.week_start, SUM(es.catch), a.animal_name, SUM(es.trips)::NUMERIC(20,12), 0 AS anon
        FROM fish1."WeeklyEffort" AS e
  INNER JOIN fish1."WeeklyEffortSpecies" AS es USING (weekly_effort_id)
  INNER JOIN entities."Animals" AS a USING (animal_id)
   LEFT JOIN "UserVessels" USING (vessel_id)
   LEFT JOIN "Users" AS u1 USING (user_id)
   LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
   LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
       WHERE (
              user_type_name IN ('admin', 'researcher')
           OR u1.user_id = in_user_id
             )
         AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
         AND (e.week_start BETWEEN in_min_date AND in_max_date)
         AND (in_animals IS NULL OR in_animals = '{}' OR a.animal_id = ANY(in_animals))
    GROUP BY e.week_start, a.animal_id
    ORDER BY e.week_start
;
  END IF;
END;
$$;


ALTER FUNCTION public.efforttrips(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_animals integer[]) OWNER TO sifids_w;

--
-- Name: effortvessels(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.effortvessels(in_user_id integer) RETURNS TABLE(vessel_id integer, vessel_pln character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN user_type_name IN ('admin', 'fisher') THEN v.vessel_pln
                WHEN user_type_name IN ('researcher', 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM fish1."WeeklyEffort"
INNER JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$$;


ALTER FUNCTION public.effortvessels(in_user_id integer) OWNER TO sifids_w;

--
-- Name: eventsfromtrips(integer, integer[], character varying[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.eventsfromtrips(in_user_id integer, in_trips integer[], in_events character varying[]) RETURNS TABLE(trip_id integer, latitude numeric, longitude numeric, activity_name character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, tr.latitude, tr.longitude, a.activity_name
      FROM "Trips" AS t
INNER JOIN "Tracks" AS tr USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN analysis."FishingEvents" USING (track_id)
INNER JOIN entities."Activities" AS a USING (activity_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_trips IS NULL OR in_trips = '{}' OR t.trip_id = ANY(in_trips))
       AND (in_events IS NULL OR in_events = '{}' OR a.activity_name = ANY(in_events))
       AND is_valid = 1
;
END;
$$;


ALTER FUNCTION public.eventsfromtrips(in_user_id integer, in_trips integer[], in_events character varying[]) OWNER TO sifids_w;

--
-- Name: fisheryoffice(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.fisheryoffice(in_user_id integer) RETURNS TABLE(fo_id integer, fo_town text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT f.fo_id, f.fo_town
      FROM fish1."Headers"
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" USING (vessel_id)
INNER JOIN entities."FisheryOffices" AS f USING (fo_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY f.fo_id, f.fo_town
  ORDER BY f.fo_town
;
END;
$$;


ALTER FUNCTION public.fisheryoffice(in_user_id integer) OWNER TO sifids_w;

--
-- Name: fishingeventsavailable(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.fishingeventsavailable(in_user_id integer, in_vessels integer[]) RETURNS TABLE(event character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT activity_name
      FROM entities."Activities"
INNER JOIN analysis."FishingEvents" USING (activity_id)
INNER JOIN "Tracks" USING (track_id)
INNER JOIN "Trips" using (trip_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
;
END;
$$;


ALTER FUNCTION public.fishingeventsavailable(in_user_id integer, in_vessels integer[]) OWNER TO sifids_w;

--
-- Name: geographybathymetry(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographybathymetry() RETURNS TABLE(dn integer, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.dn, ST_Simplify(g.geom, 0.009)
      FROM geography.bathymetry AS g
;
END;
$$;


ALTER FUNCTION public.geographybathymetry() OWNER TO sifids_w;

--
-- Name: geographyhauls(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographyhauls() RETURNS TABLE(combined double precision, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.combined, ST_Simplify(g.geom, 0.009)
      FROM geography."Hauls" AS g
     WHERE g.combined > 0.5
;
END;
$$;


ALTER FUNCTION public.geographyhauls() OWNER TO sifids_w;

--
-- Name: geographyminke(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographyminke() RETURNS TABLE(year integer, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g."year", ST_Simplify(g.geom, 0.009)
      FROM geography."Minke" AS g
;
END;
$$;


ALTER FUNCTION public.geographyminke() OWNER TO sifids_w;

--
-- Name: geographyobservations(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographyobservations() RETURNS TABLE(latitude numeric, longitude numeric, animal_name text, animal_group text, observation_count bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.latitude, g.longitude, a1.animal_name,
           COALESCE(a2.animal_name, a1.animal_name),
           SUM(g.observed_count)
      FROM geography."Observations" AS g
INNER JOIN entities."Animals" AS a1 ON g.animal_id = a1.animal_id
 LEFT JOIN entities."Animals" AS a2 ON a1.subclass_of = a2.animal_id
  GROUP BY g.latitude, g.longitude, a1.animal_id, a2.animal_id
;
END;
$$;


ALTER FUNCTION public.geographyobservations() OWNER TO sifids_w;

--
-- Name: geographysightings(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographysightings(in_year integer) RETURNS TABLE(geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.geom
      FROM geography."HWDTCreels" AS g
     WHERE hwdt_year = in_year
;
END;
$$;


ALTER FUNCTION public.geographysightings(in_year integer) OWNER TO sifids_w;

--
-- Name: geographyvessels(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.geographyvessels() RETURNS TABLE(vessel_count integer, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.vessel_count::INTEGER, ST_Simplify(g.geom, 0.009)
      FROM geography."CreelVessels" AS g
     WHERE g.vessel_count IS NOT NULL
;
END;
$$;


ALTER FUNCTION public.geographyvessels() OWNER TO sifids_w;

--
-- Name: getattributes(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.getattributes() RETURNS TABLE(attribute_id integer, attribute_name character varying, attribute_display text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT a.attribute_id, a.attribute_name, a.attribute_display
      FROM entities."AttributeTypes" AS a
;
END;
$$;


ALTER FUNCTION public.getattributes() OWNER TO sifids_w;

--
-- Name: getdeviceid(text); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.getdeviceid(in_device_string text) RETURNS TABLE(device_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT d.device_id 
      FROM "Devices" AS d
     WHERE d.device_string = in_device_string
;
END;
$$;


ALTER FUNCTION public.getdeviceid(in_device_string text) OWNER TO sifids_w;

--
-- Name: gettripid(integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.gettripid(in_device_id integer, in_time_stamp timestamp with time zone) RETURNS TABLE(trip_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- get ID of trip matching device and date in time stamp
    SELECT t.trip_id
      INTO trip_id
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
     WHERE t.device_id = in_device_id
       AND t.trip_date = in_time_stamp::DATE
  GROUP BY t.trip_id
  ORDER BY COUNT(*) DESC
     LIMIT 1
;
   
   -- if nothing found, insert new trip
   IF trip_id IS NULL THEN
     INSERT INTO "Trips" AS t (device_id, trip_date)
          SELECT in_device_id, in_time_stamp::DATE
       RETURNING t.trip_id INTO trip_id;
   END IF;
   
   RETURN QUERY
     SELECT trip_id;
END;
$$;


ALTER FUNCTION public.gettripid(in_device_id integer, in_time_stamp timestamp with time zone) OWNER TO sifids_w;

--
-- Name: gettripsfortania(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.gettripsfortania(in_trip_id integer) RETURNS TABLE(trip_id integer, track_id integer, time_stamp timestamp with time zone, x double precision, y double precision)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT in_trip_id, 
           MIN(tks.track_id), -- pick first track ID
           tks.time_stamp,
           ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 32630)) AS x, 
           ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 32630)) AS y 
      FROM "Tracks" AS tks
     WHERE tks.trip_id = in_trip_id
       AND longitude < -0.5 -- 1 - remove wrong lats and longs
       AND is_valid = 1
       AND NOT EXISTS (
                       SELECT 1
                         FROM geography.scotlandmap2
                        WHERE ST_Contains(buffer, ST_SetSRID(ST_MakePoint(tks.longitude, tks.latitude), 4326)) -- 3, 4 - remove points too close to land and on land
                      )
  GROUP BY tks.time_stamp, tks.latitude, tks.longitude -- 2 - remove duplicates
  ORDER BY time_stamp ASC;
END;
$$;


ALTER FUNCTION public.gettripsfortania(in_trip_id integer) OWNER TO sifids_w;

--
-- Name: heatmapdata(integer, integer[], date, date); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.heatmapdata(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) RETURNS TABLE(trip_id integer, lat numeric, long numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, latitude, longitude
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
;
END;
$$;


ALTER FUNCTION public.heatmapdata(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) OWNER TO sifids_w;

--
-- Name: heatmapdatafisher(integer, integer[], date, date); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.heatmapdatafisher(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) RETURNS TABLE(trip_id integer, lat numeric, long numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, latitude, longitude
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
--INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
;
END;
$$;


ALTER FUNCTION public.heatmapdatafisher(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) OWNER TO sifids_w;

--
-- Name: latestpoints(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.latestpoints(in_user_id integer, in_trips integer[]) RETURNS TABLE(trip_id integer, vessel_name character varying, time_stamp timestamp with time zone, latitude numeric, longitude numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, 
           COALESCE(
             CASE WHEN user_type_name IN ('admin', 'fisher') THEN vessel_pln
                  WHEN user_type_name IN ('researcher', 'fishery officer') THEN vessel_code::VARCHAR(16)
             END,
             'no vessel') AS vessel_name, 
           "Tracks".time_stamp, "Tracks".latitude, "Tracks".longitude
      FROM "Tracks"
INNER JOIN "Trips" AS t USING (trip_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN (SELECT device_id, MAX(trptm.time_stamp) AS time_stamp
              FROM (SELECT "Trips".trip_id, device_id, MAX("Tracks".time_stamp) AS time_stamp
                      FROM "Trips"
                INNER JOIN "Tracks" USING (trip_id)
                     WHERE "Trips".trip_id = ANY(in_trips)
                       AND DATE_TRUNC('day', trip_date) = DATE_TRUNC('day', NOW())
                       AND is_valid = 1
                  GROUP BY "Trips".trip_id) AS trptm
         GROUP BY device_id) AS dvtm 
     USING (device_id, time_stamp)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND t.trip_id = ANY(in_trips)
       AND DATE_TRUNC('day', trip_date) = DATE_TRUNC('day', NOW())
;
END;
$$;


ALTER FUNCTION public.latestpoints(in_user_id integer, in_trips integer[]) OWNER TO sifids_w;

--
-- Name: portofdeparture(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.portofdeparture(in_user_id integer) RETURNS TABLE(port_id integer, port_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Headers" AS h
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_departure_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$$;


ALTER FUNCTION public.portofdeparture(in_user_id integer) OWNER TO sifids_w;

--
-- Name: portofdeparture(integer, integer[], date, date, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.portofdeparture(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(port_id integer, port_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Rows"
INNER JOIN fish1."Headers" AS h USING (header_id)
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_departure_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Vessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           )
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
       AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
       AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
       AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$$;


ALTER FUNCTION public.portofdeparture(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

--
-- Name: portofdeparture(integer, integer[], date, date, integer, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.portofdeparture(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(port_id integer, port_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Rows"
INNER JOIN fish1."Headers" AS h USING (header_id)
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_departure_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Vessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           )
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
       AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure) 
       AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
       AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
       AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$$;


ALTER FUNCTION public.portofdeparture(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

--
-- Name: portoflanding(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.portoflanding(in_user_id integer) RETURNS TABLE(port_id integer, port_name text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT p.port_id, p.port_name
      FROM fish1."Headers" AS h
INNER JOIN entities."Ports" AS p ON (p.port_id = h.port_of_landing_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY p.port_id, p.port_name
  ORDER BY p.port_name
;
END;
$$;


ALTER FUNCTION public.portoflanding(in_user_id integer) OWNER TO sifids_w;

--
-- Name: revisitsmapdata(integer, integer[], date, date); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.revisitsmapdata(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) RETURNS TABLE(lat1 numeric, long1 numeric, lat2 numeric, long2 numeric, counts bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.latitude1, g.longitude1, g.latitude2, g.longitude2, COUNT(*)
      FROM "Trips" AS t
INNER JOIN "Tracks" USING (trip_id)
INNER JOIN analysis."TrackAnalysis" USING (track_id)
INNER JOIN analysis."Grids" AS g USING (grid_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_vessels IS NULL OR in_vessels = '{}' OR vessel_id = ANY(in_vessels))
       AND trip_date BETWEEN in_min_date AND in_max_date
       AND is_valid = 1
  GROUP BY g.grid_id
    HAVING COUNT(*) > 1
  ORDER BY COUNT(*) ASC
;
END;
$$;


ALTER FUNCTION public.revisitsmapdata(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) OWNER TO sifids_w;

--
-- Name: rifgs(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.rifgs() RETURNS TABLE(rifg character varying, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.rifg, ST_Simplify(g.geom, 0.009)
      FROM geography."RIFGs" AS g
;
END;
$$;


ALTER FUNCTION public.rifgs() OWNER TO sifids_w;

--
-- Name: scottishmarineregions(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.scottishmarineregions() RETURNS TABLE(objnam character varying, geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT g.objnam, ST_Simplify(g.geom, 0.009)
      FROM geography."ScottishMarineRegions" AS g
;
END;
$$;


ALTER FUNCTION public.scottishmarineregions() OWNER TO sifids_w;

--
-- Name: sixmilelimit(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.sixmilelimit() RETURNS TABLE(geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT ST_Simplify(g.geom, 0.009)
      FROM geography."SixMileLimit" AS g
;
END;
$$;


ALTER FUNCTION public.sixmilelimit() OWNER TO sifids_w;

--
-- Name: threemilelimit(); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.threemilelimit() RETURNS TABLE(geom public.geometry)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT ST_Simplify(g.geom, 0.009)
      FROM geography."ThreeMileLimit" AS g
;
END;
$$;


ALTER FUNCTION public.threemilelimit() OWNER TO sifids_w;

--
-- Name: trackdataavailable(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.trackdataavailable(in_user_id integer) RETURNS TABLE(estimates integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  -- see if user is admin/researcher/fo
   PERFORM 1
      FROM "Users"
INNER JOIN entities."UserTypes" USING (user_type_id)
     WHERE user_id = in_user_id 
       AND user_type_name IN ('admin', 'researcher', 'fishery officer')
;

  IF FOUND THEN
    RETURN QUERY
      SELECT 1;
  ELSE
    RETURN QUERY
      SELECT EXISTS (
        SELECT 1
          FROM "UserVessels"
    INNER JOIN "Devices" USING (vessel_id)
    INNER JOIN "Trips" USING (device_id)
    INNER JOIN "Tracks" USING (trip_id)
    INNER JOIN analysis."TrackAnalysis" USING (track_id)
    INNER JOIN entities."Activities" USING (activity_id)
         WHERE user_id = in_user_id
           AND activity_name = 'hauling'
         )::INTEGER;
  END IF;
END;
$$;


ALTER FUNCTION public.trackdataavailable(in_user_id integer) OWNER TO sifids_w;

--
-- Name: tracksfromtrips(integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.tracksfromtrips(in_user_id integer, in_trips integer[]) RETURNS TABLE(trip_id integer, latitude numeric, longitude numeric, activity integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  temp_factor INTEGER;
BEGIN
  -- put data into temp table
  CREATE TEMPORARY TABLE temp_tracks AS
    SELECT t.trip_id, tr.latitude, tr.longitude, COALESCE(activity_id, 1) AS activity, -- not fishing when no activity present
           t.trip_date, tr.time_stamp, ROW_NUMBER() OVER (ORDER BY t.trip_date, tr.time_stamp)
      FROM "Trips" AS t
INNER JOIN "Tracks" AS tr USING (trip_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN analysis."TrackAnalysis" USING (track_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher')
         OR u1.user_id = in_user_id
           ) 
       AND (in_trips IS NULL OR in_trips = '{}' OR t.trip_id = ANY(in_trips)) 
       AND is_valid = 1
;

  -- get number of rows
  SELECT (COUNT(*) / 1000)::INTEGER FROM temp_tracks INTO temp_factor;

  -- decide if temp_tracks needs to be thinned
  IF temp_factor > 1 THEN
    DELETE 
      FROM temp_tracks AS t
     WHERE MOD(t.row_number, temp_factor) <> 0 -- thin using modulo of row number
       AND t.activity = 1; -- and no fishing activity
  END IF;

  -- send back (possibly) thinned data
  RETURN QUERY
    SELECT t.trip_id, t.latitude, t.longitude, t.activity
      FROM temp_tracks AS t
  ORDER BY t.trip_date, t.time_stamp
;

  -- finished with temp table
  DROP TABLE temp_tracks
;
END;
$$;


ALTER FUNCTION public.tracksfromtrips(in_user_id integer, in_trips integer[]) OWNER TO sifids_w;

--
-- Name: trackvessels(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.trackvessels(in_user_id integer) RETURNS TABLE(vessel_id integer, vessel_pln character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN user_type_name IN ('admin', 'fisher') THEN v.vessel_pln
                WHEN user_type_name IN ('researcher' , 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM "Trips" AS t
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher')
        OR u1.user_id = in_user_id
  GROUP BY user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$$;


ALTER FUNCTION public.trackvessels(in_user_id integer) OWNER TO sifids_w;

--
-- Name: tripestimates(integer, integer[], date, date); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.tripestimates(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) RETURNS TABLE(trip_id integer, trip_name character varying, creels_low integer, creels_high integer, distance integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, 
           (COALESCE(
             CASE WHEN user_type_name IN ('admin', 'fisher') THEN vessel_pln
                  WHEN user_type_name IN ('researcher', 'fishery officer') THEN vessel_code::VARCHAR(16)
             END,
             'no vessel'
           ) || ' - ' || TO_CHAR(trip_date::DATE, 'dd-mm-yyyy'))::VARCHAR(255), 
           MAX(low.estimate_value)::INTEGER, 
           MAX(high.estimate_value)::INTEGER, 
           (MAX(dist.estimate_value) / 1000)::INTEGER
      FROM "Tracks"
INNER JOIN "Trips" AS t USING (trip_id)
INNER JOIN "Devices" USING (device_id)
 LEFT JOIN analysis."Estimates" AS low ON (t.trip_id = low.trip_id AND low.estimate_type_id = 1)
 LEFT JOIN analysis."Estimates" AS high ON (t.trip_id = high.trip_id AND high.estimate_type_id = 2)
 LEFT JOIN analysis."Estimates" AS dist ON (t.trip_id = dist.trip_id AND dist.estimate_type_id = 3)
 LEFT JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') 
         OR u1.user_id = in_user_id
           ) 
       AND (
            in_vessels IS NULL 
         OR in_vessels = '{}' 
         OR vessel_id = ANY(in_vessels)
           )
       AND trip_date BETWEEN in_min_date AND in_max_date
  GROUP BY ut.user_type_name, t.trip_id, v.vessel_id
    HAVING COUNT(*) > 1 -- exclude trips with only 1 track
  ORDER BY trip_date DESC, vessel_pln ASC
;
END;
$$;


ALTER FUNCTION public.tripestimates(in_user_id integer, in_vessels integer[], in_min_date date, in_max_date date) OWNER TO sifids_w;

--
-- Name: vesselsfish1(integer); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.vesselsfish1(in_user_id integer) RETURNS TABLE(vessel_id integer, vessel_pln character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN ut.user_type_name IN ('admin', 'fisher') THEN v.vessel_pln 
                WHEN ut.user_type_name IN ('researcher', 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM fish1."Headers"
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE user_type_name IN ('admin', 'researcher') -- see all vessels
        OR u1.user_id = in_user_id -- just see own vessel/s
  GROUP BY ut.user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$$;


ALTER FUNCTION public.vesselsfish1(in_user_id integer) OWNER TO sifids_w;

--
-- Name: vesselsfish1(integer, date, date, integer, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: sifids_w
--

CREATE FUNCTION public.vesselsfish1(in_user_id integer, in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) RETURNS TABLE(vessel_id integer, vessel_pln character varying)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
    SELECT v.vessel_id, 
           CASE WHEN ut.user_type_name IN ('admin', 'fisher') THEN v.vessel_pln 
                WHEN ut.user_type_name IN ('researcher', 'fishery officer') THEN v.vessel_code::VARCHAR(16)
           END
      FROM fish1."Rows"
INNER JOIN fish1."Headers" USING (header_id)
INNER JOIN "Uploads" USING (upload_id)
INNER JOIN "Devices" USING (device_id)
INNER JOIN "Vessels" AS v USING (vessel_id)
 LEFT JOIN "UserVessels" USING (vessel_id)
 LEFT JOIN "Users" AS u1 USING (user_id)
 LEFT JOIN "Users" AS u2 ON (u2.user_id = in_user_id)
 LEFT JOIN entities."UserTypes" AS ut ON u2.user_type_id = ut.user_type_id
     WHERE (
            user_type_name IN ('admin', 'researcher') -- see all vessels
         OR u1.user_id = in_user_id -- just see own vessel/s
           )
       AND (in_species IS NULL OR in_species = '{}' OR animal_id = ANY(in_species)) 
       AND (in_port_departure IS NULL OR in_port_departure = 0 OR port_of_departure_id = in_port_departure)
       AND (in_port_landing IS NULL OR in_port_landing = 0 OR port_of_landing_id = in_port_landing) 
       AND (in_fo IS NULL OR in_fo = 0 OR fo_id = in_fo) 
       AND (in_min_date IS NULL OR in_max_date IS NULL OR fishing_date BETWEEN in_min_date AND in_max_date)
  GROUP BY ut.user_type_name, v.vessel_id
  ORDER BY v.vessel_pln
;
END;
$$;


ALTER FUNCTION public.vesselsfish1(in_user_id integer, in_min_date date, in_max_date date, in_port_departure integer, in_port_landing integer, in_fo integer, in_species integer[]) OWNER TO sifids_w;

SET default_tablespace = '';

--
-- Name: Estimates; Type: TABLE; Schema: analysis; Owner: sifids_w
--

CREATE TABLE analysis."Estimates" (
    trip_id integer NOT NULL,
    estimate_type_id integer NOT NULL,
    estimate_value numeric
);


ALTER TABLE analysis."Estimates" OWNER TO sifids_w;

--
-- Name: FishingEvents; Type: TABLE; Schema: analysis; Owner: sifids_w
--

CREATE TABLE analysis."FishingEvents" (
    track_id integer,
    activity_id integer
);


ALTER TABLE analysis."FishingEvents" OWNER TO sifids_w;

--
-- Name: Grids; Type: TABLE; Schema: analysis; Owner: sifids_w
--

CREATE TABLE analysis."Grids" (
    grid_id integer NOT NULL,
    latitude1 numeric(15,12),
    longitude1 numeric(15,12),
    latitude2 numeric(15,12),
    longitude2 numeric(15,12)
);


ALTER TABLE analysis."Grids" OWNER TO sifids_w;

--
-- Name: Grids_grid_id_seq; Type: SEQUENCE; Schema: analysis; Owner: sifids_w
--

CREATE SEQUENCE analysis."Grids_grid_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE analysis."Grids_grid_id_seq" OWNER TO sifids_w;

--
-- Name: Grids_grid_id_seq; Type: SEQUENCE OWNED BY; Schema: analysis; Owner: sifids_w
--

ALTER SEQUENCE analysis."Grids_grid_id_seq" OWNED BY analysis."Grids".grid_id;


--
-- Name: TrackAnalysis; Type: TABLE; Schema: analysis; Owner: sifids_w
--

CREATE TABLE analysis."TrackAnalysis" (
    track_id integer NOT NULL,
    grid_id integer,
    activity_id integer
);


ALTER TABLE analysis."TrackAnalysis" OWNER TO sifids_w;

--
-- Name: Activities; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Activities" (
    activity_id integer NOT NULL,
    activity_name character varying(32)
);


ALTER TABLE entities."Activities" OWNER TO sifids_w;

--
-- Name: Activities_activity_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Activities_activity_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Activities_activity_id_seq" OWNER TO sifids_w;

--
-- Name: Activities_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Activities_activity_id_seq" OWNED BY entities."Activities".activity_id;


--
-- Name: Animals; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Animals" (
    animal_id integer NOT NULL,
    animal_name text,
    animal_code character varying(16),
    subclass_of integer
);


ALTER TABLE entities."Animals" OWNER TO sifids_w;

--
-- Name: Animals_animal_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Animals_animal_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Animals_animal_id_seq" OWNER TO sifids_w;

--
-- Name: Animals_animal_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Animals_animal_id_seq" OWNED BY entities."Animals".animal_id;


--
-- Name: AttributeTypes; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."AttributeTypes" (
    attribute_id integer NOT NULL,
    attribute_name character varying(32),
    attribute_display text
);


ALTER TABLE entities."AttributeTypes" OWNER TO sifids_w;

--
-- Name: AttributeTypes_attribute_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."AttributeTypes_attribute_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."AttributeTypes_attribute_id_seq" OWNER TO sifids_w;

--
-- Name: AttributeTypes_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."AttributeTypes_attribute_id_seq" OWNED BY entities."AttributeTypes".attribute_id;


--
-- Name: DeviceModels; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."DeviceModels" (
    model_id integer NOT NULL,
    model_family character varying(255),
    model_name character varying(255),
    protocol_id integer
);


ALTER TABLE entities."DeviceModels" OWNER TO sifids_w;

--
-- Name: DeviceModels_model_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."DeviceModels_model_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."DeviceModels_model_id_seq" OWNER TO sifids_w;

--
-- Name: DeviceModels_model_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."DeviceModels_model_id_seq" OWNED BY entities."DeviceModels".model_id;


--
-- Name: DevicePower; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."DevicePower" (
    devce_power_id integer NOT NULL,
    device_power_name character varying(32)
);


ALTER TABLE entities."DevicePower" OWNER TO sifids_w;

--
-- Name: DevicePower_devce_power_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."DevicePower_devce_power_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."DevicePower_devce_power_id_seq" OWNER TO sifids_w;

--
-- Name: DevicePower_devce_power_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."DevicePower_devce_power_id_seq" OWNED BY entities."DevicePower".devce_power_id;


--
-- Name: EstimateTypes; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."EstimateTypes" (
    estimate_type_id integer NOT NULL,
    estimate_name character varying(32)
);


ALTER TABLE entities."EstimateTypes" OWNER TO sifids_w;

--
-- Name: EstimateTypes_estimate_type_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."EstimateTypes_estimate_type_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."EstimateTypes_estimate_type_id_seq" OWNER TO sifids_w;

--
-- Name: EstimateTypes_estimate_type_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."EstimateTypes_estimate_type_id_seq" OWNED BY entities."EstimateTypes".estimate_type_id;


--
-- Name: FisheryOffices; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."FisheryOffices" (
    fo_id integer NOT NULL,
    fo_town text,
    fo_address text,
    fo_email text
);


ALTER TABLE entities."FisheryOffices" OWNER TO sifids_w;

--
-- Name: FisheryOffices_fo_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."FisheryOffices_fo_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."FisheryOffices_fo_id_seq" OWNER TO sifids_w;

--
-- Name: FisheryOffices_fo_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."FisheryOffices_fo_id_seq" OWNED BY entities."FisheryOffices".fo_id;


--
-- Name: Gears; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Gears" (
    gear_id integer NOT NULL,
    gear_name character varying(32)
);


ALTER TABLE entities."Gears" OWNER TO sifids_w;

--
-- Name: Gears_gear_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Gears_gear_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Gears_gear_id_seq" OWNER TO sifids_w;

--
-- Name: Gears_gear_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Gears_gear_id_seq" OWNED BY entities."Gears".gear_id;


--
-- Name: IcesRectangles; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."IcesRectangles" (
    ices_id integer NOT NULL,
    ices_name character varying(8)
);


ALTER TABLE entities."IcesRectangles" OWNER TO sifids_w;

--
-- Name: IcesRectangles_ices_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."IcesRectangles_ices_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."IcesRectangles_ices_id_seq" OWNER TO sifids_w;

--
-- Name: IcesRectangles_ices_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."IcesRectangles_ices_id_seq" OWNED BY entities."IcesRectangles".ices_id;


--
-- Name: Ports; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Ports" (
    port_id integer NOT NULL,
    port_name text,
    latitude numeric(15,12),
    longitude numeric(15,12)
);


ALTER TABLE entities."Ports" OWNER TO sifids_w;

--
-- Name: Ports_port_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Ports_port_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Ports_port_id_seq" OWNER TO sifids_w;

--
-- Name: Ports_port_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Ports_port_id_seq" OWNED BY entities."Ports".port_id;


--
-- Name: Presentations; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Presentations" (
    presentation_id integer NOT NULL,
    presentation_name character varying(32)
);


ALTER TABLE entities."Presentations" OWNER TO sifids_w;

--
-- Name: Presentations_presentation_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Presentations_presentation_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Presentations_presentation_id_seq" OWNER TO sifids_w;

--
-- Name: Presentations_presentation_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Presentations_presentation_id_seq" OWNED BY entities."Presentations".presentation_id;


--
-- Name: Projects; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Projects" (
    project_id integer NOT NULL,
    project_code character varying(16),
    project_name text
);


ALTER TABLE entities."Projects" OWNER TO sifids_w;

--
-- Name: Projects_project_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Projects_project_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Projects_project_id_seq" OWNER TO sifids_w;

--
-- Name: Projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Projects_project_id_seq" OWNED BY entities."Projects".project_id;


--
-- Name: Protocols; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."Protocols" (
    protocol_id integer NOT NULL,
    protocol_name text,
    protocol_code character varying(255)
);


ALTER TABLE entities."Protocols" OWNER TO sifids_w;

--
-- Name: Protocols_protocol_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."Protocols_protocol_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."Protocols_protocol_id_seq" OWNER TO sifids_w;

--
-- Name: Protocols_protocol_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."Protocols_protocol_id_seq" OWNED BY entities."Protocols".protocol_id;


--
-- Name: States; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."States" (
    state_id integer NOT NULL,
    state_name character varying(32)
);


ALTER TABLE entities."States" OWNER TO sifids_w;

--
-- Name: States_state_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."States_state_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."States_state_id_seq" OWNER TO sifids_w;

--
-- Name: States_state_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."States_state_id_seq" OWNED BY entities."States".state_id;


--
-- Name: UserTypes; Type: TABLE; Schema: entities; Owner: sifids_w
--

CREATE TABLE entities."UserTypes" (
    user_type_id integer NOT NULL,
    user_type_name character varying(32)
);


ALTER TABLE entities."UserTypes" OWNER TO sifids_w;

--
-- Name: UserTypes_user_type_id_seq; Type: SEQUENCE; Schema: entities; Owner: sifids_w
--

CREATE SEQUENCE entities."UserTypes_user_type_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities."UserTypes_user_type_id_seq" OWNER TO sifids_w;

--
-- Name: UserTypes_user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: sifids_w
--

ALTER SEQUENCE entities."UserTypes_user_type_id_seq" OWNED BY entities."UserTypes".user_type_id;


--
-- Name: Headers; Type: TABLE; Schema: fish1; Owner: sifids_w
--

CREATE TABLE fish1."Headers" (
    header_id integer NOT NULL,
    upload_id integer,
    port_of_departure_id integer,
    port_of_landing_id integer,
    total_pots_fishing integer,
    comments text
);


ALTER TABLE fish1."Headers" OWNER TO sifids_w;

--
-- Name: Headers_header_id_seq; Type: SEQUENCE; Schema: fish1; Owner: sifids_w
--

CREATE SEQUENCE fish1."Headers_header_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fish1."Headers_header_id_seq" OWNER TO sifids_w;

--
-- Name: Headers_header_id_seq; Type: SEQUENCE OWNED BY; Schema: fish1; Owner: sifids_w
--

ALTER SEQUENCE fish1."Headers_header_id_seq" OWNED BY fish1."Headers".header_id;


--
-- Name: Rows; Type: TABLE; Schema: fish1; Owner: sifids_w
--

CREATE TABLE fish1."Rows" (
    header_id integer,
    animal_id integer,
    gear_id integer,
    state_id integer,
    presentation_id integer,
    ices_id integer,
    fishing_date timestamp with time zone,
    landing_or_discard_date timestamp with time zone,
    lat_long character varying(32),
    mesh_size integer,
    weight numeric(6,2) DEFAULT NULL::numeric,
    dis integer,
    bms integer,
    number_of_pots integer,
    transporter_reg text
);


ALTER TABLE fish1."Rows" OWNER TO sifids_w;

--
-- Name: WeeklyEffort; Type: TABLE; Schema: fish1; Owner: sifids_w
--

CREATE TABLE fish1."WeeklyEffort" (
    weekly_effort_id integer NOT NULL,
    vessel_id integer,
    week_start date,
    distance numeric,
    total_pots_fishing numeric
);


ALTER TABLE fish1."WeeklyEffort" OWNER TO sifids_w;

--
-- Name: WeeklyEffortSpecies; Type: TABLE; Schema: fish1; Owner: sifids_w
--

CREATE TABLE fish1."WeeklyEffortSpecies" (
    weekly_effort_id integer NOT NULL,
    animal_id integer NOT NULL,
    catch numeric,
    trips integer
);


ALTER TABLE fish1."WeeklyEffortSpecies" OWNER TO sifids_w;

--
-- Name: WeeklyEffort_weekly_effort_id_seq; Type: SEQUENCE; Schema: fish1; Owner: sifids_w
--

CREATE SEQUENCE fish1."WeeklyEffort_weekly_effort_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fish1."WeeklyEffort_weekly_effort_id_seq" OWNER TO sifids_w;

--
-- Name: WeeklyEffort_weekly_effort_id_seq; Type: SEQUENCE OWNED BY; Schema: fish1; Owner: sifids_w
--

ALTER SEQUENCE fish1."WeeklyEffort_weekly_effort_id_seq" OWNED BY fish1."WeeklyEffort".weekly_effort_id;


--
-- Name: CreelVessels; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."CreelVessels" (
    vessel_count numeric,
    geom public.geometry(MultiPolygon)
);


ALTER TABLE geography."CreelVessels" OWNER TO sifids_w;

--
-- Name: HWDTCreels; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."HWDTCreels" (
    hwdt_year integer,
    geom public.geometry(Point,4326)
);


ALTER TABLE geography."HWDTCreels" OWNER TO sifids_w;

--
-- Name: Hauls; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."Hauls" (
    combined double precision,
    geom public.geometry(MultiPolygon)
);


ALTER TABLE geography."Hauls" OWNER TO sifids_w;

--
-- Name: MPAs; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."MPAs" (
    mpa_id integer NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    mpa_name character varying(255),
    pa_code bigint,
    eur_code character varying(48),
    lead character varying(4),
    site_ha numeric,
    status character varying(200)
);


ALTER TABLE geography."MPAs" OWNER TO sifids_w;

--
-- Name: MPAs_mpa_id_seq; Type: SEQUENCE; Schema: geography; Owner: sifids_w
--

CREATE SEQUENCE geography."MPAs_mpa_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geography."MPAs_mpa_id_seq" OWNER TO sifids_w;

--
-- Name: MPAs_mpa_id_seq; Type: SEQUENCE OWNED BY; Schema: geography; Owner: sifids_w
--

ALTER SEQUENCE geography."MPAs_mpa_id_seq" OWNED BY geography."MPAs".mpa_id;


--
-- Name: Minke; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."Minke" (
    year integer,
    geom public.geometry(Point)
);


ALTER TABLE geography."Minke" OWNER TO sifids_w;

--
-- Name: Observations; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."Observations" (
    upload_id integer,
    animal_id integer,
    time_stamp timestamp with time zone,
    latitude numeric(15,12),
    longitude numeric(15,12),
    observed_count integer,
    notes text
);


ALTER TABLE geography."Observations" OWNER TO sifids_w;

--
-- Name: RIFGs; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."RIFGs" (
    rifg character varying(32),
    geom public.geometry(MultiPolygon,4326)
);


ALTER TABLE geography."RIFGs" OWNER TO sifids_w;

--
-- Name: ScottishMarineRegions; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."ScottishMarineRegions" (
    objnam character varying(255),
    geom public.geometry(MultiPolygon,4326)
);


ALTER TABLE geography."ScottishMarineRegions" OWNER TO sifids_w;

--
-- Name: SixMileLimit; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."SixMileLimit" (
    geom public.geometry(MultiLineString,4326)
);


ALTER TABLE geography."SixMileLimit" OWNER TO sifids_w;

--
-- Name: ThreeMileLimit; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography."ThreeMileLimit" (
    geom public.geometry(MultiPolygon,4326)
);


ALTER TABLE geography."ThreeMileLimit" OWNER TO sifids_w;

--
-- Name: bathymetry; Type: TABLE; Schema: geography; Owner: sifids_w
--

CREATE TABLE geography.bathymetry (
    gid integer NOT NULL,
    dn integer,
    geom public.geometry(Polygon)
);


ALTER TABLE geography.bathymetry OWNER TO sifids_w;

--
-- Name: bathymetry_gid_seq; Type: SEQUENCE; Schema: geography; Owner: sifids_w
--

CREATE SEQUENCE geography.bathymetry_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geography.bathymetry_gid_seq OWNER TO sifids_w;

--
-- Name: bathymetry_gid_seq; Type: SEQUENCE OWNED BY; Schema: geography; Owner: sifids_w
--

ALTER SEQUENCE geography.bathymetry_gid_seq OWNED BY geography.bathymetry.gid;


--
-- Name: scotlandmap2; Type: TABLE; Schema: geography; Owner: postgres
--

CREATE TABLE geography.scotlandmap2 (
    gid integer NOT NULL,
    id numeric,
    geom public.geometry(MultiPolygon,4326),
    buffer public.geometry
);


ALTER TABLE geography.scotlandmap2 OWNER TO postgres;

--
-- Name: scotlandmap2_gid_seq; Type: SEQUENCE; Schema: geography; Owner: postgres
--

CREATE SEQUENCE geography.scotlandmap2_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geography.scotlandmap2_gid_seq OWNER TO postgres;

--
-- Name: scotlandmap2_gid_seq; Type: SEQUENCE OWNED BY; Schema: geography; Owner: postgres
--

ALTER SEQUENCE geography.scotlandmap2_gid_seq OWNED BY geography.scotlandmap2.gid;


--
-- Name: Attributes; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Attributes" (
    attribute_id integer NOT NULL,
    device_id integer NOT NULL,
    time_stamp timestamp with time zone NOT NULL,
    attribute_value numeric
);


ALTER TABLE public."Attributes" OWNER TO sifids_w;

--
-- Name: TABLE "Attributes"; Type: COMMENT; Schema: public; Owner: sifids_w
--

COMMENT ON TABLE public."Attributes" IS 'Data supplied by device about itself';


--
-- Name: Devices; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Devices" (
    device_id integer NOT NULL,
    vessel_id integer,
    device_name text,
    device_string text,
    serial_number character varying(255),
    model_id integer,
    telephone character varying(255),
    device_power_id integer,
    created timestamp with time zone DEFAULT now(),
    device_active smallint DEFAULT 1,
    engineer_notes text
);


ALTER TABLE public."Devices" OWNER TO sifids_w;

--
-- Name: COLUMN "Devices".device_name; Type: COMMENT; Schema: public; Owner: sifids_w
--

COMMENT ON COLUMN public."Devices".device_name IS 'e.g. s004_204_solar';


--
-- Name: COLUMN "Devices".device_string; Type: COMMENT; Schema: public; Owner: sifids_w
--

COMMENT ON COLUMN public."Devices".device_string IS 'e.g. IMEI number';


--
-- Name: Devices_device_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Devices_device_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Devices_device_id_seq" OWNER TO sifids_w;

--
-- Name: Devices_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Devices_device_id_seq" OWNED BY public."Devices".device_id;


--
-- Name: Tracks; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Tracks" (
    track_id integer NOT NULL,
    latitude numeric(15,12),
    longitude numeric(15,12),
    time_stamp timestamp with time zone,
    trip_id integer,
    is_valid smallint DEFAULT 1
);


ALTER TABLE public."Tracks" OWNER TO sifids_w;

--
-- Name: COLUMN "Tracks".is_valid; Type: COMMENT; Schema: public; Owner: sifids_w
--

COMMENT ON COLUMN public."Tracks".is_valid IS '1 = valid, 0 = invalid';


--
-- Name: Tracks_track_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Tracks_track_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Tracks_track_id_seq" OWNER TO sifids_w;

--
-- Name: Tracks_track_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Tracks_track_id_seq" OWNED BY public."Tracks".track_id;


--
-- Name: Trips; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Trips" (
    trip_id integer NOT NULL,
    device_id integer,
    trip_date date,
    legacy_id character varying(10)
);


ALTER TABLE public."Trips" OWNER TO sifids_w;

--
-- Name: Trips_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Trips_trip_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Trips_trip_id_seq" OWNER TO sifids_w;

--
-- Name: Trips_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Trips_trip_id_seq" OWNED BY public."Trips".trip_id;


--
-- Name: Uploads; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Uploads" (
    upload_id integer NOT NULL,
    device_id integer,
    time_stamp timestamp with time zone DEFAULT now()
);


ALTER TABLE public."Uploads" OWNER TO sifids_w;

--
-- Name: Uploads_upload_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Uploads_upload_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Uploads_upload_id_seq" OWNER TO sifids_w;

--
-- Name: Uploads_upload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Uploads_upload_id_seq" OWNED BY public."Uploads".upload_id;


--
-- Name: UserFisheryOffices; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."UserFisheryOffices" (
    user_id integer,
    fo_id integer
);


ALTER TABLE public."UserFisheryOffices" OWNER TO sifids_w;

--
-- Name: UserProjects; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."UserProjects" (
    user_id integer,
    project_id integer
);


ALTER TABLE public."UserProjects" OWNER TO sifids_w;

--
-- Name: UserVessels; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."UserVessels" (
    user_id integer NOT NULL,
    vessel_id integer NOT NULL
);


ALTER TABLE public."UserVessels" OWNER TO sifids_w;

--
-- Name: Users; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Users" (
    user_id integer NOT NULL,
    user_name text,
    user_email character varying(255),
    user_password text,
    user_type_id integer,
    created timestamp with time zone DEFAULT now(),
    user_active smallint DEFAULT 1
);


ALTER TABLE public."Users" OWNER TO sifids_w;

--
-- Name: Users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Users_user_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Users_user_id_seq" OWNER TO sifids_w;

--
-- Name: Users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Users_user_id_seq" OWNED BY public."Users".user_id;


--
-- Name: VesselOwners; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."VesselOwners" (
    owner_id integer NOT NULL,
    owner_name text,
    owner_address text
);


ALTER TABLE public."VesselOwners" OWNER TO sifids_w;

--
-- Name: VesselOwners_owner_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."VesselOwners_owner_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."VesselOwners_owner_id_seq" OWNER TO sifids_w;

--
-- Name: VesselOwners_owner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."VesselOwners_owner_id_seq" OWNED BY public."VesselOwners".owner_id;


--
-- Name: VesselProjects; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."VesselProjects" (
    vessel_id integer,
    project_id integer
);


ALTER TABLE public."VesselProjects" OWNER TO sifids_w;

--
-- Name: Vessels; Type: TABLE; Schema: public; Owner: sifids_w
--

CREATE TABLE public."Vessels" (
    vessel_id integer NOT NULL,
    vessel_name text,
    vessel_code character varying(32),
    vessel_pln character varying(16),
    owner_id integer,
    fo_id integer,
    created timestamp with time zone DEFAULT now(),
    vessel_active smallint DEFAULT 1
);


ALTER TABLE public."Vessels" OWNER TO sifids_w;

--
-- Name: Vessels_vessel_id_seq; Type: SEQUENCE; Schema: public; Owner: sifids_w
--

CREATE SEQUENCE public."Vessels_vessel_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Vessels_vessel_id_seq" OWNER TO sifids_w;

--
-- Name: Vessels_vessel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sifids_w
--

ALTER SEQUENCE public."Vessels_vessel_id_seq" OWNED BY public."Vessels".vessel_id;


--
-- Name: Grids grid_id; Type: DEFAULT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."Grids" ALTER COLUMN grid_id SET DEFAULT nextval('analysis."Grids_grid_id_seq"'::regclass);


--
-- Name: Activities activity_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Activities" ALTER COLUMN activity_id SET DEFAULT nextval('entities."Activities_activity_id_seq"'::regclass);


--
-- Name: Animals animal_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Animals" ALTER COLUMN animal_id SET DEFAULT nextval('entities."Animals_animal_id_seq"'::regclass);


--
-- Name: AttributeTypes attribute_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."AttributeTypes" ALTER COLUMN attribute_id SET DEFAULT nextval('entities."AttributeTypes_attribute_id_seq"'::regclass);


--
-- Name: DeviceModels model_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."DeviceModels" ALTER COLUMN model_id SET DEFAULT nextval('entities."DeviceModels_model_id_seq"'::regclass);


--
-- Name: DevicePower devce_power_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."DevicePower" ALTER COLUMN devce_power_id SET DEFAULT nextval('entities."DevicePower_devce_power_id_seq"'::regclass);


--
-- Name: EstimateTypes estimate_type_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."EstimateTypes" ALTER COLUMN estimate_type_id SET DEFAULT nextval('entities."EstimateTypes_estimate_type_id_seq"'::regclass);


--
-- Name: FisheryOffices fo_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."FisheryOffices" ALTER COLUMN fo_id SET DEFAULT nextval('entities."FisheryOffices_fo_id_seq"'::regclass);


--
-- Name: Gears gear_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Gears" ALTER COLUMN gear_id SET DEFAULT nextval('entities."Gears_gear_id_seq"'::regclass);


--
-- Name: IcesRectangles ices_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."IcesRectangles" ALTER COLUMN ices_id SET DEFAULT nextval('entities."IcesRectangles_ices_id_seq"'::regclass);


--
-- Name: Ports port_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Ports" ALTER COLUMN port_id SET DEFAULT nextval('entities."Ports_port_id_seq"'::regclass);


--
-- Name: Presentations presentation_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Presentations" ALTER COLUMN presentation_id SET DEFAULT nextval('entities."Presentations_presentation_id_seq"'::regclass);


--
-- Name: Projects project_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Projects" ALTER COLUMN project_id SET DEFAULT nextval('entities."Projects_project_id_seq"'::regclass);


--
-- Name: Protocols protocol_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Protocols" ALTER COLUMN protocol_id SET DEFAULT nextval('entities."Protocols_protocol_id_seq"'::regclass);


--
-- Name: States state_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."States" ALTER COLUMN state_id SET DEFAULT nextval('entities."States_state_id_seq"'::regclass);


--
-- Name: UserTypes user_type_id; Type: DEFAULT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."UserTypes" ALTER COLUMN user_type_id SET DEFAULT nextval('entities."UserTypes_user_type_id_seq"'::regclass);


--
-- Name: Headers header_id; Type: DEFAULT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Headers" ALTER COLUMN header_id SET DEFAULT nextval('fish1."Headers_header_id_seq"'::regclass);


--
-- Name: WeeklyEffort weekly_effort_id; Type: DEFAULT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffort" ALTER COLUMN weekly_effort_id SET DEFAULT nextval('fish1."WeeklyEffort_weekly_effort_id_seq"'::regclass);


--
-- Name: MPAs mpa_id; Type: DEFAULT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography."MPAs" ALTER COLUMN mpa_id SET DEFAULT nextval('geography."MPAs_mpa_id_seq"'::regclass);


--
-- Name: bathymetry gid; Type: DEFAULT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography.bathymetry ALTER COLUMN gid SET DEFAULT nextval('geography.bathymetry_gid_seq'::regclass);


--
-- Name: scotlandmap2 gid; Type: DEFAULT; Schema: geography; Owner: postgres
--

ALTER TABLE ONLY geography.scotlandmap2 ALTER COLUMN gid SET DEFAULT nextval('geography.scotlandmap2_gid_seq'::regclass);


--
-- Name: Devices device_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices" ALTER COLUMN device_id SET DEFAULT nextval('public."Devices_device_id_seq"'::regclass);


--
-- Name: Tracks track_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Tracks" ALTER COLUMN track_id SET DEFAULT nextval('public."Tracks_track_id_seq"'::regclass);


--
-- Name: Trips trip_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Trips" ALTER COLUMN trip_id SET DEFAULT nextval('public."Trips_trip_id_seq"'::regclass);


--
-- Name: Uploads upload_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Uploads" ALTER COLUMN upload_id SET DEFAULT nextval('public."Uploads_upload_id_seq"'::regclass);


--
-- Name: Users user_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Users" ALTER COLUMN user_id SET DEFAULT nextval('public."Users_user_id_seq"'::regclass);


--
-- Name: VesselOwners owner_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."VesselOwners" ALTER COLUMN owner_id SET DEFAULT nextval('public."VesselOwners_owner_id_seq"'::regclass);


--
-- Name: Vessels vessel_id; Type: DEFAULT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Vessels" ALTER COLUMN vessel_id SET DEFAULT nextval('public."Vessels_vessel_id_seq"'::regclass);


--
-- Name: TrackAnalysis Analysis_pk; Type: CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."TrackAnalysis"
    ADD CONSTRAINT "Analysis_pk" PRIMARY KEY (track_id);


--
-- Name: Estimates Estimates_pk; Type: CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."Estimates"
    ADD CONSTRAINT "Estimates_pk" PRIMARY KEY (trip_id, estimate_type_id);


--
-- Name: Grids Grids_pk; Type: CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."Grids"
    ADD CONSTRAINT "Grids_pk" PRIMARY KEY (grid_id);


--
-- Name: Activities Activities_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Activities"
    ADD CONSTRAINT "Activities_pk" PRIMARY KEY (activity_id);


--
-- Name: Animals Animals_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Animals"
    ADD CONSTRAINT "Animals_pk" PRIMARY KEY (animal_id);


--
-- Name: AttributeTypes AttributeTypes_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."AttributeTypes"
    ADD CONSTRAINT "AttributeTypes_pk" PRIMARY KEY (attribute_id);


--
-- Name: DeviceModels DeviceModels_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."DeviceModels"
    ADD CONSTRAINT "DeviceModels_pk" PRIMARY KEY (model_id);


--
-- Name: DevicePower DevicePower_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."DevicePower"
    ADD CONSTRAINT "DevicePower_pk" PRIMARY KEY (devce_power_id);


--
-- Name: EstimateTypes EstimateTypes_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."EstimateTypes"
    ADD CONSTRAINT "EstimateTypes_pk" PRIMARY KEY (estimate_type_id);


--
-- Name: Gears Gears_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Gears"
    ADD CONSTRAINT "Gears_pk" PRIMARY KEY (gear_id);


--
-- Name: IcesRectangles IcesRectangles_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."IcesRectangles"
    ADD CONSTRAINT "IcesRectangles_pk" PRIMARY KEY (ices_id);


--
-- Name: Presentations Presentations_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Presentations"
    ADD CONSTRAINT "Presentations_pk" PRIMARY KEY (presentation_id);


--
-- Name: Projects Projects_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Projects"
    ADD CONSTRAINT "Projects_pk" PRIMARY KEY (project_id);


--
-- Name: Protocols Protocols_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Protocols"
    ADD CONSTRAINT "Protocols_pk" PRIMARY KEY (protocol_id);


--
-- Name: States States_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."States"
    ADD CONSTRAINT "States_pk" PRIMARY KEY (state_id);


--
-- Name: UserTypes UserTypes_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."UserTypes"
    ADD CONSTRAINT "UserTypes_pk" PRIMARY KEY (user_type_id);


--
-- Name: FisheryOffices fishery_office_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."FisheryOffices"
    ADD CONSTRAINT fishery_office_pk PRIMARY KEY (fo_id);


--
-- Name: Ports ports_pk; Type: CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Ports"
    ADD CONSTRAINT ports_pk PRIMARY KEY (port_id);


--
-- Name: Headers Headers_pk; Type: CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Headers"
    ADD CONSTRAINT "Headers_pk" PRIMARY KEY (header_id);


--
-- Name: WeeklyEffortSpecies WeeklyEffortSpecies_pk; Type: CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffortSpecies"
    ADD CONSTRAINT "WeeklyEffortSpecies_pk" PRIMARY KEY (weekly_effort_id, animal_id);


--
-- Name: WeeklyEffort WeeklyEffort_pk; Type: CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffort"
    ADD CONSTRAINT "WeeklyEffort_pk" PRIMARY KEY (weekly_effort_id);


--
-- Name: MPAs MPAs_pk; Type: CONSTRAINT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography."MPAs"
    ADD CONSTRAINT "MPAs_pk" PRIMARY KEY (mpa_id);


--
-- Name: bathymetry bathymetry_pkey; Type: CONSTRAINT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography.bathymetry
    ADD CONSTRAINT bathymetry_pkey PRIMARY KEY (gid);


--
-- Name: scotlandmap2 scotlandmap2_pkey; Type: CONSTRAINT; Schema: geography; Owner: postgres
--

ALTER TABLE ONLY geography.scotlandmap2
    ADD CONSTRAINT scotlandmap2_pkey PRIMARY KEY (gid);


--
-- Name: Attributes Attributes_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Attributes"
    ADD CONSTRAINT "Attributes_pk" PRIMARY KEY (attribute_id, device_id, time_stamp);


--
-- Name: Devices Devices_device_name; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_device_name" UNIQUE (device_name, vessel_id);


--
-- Name: Devices Devices_device_string; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_device_string" UNIQUE (device_string, vessel_id);


--
-- Name: Devices Devices_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_pk" PRIMARY KEY (device_id);


--
-- Name: Devices Devices_serial_number; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_serial_number" UNIQUE (serial_number, vessel_id);


--
-- Name: Devices Devices_telephone; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_telephone" UNIQUE (telephone, vessel_id);


--
-- Name: Tracks Tracks_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Tracks"
    ADD CONSTRAINT "Tracks_pk" PRIMARY KEY (track_id);


--
-- Name: Trips Trips_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Trips"
    ADD CONSTRAINT "Trips_pk" PRIMARY KEY (trip_id);


--
-- Name: Uploads Uploads_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Uploads"
    ADD CONSTRAINT "Uploads_pk" PRIMARY KEY (upload_id);


--
-- Name: UserVessels UserVessels_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserVessels"
    ADD CONSTRAINT "UserVessels_pk" PRIMARY KEY (user_id, vessel_id);


--
-- Name: Users Users_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pk" PRIMARY KEY (user_id);


--
-- Name: Vessels Vessels_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Vessels"
    ADD CONSTRAINT "Vessels_pk" PRIMARY KEY (vessel_id);


--
-- Name: VesselOwners vessel_owners_pk; Type: CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."VesselOwners"
    ADD CONSTRAINT vessel_owners_pk PRIMARY KEY (owner_id);


--
-- Name: Tracks_trip_id_is_valid_idx; Type: INDEX; Schema: public; Owner: sifids_w
--

CREATE INDEX "Tracks_trip_id_is_valid_idx" ON public."Tracks" USING btree (trip_id, is_valid);


--
-- Name: Trips_trip_device_date_idx; Type: INDEX; Schema: public; Owner: sifids_w
--

CREATE INDEX "Trips_trip_device_date_idx" ON public."Trips" USING btree (trip_id, device_id, trip_date);


--
-- Name: Users_username_idx; Type: INDEX; Schema: public; Owner: sifids_w
--

CREATE UNIQUE INDEX "Users_username_idx" ON public."Users" USING btree (user_name);


--
-- Name: Vessels_vessel_code_idx; Type: INDEX; Schema: public; Owner: sifids_w
--

CREATE UNIQUE INDEX "Vessels_vessel_code_idx" ON public."Vessels" USING btree (vessel_code);


--
-- Name: Vessels_vessel_pln_idx; Type: INDEX; Schema: public; Owner: sifids_w
--

CREATE UNIQUE INDEX "Vessels_vessel_pln_idx" ON public."Vessels" USING btree (vessel_pln);


--
-- Name: TrackAnalysis Analysis_activity_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."TrackAnalysis"
    ADD CONSTRAINT "Analysis_activity_id" FOREIGN KEY (activity_id) REFERENCES entities."Activities"(activity_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TrackAnalysis Analysis_grid_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."TrackAnalysis"
    ADD CONSTRAINT "Analysis_grid_id" FOREIGN KEY (grid_id) REFERENCES analysis."Grids"(grid_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TrackAnalysis Analysis_track_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."TrackAnalysis"
    ADD CONSTRAINT "Analysis_track_id" FOREIGN KEY (track_id) REFERENCES public."Tracks"(track_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Estimates Estimates_estimate_type_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."Estimates"
    ADD CONSTRAINT "Estimates_estimate_type_id" FOREIGN KEY (estimate_type_id) REFERENCES entities."EstimateTypes"(estimate_type_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Estimates Estimates_trip_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."Estimates"
    ADD CONSTRAINT "Estimates_trip_id" FOREIGN KEY (trip_id) REFERENCES public."Trips"(trip_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: FishingEvents FishingEvents_activity_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."FishingEvents"
    ADD CONSTRAINT "FishingEvents_activity_id" FOREIGN KEY (activity_id) REFERENCES entities."Activities"(activity_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: FishingEvents FishingEvents_track_id; Type: FK CONSTRAINT; Schema: analysis; Owner: sifids_w
--

ALTER TABLE ONLY analysis."FishingEvents"
    ADD CONSTRAINT "FishingEvents_track_id" FOREIGN KEY (track_id) REFERENCES public."Tracks"(track_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Animals Animals_subclass_of; Type: FK CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."Animals"
    ADD CONSTRAINT "Animals_subclass_of" FOREIGN KEY (subclass_of) REFERENCES entities."Animals"(animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DeviceModels DeviceModel_protocol_id; Type: FK CONSTRAINT; Schema: entities; Owner: sifids_w
--

ALTER TABLE ONLY entities."DeviceModels"
    ADD CONSTRAINT "DeviceModel_protocol_id" FOREIGN KEY (protocol_id) REFERENCES entities."Protocols"(protocol_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Rows Rows_animal_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_animal_id" FOREIGN KEY (animal_id) REFERENCES entities."Animals"(animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Rows Rows_gear_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_gear_id" FOREIGN KEY (gear_id) REFERENCES entities."Gears"(gear_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Rows Rows_header_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_header_id" FOREIGN KEY (header_id) REFERENCES fish1."Headers"(header_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Rows Rows_ices_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_ices_id" FOREIGN KEY (ices_id) REFERENCES entities."IcesRectangles"(ices_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Headers Rows_port_of_departure_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Headers"
    ADD CONSTRAINT "Rows_port_of_departure_id" FOREIGN KEY (port_of_departure_id) REFERENCES entities."Ports"(port_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Headers Rows_port_of_landing_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Headers"
    ADD CONSTRAINT "Rows_port_of_landing_id" FOREIGN KEY (port_of_landing_id) REFERENCES entities."Ports"(port_id) MATCH FULL;


--
-- Name: Rows Rows_presentation_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_presentation_id" FOREIGN KEY (presentation_id) REFERENCES entities."Presentations"(presentation_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Rows Rows_state_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Rows"
    ADD CONSTRAINT "Rows_state_id" FOREIGN KEY (state_id) REFERENCES entities."States"(state_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Headers Rows_upload_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."Headers"
    ADD CONSTRAINT "Rows_upload_id" FOREIGN KEY (upload_id) REFERENCES public."Uploads"(upload_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: WeeklyEffortSpecies WeeklyEffortSpecies_animal_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffortSpecies"
    ADD CONSTRAINT "WeeklyEffortSpecies_animal_id" FOREIGN KEY (animal_id) REFERENCES entities."Animals"(animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: WeeklyEffortSpecies WeeklyEffortSpecies_weekly_effort_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffortSpecies"
    ADD CONSTRAINT "WeeklyEffortSpecies_weekly_effort_id" FOREIGN KEY (weekly_effort_id) REFERENCES fish1."WeeklyEffort"(weekly_effort_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: WeeklyEffort WeeklyEffort_vessel_id; Type: FK CONSTRAINT; Schema: fish1; Owner: sifids_w
--

ALTER TABLE ONLY fish1."WeeklyEffort"
    ADD CONSTRAINT "WeeklyEffort_vessel_id" FOREIGN KEY (vessel_id) REFERENCES public."Vessels"(vessel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Observations Observations_animal_id; Type: FK CONSTRAINT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography."Observations"
    ADD CONSTRAINT "Observations_animal_id" FOREIGN KEY (animal_id) REFERENCES entities."Animals"(animal_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Observations Observations_upload_id; Type: FK CONSTRAINT; Schema: geography; Owner: sifids_w
--

ALTER TABLE ONLY geography."Observations"
    ADD CONSTRAINT "Observations_upload_id" FOREIGN KEY (upload_id) REFERENCES public."Uploads"(upload_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Attributes Attribute_attribute_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Attributes"
    ADD CONSTRAINT "Attribute_attribute_id" FOREIGN KEY (attribute_id) REFERENCES entities."AttributeTypes"(attribute_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Attributes Attribute_device_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Attributes"
    ADD CONSTRAINT "Attribute_device_id" FOREIGN KEY (device_id) REFERENCES public."Devices"(device_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Devices Devices_device_power_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_device_power_id" FOREIGN KEY (device_power_id) REFERENCES entities."DevicePower"(devce_power_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Devices Devices_model_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_model_id" FOREIGN KEY (model_id) REFERENCES entities."DeviceModels"(model_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Devices Devices_vessel_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Devices"
    ADD CONSTRAINT "Devices_vessel_id" FOREIGN KEY (vessel_id) REFERENCES public."Vessels"(vessel_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Tracks Tracks_trip_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Tracks"
    ADD CONSTRAINT "Tracks_trip_id" FOREIGN KEY (trip_id) REFERENCES public."Trips"(trip_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Trips Trips_device_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Trips"
    ADD CONSTRAINT "Trips_device_id" FOREIGN KEY (device_id) REFERENCES public."Devices"(device_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Uploads Uploads_device_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Uploads"
    ADD CONSTRAINT "Uploads_device_id" FOREIGN KEY (device_id) REFERENCES public."Devices"(device_id) MATCH FULL;


--
-- Name: UserFisheryOffices UserFisheryOffices_fo_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserFisheryOffices"
    ADD CONSTRAINT "UserFisheryOffices_fo_id" FOREIGN KEY (fo_id) REFERENCES entities."FisheryOffices"(fo_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserFisheryOffices UserFisheryOffices_user_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserFisheryOffices"
    ADD CONSTRAINT "UserFisheryOffices_user_id" FOREIGN KEY (user_id) REFERENCES public."Users"(user_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserProjects UserProjects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserProjects"
    ADD CONSTRAINT "UserProjects_project_id" FOREIGN KEY (project_id) REFERENCES entities."Projects"(project_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: UserProjects UserProjects_user_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserProjects"
    ADD CONSTRAINT "UserProjects_user_id" FOREIGN KEY (user_id) REFERENCES public."Users"(user_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserVessels UserVessels_user_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserVessels"
    ADD CONSTRAINT "UserVessels_user_id" FOREIGN KEY (user_id) REFERENCES public."Users"(user_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserVessels UserVessels_vessel_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."UserVessels"
    ADD CONSTRAINT "UserVessels_vessel_id" FOREIGN KEY (vessel_id) REFERENCES public."Vessels"(vessel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Users Users_user_type_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_user_type_id" FOREIGN KEY (user_type_id) REFERENCES entities."UserTypes"(user_type_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: VesselProjects VesselProjects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."VesselProjects"
    ADD CONSTRAINT "VesselProjects_project_id" FOREIGN KEY (project_id) REFERENCES entities."Projects"(project_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: VesselProjects VesselProjects_vessel_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."VesselProjects"
    ADD CONSTRAINT "VesselProjects_vessel_id" FOREIGN KEY (vessel_id) REFERENCES public."Vessels"(vessel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Vessels Vessels_fo_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Vessels"
    ADD CONSTRAINT "Vessels_fo_id" FOREIGN KEY (fo_id) REFERENCES entities."FisheryOffices"(fo_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Vessels Vessels_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: sifids_w
--

ALTER TABLE ONLY public."Vessels"
    ADD CONSTRAINT "Vessels_owner_id" FOREIGN KEY (owner_id) REFERENCES public."VesselOwners"(owner_id) MATCH FULL ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: FUNCTION gettripsfortania(in_trip_id integer); Type: ACL; Schema: public; Owner: sifids_w
--

GRANT ALL ON FUNCTION public.gettripsfortania(in_trip_id integer) TO tania;


--
-- Name: TABLE scotlandmap2; Type: ACL; Schema: geography; Owner: postgres
--

GRANT SELECT ON TABLE geography.scotlandmap2 TO sifids_w;


--
-- Name: TABLE "Attributes"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Attributes" TO tania;


--
-- Name: TABLE "Devices"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Devices" TO tania;


--
-- Name: TABLE "Tracks"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Tracks" TO tania;


--
-- Name: TABLE "Trips"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Trips" TO tania;


--
-- Name: TABLE "Uploads"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Uploads" TO tania;


--
-- Name: TABLE "UserFisheryOffices"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."UserFisheryOffices" TO tania;


--
-- Name: TABLE "UserProjects"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."UserProjects" TO tania;


--
-- Name: TABLE "UserVessels"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."UserVessels" TO tania;


--
-- Name: TABLE "Users"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Users" TO tania;


--
-- Name: TABLE "VesselOwners"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."VesselOwners" TO tania;


--
-- Name: TABLE "VesselProjects"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."VesselProjects" TO tania;


--
-- Name: TABLE "Vessels"; Type: ACL; Schema: public; Owner: sifids_w
--

GRANT SELECT ON TABLE public."Vessels" TO tania;


--
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.geography_columns TO tania;


--
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.geometry_columns TO tania;


--
-- Name: TABLE raster_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.raster_columns TO tania;


--
-- Name: TABLE raster_overviews; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.raster_overviews TO tania;


--
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.spatial_ref_sys TO tania;


--
-- PostgreSQL database dump complete
--

