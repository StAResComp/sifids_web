-- https://stackoverflow.com/questions/47162200/pbkdf2-function-in-postgresql

-- PBKDF2 function to use Django's user credentials table
CREATE OR REPLACE FUNCTION PBKDF2 (
  salt BYTEA, 
  pw TEXT, 
  count INTEGER, 
  desired_length INTEGER, 
  algorithm TEXT
)
RETURNS bytea
AS $FUNC$
  DECLARE 
    hash_length INTEGER;
    block_count INTEGER;
    output BYTEA;
    the_last BYTEA;
    xorsum BYTEA;
    i_as_int32 BYTEA;
    i INTEGER;
    j INTEGER;
    k INTEGER;
BEGIN
  algorithm := LOWER(algorithm);
  CASE algorithm
    WHEN 'md5' THEN
      hash_length := 16;
    WHEN 'sha1' THEN
      hash_length = 20;
    WHEN 'sha256' THEN
      hash_length = 32;
    WHEN 'sha512' THEN
      hash_length = 64;
  ELSE
    RAISE EXCEPTION 'Unknown algorithm "%"', algorithm;
  END CASE;

  block_count := CEIL(desired_length::REAL / hash_length::REAL);

  FOR i IN 1 .. block_count LOOP
    i_as_int32 := E'\\000\\000\\000'::BYTEA || CHR(i)::BYTEA;
    i_as_int32 := SUBSTRING(i_as_int32, LENGTH(i_as_int32) - 3);
    
    the_last := salt::BYTEA || i_as_int32;
    
    xorsum := HMAC(the_last, pw::BYTEA, algorithm);
    the_last := xorsum;
    
    FOR j IN 2 .. count LOOP
      the_last := HMAC(the_last, pw::BYTEA, algorithm);
      
      --
      -- xor the two
      --
      FOR k IN 1 .. LENGTH(xorsum) LOOP
        xorsum := SET_BYTE(xorsum, k - 1, GET_BYTE(xorsum, k - 1) # GET_BYTE(the_last, k - 1));
      END LOOP;
    END LOOP;
    
    IF output IS NULL THEN
      output := xorsum;
    ELSE
      output := output || xorsum;
    END IF;
  END LOOP;
  
  RETURN SUBSTRING(output FROM 1 FOR desired_length);
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER IMMUTABLE;

-- function to compare given password with django record
CREATE OR REPLACE FUNCTION pescarLogin(
  in_username TEXT, -- name of user
  in_password TEXT -- plaintext password
)
RETURNS BOOLEAN
AS $FUNC$
  DECLARE
    password_field TEXT;
    algorithm TEXT;
    iterations INTEGER;
    salt TEXT;
    enc_password TEXT;
    desired_length INTEGER;
BEGIN
  -- get password data from django
  SELECT password 
    INTO password_field
    FROM auth_user
   WHERE username = in_username;
  
  -- make sure something was found
  IF password_field IS NULL THEN
    RETURN 1 <> 1;
  END IF;
  
  -- extract information from django password field
  algorithm := SUBSTRING(SPLIT_PART(password_field, '$', 1) FROM 8);
  iterations := SPLIT_PART(password_field, '$', 2)::INTEGER;
  salt := SPLIT_PART(password_field, '$', 3);
  enc_password := SPLIT_PART(password_field, '$', 4);
  
  -- get length of decoded (but encrypted) password
  desired_length := LENGTH(DECODE(enc_password, 'base64'));

  -- return comparison of encrypted passwords
  RETURN enc_password = ENCODE(PBKDF2(salt::BYTEA, in_password, iterations, desired_length, algorithm), 'base64');
END;
$FUNC$ LANGUAGE plpgsql SECURITY DEFINER IMMUTABLE;