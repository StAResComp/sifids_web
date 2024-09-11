-- stored procedures for helping with automated analysis of tracks to predict hauling behaviour

-- get track data for trips on given date
CREATE OR REPLACE FUNCTION tracksForAnalysis ( --{{{
  in_date DATE,
  in_obvs INTEGER, -- need more observations than this
  in_meters INTEGER, -- need trip to be longer (in meters) than this
  in_time INTEGER -- need trip to be longer (in seconds) than this
)
RETURNS TABLE (
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    -- CTE for getting start and stop times for vessel leaving 200m buffer per trip
    -- https://stackoverflow.com/questions/10614505/window-functions-and-more-local-aggregation/10624628#10624628
    WITH minmax AS (
      SELECT t.trip_id, 
             MIN(t.time_stamp) AS start, 
             MAX(t.time_stamp) AS stop
        FROM "Tracks" AS t
  INNER JOIN "Trips" USING (trip_id)
       WHERE trip_date = in_date
         AND NOT EXISTS ( -- points outside 200m buffer
               SELECT 1
                 FROM geography.scotlandmap2
                WHERE ST_Contains(buffer_200, ST_SetSRID(ST_MakePoint(t.longitude, t.latitude), 4326)))
       GROUP BY t.trip_id
    )
    SELECT DISTINCT t3.latitude,
                    t3.longitude, 
                    t3.time_stamp, 
                    t3.trip_id
               FROM (SELECT t2.latitude,
                            t2.longitude,
                            MIN(t2.time_stamp) OVER (PARTITION BY group_nr) AS time_stamp, -- get first time stamp for consecutive identical points
                            t2.trip_id,
                            obvs,
                            MAX(t2.meters) OVER (PARTITION BY t2.trip_id) AS meters, -- length of each trip in meters
                            MIN(t2.time_stamp) OVER (PARTITION BY t2.trip_id) AS start_time, -- start time of trip
                            MAX(t2.time_stamp) OVER (PARTITION BY t2.trip_id) AS end_time -- end time of trip
                       FROM (SELECT *, 
                                    SUM(group_flag) OVER (ORDER BY t1.trip_id, t1.time_stamp, t1.point) AS group_nr, -- get unique group number for consecutive identical points
                                    COUNT(*) OVER (PARTITION BY t1.trip_id) AS obvs, -- get number of observations per trip
                                    ST_Length(ST_MakeLine(t1.point) OVER (PARTITION BY t1.trip_id ORDER BY t1.trip_id, t1.time_stamp)::geography) AS meters
                               FROM (SELECT *, 
                                            ST_MakePoint(t.longitude, t.latitude) AS point,
                                            -- when previous point is same as current, select NULL, else 1
                                            CASE WHEN LAG(ST_MakePoint(t.longitude, t.latitude)) OVER (ORDER BY t.trip_id, t.time_stamp) = ST_MakePoint(t.longitude, t.latitude) THEN NULL
                                                 ELSE 1
                                            END AS group_flag
                                       FROM "Tracks" AS t
                                 INNER JOIN minmax USING (trip_id) -- join to CTE to filter on points between start and stop times
                                      WHERE t.time_stamp BETWEEN start AND stop
                                        AND t.is_valid = 1
                                        AND t.latitude > 40 -- within Scottish waters
                                        AND t.longitude BETWEEN -8 AND 0
                                        AND NOT EXISTS ( -- outside of 10m buffer
                                              SELECT 1
                                                FROM geography.scotlandmap2
                                               WHERE ST_Contains(buffer_10, ST_SetSRID(ST_MakePoint(t.longitude, t.latitude), 4326))
                                           )
                                   ) AS t1
                            ) AS t2
                    ) AS t3
              WHERE obvs > in_obvs
                AND meters > in_meters
                AND EXTRACT(EPOCH FROM (end_time - start_time)) > in_time
           ORDER BY t3.trip_id, t3.time_stamp ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get track data for trips on given date for given device
CREATE OR REPLACE FUNCTION tracksDeviceForAnalysis ( --{{{
  in_date DATE,
  in_device_id INTEGER,
  in_obvs INTEGER, -- need more observations than this
  in_meters INTEGER, -- need trip to be longer (in meters) than this
  in_time INTEGER -- need trip to be longer (in seconds) than this
)
RETURNS TABLE (
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    -- CTE for getting start and stop times for vessel leaving 200m buffer per trip
    -- https://stackoverflow.com/questions/10614505/window-functions-and-more-local-aggregation/10624628#10624628
    WITH minmax AS (
      SELECT t.trip_id, 
             MIN(t.time_stamp) AS start, 
             MAX(t.time_stamp) AS stop
        FROM "Tracks" AS t
  INNER JOIN "Trips" USING (trip_id)
       WHERE trip_date = in_date
         AND device_id = in_device_id
         AND NOT EXISTS ( -- points outside 200m buffer
               SELECT 1
                 FROM geography.scotlandmap2
                WHERE ST_Contains(buffer_200, ST_SetSRID(ST_MakePoint(t.longitude, t.latitude), 4326)))
       GROUP BY t.trip_id
    )
    SELECT DISTINCT t3.latitude,
                    t3.longitude, 
                    t3.time_stamp, 
                    t3.trip_id
               FROM (SELECT t2.latitude,
                            t2.longitude,
                            MIN(t2.time_stamp) OVER (PARTITION BY group_nr) AS time_stamp, -- get first time stamp for consecutive identical points
                            t2.trip_id,
                            obvs,
                            MAX(t2.meters) OVER (PARTITION BY t2.trip_id) AS meters, -- length of each trip in meters
                            MIN(t2.time_stamp) OVER (PARTITION BY t2.trip_id) AS start_time, -- start time of trip
                            MAX(t2.time_stamp) OVER (PARTITION BY t2.trip_id) AS end_time -- end time of trip
                       FROM (SELECT *, 
                                    SUM(group_flag) OVER (ORDER BY t1.trip_id, t1.time_stamp, t1.point) AS group_nr, -- get unique group number for consecutive identical points
                                    COUNT(*) OVER (PARTITION BY t1.trip_id) AS obvs, -- get number of observations per trip
                                    ST_Length(ST_MakeLine(t1.point) OVER (PARTITION BY t1.trip_id ORDER BY t1.trip_id, t1.time_stamp)::geography) AS meters
                               FROM (SELECT *, 
                                            ST_MakePoint(t.longitude, t.latitude) AS point,
                                            -- when previous point is same as current, select NULL, else 1
                                            CASE WHEN LAG(ST_MakePoint(t.longitude, t.latitude)) OVER (ORDER BY t.trip_id, t.time_stamp) = ST_MakePoint(t.longitude, t.latitude) THEN NULL
                                                 ELSE 1
                                            END AS group_flag
                                       FROM "Tracks" AS t
                                 INNER JOIN minmax USING (trip_id) -- join to CTE to filter on points between start and stop times
                                      WHERE t.time_stamp BETWEEN start AND stop
                                        AND t.is_valid = 1
                                        AND t.latitude > 40 -- within Scottish waters
                                        AND t.longitude BETWEEN -8 AND 0
                                        AND NOT EXISTS ( -- outside of 10m buffer
                                              SELECT 1
                                                FROM geography.scotlandmap2
                                               WHERE ST_Contains(buffer_10, ST_SetSRID(ST_MakePoint(t.longitude, t.latitude), 4326))
                                           )
                                   ) AS t1
                            ) AS t2
                    ) AS t3
              WHERE obvs > in_obvs
                AND meters > in_meters
                AND EXTRACT(EPOCH FROM (end_time - start_time)) > in_time
           ORDER BY t3.trip_id, t3.time_stamp ASC
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- get vessel data for trips on given date
CREATE OR REPLACE FUNCTION vesselsForAnalysis ( --{{{
  in_date DATE
)
RETURNS TABLE (
  trip_id INTEGER,
  id VARCHAR(32),
  vessel_id INTEGER,
  vessel_pln VARCHAR(16),
  vessel_name TEXT,
  vessel_length NUMERIC(6,3),
  gear_name VARCHAR(32),
  animal_code VARCHAR(16)
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.trip_id, 
           CONCAT(t.trip_id, t.trip_date)::VARCHAR(32), 
           v.vessel_id, v.vessel_pln, v.vessel_name, v.vessel_length,
           g.gear_name, a.animal_code
      FROM "Trips" AS t
INNER JOIN "Devices" AS d USING (device_id)
INNER JOIN "Vessels" AS v ON d.vessel_id = v.vessel_id
INNER JOIN entities."Gears" AS g USING (gear_id)
INNER JOIN entities."Animals" AS a USING (animal_id)
     WHERE t.trip_date = in_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- update analysis by adding grid IDs
CREATE OR REPLACE FUNCTION addSegmentAnalysis ( --{{{
  in_trip_id INTEGER,
  in_grid_size INTEGER
)
RETURNS TABLE (
  updated INTEGER
)
AS $FUNC$
  DECLARE updated INTEGER;
BEGIN
  UPDATE analysis."TrackAnalysis"
     SET grid_id = r4.grid_id
    FROM (SELECT track_id,
                 CASE WHEN MIN(time_stamp) OVER (PARTITION by group_nr) = time_stamp THEN grid_id
                      ELSE NULL
                 END AS grid_id
            FROM (SELECT track_id, grid_id, time_stamp,
                         SUM(group_flag) OVER (ORDER BY time_stamp) AS group_nr
                    FROM (SELECT track_id, grid_id, time_stamp,
                                 CASE WHEN LAG(grid_id) OVER (ORDER BY time_stamp) = grid_id THEN 0
                                      ELSE 1
                                 END AS group_flag
                            FROM (SELECT track_id, time_stamp,
                                         findGridSquare(longitude, latitude, in_grid_size) AS grid_id
                                    FROM analysis."AnalysedTracks"
                              INNER JOIN analysis."TrackAnalysis" USING (track_id)
                                   WHERE trip_id = in_trip_id
                                     AND activity_id = 2
                                 ) AS r1
                         ) AS r2
                 ) AS r3
         ) AS r4
   WHERE analysis."TrackAnalysis".track_id = r4.track_id;
     
  -- find out how many rows updated
  GET DIAGNOSTICS updated = ROW_COUNT;
  
  RETURN QUERY
    SELECT updated;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- find grid containing given point, adding if necessary
CREATE OR REPLACE FUNCTION findGridSquare ( --{{{
  in_longitude NUMERIC(15,12),
  in_latitude NUMERIC(15,12),
  in_grid_size INTEGER
)
RETURNS TABLE (
  grid_id INTEGER
)
AS $FUNC$
  DECLARE x INTEGER;
  DECLARE y INTEGER;
  DECLARE p GEOMETRY;
BEGIN
  
  -- create point for input coordinates
  p := ST_Transform(ST_SetSRID(ST_MakePoint(in_longitude, in_latitude), 4326), 32630);
  x := ST_X(p)::INTEGER;
  y := ST_Y(p)::INTEGER;
  
  -- try to find grid square containing point
  RETURN QUERY
    SELECT g.grid_id
      FROM analysis."Grids" AS g
     WHERE x >= ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(longitude1, latitude1), 4326), 32630))::INTEGER
       AND x <  ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(longitude2, latitude2), 4326), 32630))::INTEGER
       AND y >= ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(longitude1, latitude1), 4326), 32630))::INTEGER
       AND y <  ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(longitude2, latitude2), 4326), 32630))::INTEGER
;
  
  -- grid square not found, so create new grid square containing point
  IF NOT FOUND THEN
    -- find min x/y
    x := x - (x % in_grid_size);
    y := y - (y % in_grid_size);
    
    RETURN QUERY
      INSERT
        INTO analysis."Grids" AS g
             (latitude1, longitude1, latitude2, longitude2)
      SELECT ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(x, y), 32630), 4326)),
             ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(x, y), 32630), 4326)),
             ST_Y(ST_Transform(ST_SetSRID(ST_MakePoint(x + in_grid_size, y + in_grid_size), 32630), 4326)),
             ST_X(ST_Transform(ST_SetSRID(ST_MakePoint(x + in_grid_size, y + in_grid_size), 32630), 4326))
   RETURNING g.grid_id;
  END IF;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- get all track data for date
CREATE OR REPLACE FUNCTION rawDataForDate ( --{{{
  in_date DATE
)
RETURNS TABLE (
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  time_stamp TIMESTAMP WITH TIME ZONE,
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT t.latitude, t.longitude, t.time_stamp, t.trip_id
      FROM "Tracks" AS t
INNER JOIN "Trips" USING (trip_id)
     WHERE trip_date = in_date;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

-- add analysed (not real) track point and record activity
CREATE OR REPLACE FUNCTION addAnalysedTrack ( --{{{
  in_latitude NUMERIC(15,12),
  in_longitude NUMERIC(15,12),
  in_time_stamp TIMESTAMP WITHOUT TIME ZONE,
  in_trip_id INTEGER,
  in_activity INTEGER
)
RETURNS TABLE (
  track_id INTEGER
)
AS $FUNC$
  DECLARE track_id_var INTEGER;
BEGIN
  -- add analysed track point
    INSERT
      INTO analysis."AnalysedTracks" AS t
           (latitude, longitude, time_stamp, trip_id, geog)
    VALUES (in_latitude, in_longitude, in_time_stamp, in_trip_id,
            CAST(ST_SetSRID( ST_Point(in_longitude, in_latitude), 4326) as geography))
 RETURNING t.track_id
      INTO track_id_var;
      
  -- add track ID and activity to track analysis
  INSERT 
    INTO analysis."TrackAnalysis"
         (track_id, activity_id)
  VALUES (track_id_var, in_activity);
  
  RETURN QUERY
    SELECT track_id_var;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add estimated distance for trip
CREATE OR REPLACE FUNCTION addDistanceEstimate ( --{{{
  in_trip_id INTEGER,
  in_distance NUMERIC
)
RETURNS TABLE (
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT
      INTO analysis."Estimates"
           (trip_id, estimate_type_id, estimate_value)
    SELECT in_trip_id, et.estimate_type_id, in_distance
      FROM entities."EstimateTypes" AS et
     WHERE estimate_name = 'distance'
 RETURNING in_trip_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- add creel estimates for trip
CREATE OR REPLACE FUNCTION addCreelEstimates ( --{{{
  in_trip_id INTEGER,
  in_creels NUMERIC,
  in_creels_low NUMERIC,
  in_creels_high NUMERIC
)
RETURNS TABLE (
  trip_id INTEGER
)
AS $FUNC$
BEGIN
  RETURN QUERY
    INSERT
      INTO analysis."Estimates"
           (trip_id, estimate_type_id, estimate_value)
    SELECT in_trip_id, etc.estimate_type_id, in_creels
      FROM entities."EstimateTypes" AS etc
     WHERE etc.estimate_name = 'creels'
     UNION
    SELECT in_trip_id, etcl.estimate_type_id, in_creels_low
      FROM entities."EstimateTypes" AS etcl
     WHERE etcl.estimate_name = 'creels_low'
     UNION
    SELECT in_trip_id, etch.estimate_type_id, in_creels_high
      FROM entities."EstimateTypes" AS etch
     WHERE etch.estimate_name = 'creels_high'
 RETURNING in_trip_id;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete any analysis for given date
CREATE OR REPLACE FUNCTION deleteAnalysis ( --{{{
  in_date DATE
)
RETURNS TABLE (
  deleted BOOLEAN
)
AS $FUNC$
BEGIN
  DELETE
    FROM analysis."AnalysedTracks"
   WHERE trip_id IN (SELECT trip_id
                       FROM "Trips"
                      WHERE trip_date = in_date);
                      
  DELETE
    FROM analysis."Estimates"
   WHERE trip_id IN (SELECT trip_id
                       FROM "Trips"
                      WHERE trip_date = in_date);

  RETURN QUERY
    SELECT FOUND;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}

-- delete any analysis for given date and given device
CREATE OR REPLACE FUNCTION deleteDeviceAnalysis ( --{{{
  in_date DATE,
  in_device_id INTEGER
)
RETURNS TABLE (
  deleted BOOLEAN
)
AS $FUNC$
BEGIN
  DELETE
    FROM analysis."AnalysedTracks"
   WHERE trip_id IN (SELECT trip_id
                       FROM "Trips"
                      WHERE trip_date = in_date
                        AND device_id = in_device_id);
                      
  DELETE
    FROM analysis."Estimates"
   WHERE trip_id IN (SELECT trip_id
                       FROM "Trips"
                      WHERE trip_date = in_date
                        AND device_id = in_device_id);

  RETURN QUERY
    SELECT FOUND;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER VOLATILE;
--}}}
