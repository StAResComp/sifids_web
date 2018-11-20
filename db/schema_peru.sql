-- -*- pgsql -*-

-- need new schema
CREATE SCHEMA IF NOT EXISTS peru;

SET SCHEMA 'peru';

-- reuse schema document from main instance
\include schema_common.sql

-- different observation tables
\include schema_observations_peru.sql

-- reuse consent table
\include schema_consent.sql

-- form
\include schema_form_peru.sql