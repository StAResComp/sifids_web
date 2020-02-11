# Database

The SIFIDS database at St Andrews uses PostgreSQL with PostGIS running on
Debian Linux. Version details as of 11 February 2020:

- PostgreSQL 11.5 (Debian 11.5-1+deb10u1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
- POSTGIS="2.5.1 r17027" [EXTENSION] PGSQL="110" GEOS="3.7.1-CAPI-1.11.1 27a5e771" PROJ="Rel. 5.2.0, September 15th, 2018" GDAL="GDAL 2.4.0, released 2018/12/14" LIBXML="2.9.4" LIBJSON="0.12.1" LIBPROTOBUF="1.3.1" RASTERPOSTGIS="2.5.1 r17027" [EXTENSION] PGSQL="110" GEOS="3.7.1-CAPI-1.11.1 27a5e771" PROJ="Rel. 5.2.0, September 15th, 2018" GDAL="GDAL 2.4.0, released 2018/12/14" LIBXML="2.9.4" LIBJSON="0.12.1" LIBPROTOBUF="1.3.1" RASTER
- Debian 4.19.16-1 (2019-01-17) x86_64

The operation of the database has not been tested to any significant extent
with other software configurations.
A dump of the database schema and functions can be found at
`db/sifids_db_schema.sql`. The functioning of this script has been tested
superficially on a number of versions of PostgreSQL (see
`db/run-in-docker.sh`) and found to execute correctly on PostgreSQL 10 and
11, failing on 9.x. It has not been tested with PostgreSQL 12.

To use `db/sifids_db_schema.sql` you need to:
1. Create a database
2. Create a user called `sifids_w`
3. Run `db/sifids_db_schema.sql` in the database created in step 1. You may see
   errors relating to the absence of a role 'tania'; these can be ignored.

For example, using `psql` with `conninfo` strings (not recommended to put
passwords in strings, but included here for clarity):

```bash
psql -d "host=localhost port=5432 dbname=postgres user=postgres password=[postgres-user-password]" -c "CREATE DATABASE sifids WITH ENCODING = 'UTF8';"
psql -d "host=localhost port=5432 dbname=postgres user=postgres password=[postgres-user-password]" -c "CREATE USER sifids_w WITH PASSWORD '[sifids_w-user-password]';"
psql -d "host=localhost post=5432 dbname=sifids user=postgres password=[postgres-user-password]" -f "/path/to/db/sifids_db_schema.sql"
```
