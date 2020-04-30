-- stored procedures used by Shiny app and indexing functions

/*
-- stored procedure for checking user details
CREATE OR REPLACE FUNCTION  ( --{{{
)
RETURNS TABLE (
)
AS $FUNC$
BEGIN
  RETURN QUERY
    
;
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
--}}}
*/


-- get earliest timestamp of element in array
CREATE OR REPLACE FUNCTION dateStartFunc (
  arr JSONB
)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS $FUNC$
  SELECT MIN((a ->> 'timestamp'))::TIMESTAMP WITHOUT TIME ZONE
    FROM jsonb_array_elements(arr) AS a;
$FUNC$ LANGUAGE sql SECURITY DEFINER IMMUTABLE;

