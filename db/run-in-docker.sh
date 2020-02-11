#!/usr/bin/env bash

# Script takes 1 argument - the tag of the docker image to be used. See
# https://registry.hub.docker.com/r/mdillon/postgis/tags for possible values.
# e.g. ./run-in-docker 11
# e.g. ./run-in-docker 10-alpine
# to run over all available versions of postgres, try:
# versions=("9.1" "9.2" "9.3" "9.4" "9.5" "9.6" "10" "11"); for val in $versions; do ./run-in-docker.sh $val; done

# This script requires docker and should be in the same directory as
# sifids_db_schema.sql

DOCKER_NAME=pg$1
POSTGRES_PW=docker
SIFIDS_DB=sifids
SIFIDS_USER=sifids_w
SIFIDS_USER_PW=sifids
DIR=`dirname "$0"`

conn_string () {
    echo "host=localhost port=5432 dbname=$1 user=postgres password=$POSTGRES_PW"
}

echo "Setting up Postgres $1 using Docker"
docker run --rm --name $DOCKER_NAME -e POSTGRES_PASSWORD=$POSTGRES_PW -d -p 5432:5432 mdillon/postgis:$1

# Wait until container is ready
until [ "`docker inspect -f {{.State.Running}} ${DOCKER_NAME}`"=="true" ]; do
    sleep 0.1;
done;
# Wait until Postgres is ready
until pg_isready -h localhost -q; do
    sleep 0.1;
done;

echo "Creating sifids DB"
psql -d "`conn_string postgres`" -c "CREATE DATABASE $SIFIDS_DB WITH ENCODING = 'UTF8';"

echo "Creating sifids_w user"
psql -d "`conn_string postgres`" -c "CREATE USER $SIFIDS_USER WITH PASSWORD '$SIFIDS_USER_PW';"

echo "Running create script, showing only errors. Errors related to role \"tania\" are expected - others are not"
psql -d "`conn_string $SIFIDS_DB`" -f $DIR/sifids_db_schema.sql | grep ERRO

echo "Stopping and deleting container"
docker stop $DOCKER_NAME
