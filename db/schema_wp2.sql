-- tables to hold subsection of data from WP2 database

/*DROP TABLE IF EXISTS incoming_sessions;
CREATE TABLE incoming_sessions (
  vessel_sessionid VARCHAR(10),
  pooled_vesselid VARCHAR(255),
  vessel_creationtimestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  pooled_vesseltrackpoints BIGINT,
  PRIMARY KEY (vessel_sessionid)
);

-- speed up selects of sessions using timestamp and number of track points
CREATE INDEX session_idx ON incoming_sessions (vessel_creationtimestamp, pooled_vesseltrackpoints);

DROP TABLE IF EXISTS incoming_primarygnss;
CREATE TABLE incoming_primarygnss (
  vessel_sessionid VARCHAR(10) REFERENCES incoming_sessions(vessel_sessionid) ON DELETE CASCADE,
  vessel_latitude NUMERIC(15,12),
  vessel_longitude NUMERIC(15,12),
  vessel_servertimestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  pooled_anomalousrecord BOOLEAN
);

-- speed up selects of tracks using session
CREATE INDEX gnss_session_idx ON incoming_primarygnss (vessel_sessionid);
*/
-- get list of sessions per vessel where the session is between the given dates
-- and has a minimum number of points
CREATE OR REPLACE FUNCTION GimmeSessions ( --{{{
  in_from TIMESTAMP WITH TIME ZONE,
  in_to TIMESTAMP WITH TIME ZONE,
  in_min_tracks BIGINT,
  in_min_sessions INTEGER
)
RETURNS TABLE (
  vesselid VARCHAR(255),
  session_count BIGINT,
  sessions TEXT
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT pooled_vesselid AS vesselid, COUNT(*) AS session_count, STRING_AGG(vessel_sessionid, ' ') AS sessions
      FROM incoming_sessions
     WHERE vessel_creationtimestamp BETWEEN in_from AND in_to
       AND pooled_vesseltrackpoints >= in_min_tracks
  GROUP BY pooled_vesselid
    HAVING COUNT(*) >= in_min_sessions
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

CREATE OR REPLACE FUNCTION GimmeTracks ( --{{{
  in_vessel_sessionid VARCHAR(10)
)
RETURNS TABLE (
  vesselid VARCHAR(255),
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  servertimestamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT pooled_vesselid, vessel_latitude, vessel_longitude, vessel_servertimestamp
      FROM incoming_primarygnss 
INNER JOIN incoming_sessions USING (vessel_sessionid)
     WHERE pooled_anomalousrecord IS NULL
       AND vessel_sessionid = in_vessel_sessionid
  ORDER BY vessel_servertimestamp
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}

CREATE OR REPLACE FUNCTION GimmeTracks ( --{{{
  in_from TIMESTAMP WITH TIME ZONE,
  in_to TIMESTAMP WITH TIME ZONE,
  in_min_tracks BIGINT,
  in_min_sessions INTEGER
)
RETURNS TABLE (
  vesselid VARCHAR(255),
  sessionid VARCHAR(10),
  latitude NUMERIC(15,12),
  longitude NUMERIC(15,12),
  servertimestamp TIMESTAMP WITH TIME ZONE
)
AS $FUNC$
BEGIN
  RETURN QUERY
    SELECT pooled_vesselid, vessel_sessionid, vessel_latitude, vessel_longitude, vessel_servertimestamp
      FROM incoming_primarygnss 
INNER JOIN (SELECT pooled_vesselid, UNNEST(ARRAY_AGG(vessel_sessionid)) AS vessel_sessionid
              FROM incoming_sessions
             WHERE vessel_creationtimestamp BETWEEN in_from AND in_to
               AND pooled_vesseltrackpoints >= in_min_tracks
          GROUP BY pooled_vesselid
            HAVING COUNT(*) >= in_min_sessions) AS s USING (vessel_sessionid)
     WHERE pooled_anomalousrecord IS NULL
  ORDER BY vessel_sessionid, vessel_servertimestamp
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
