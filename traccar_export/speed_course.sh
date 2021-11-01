#!/bin/bash

# TRACCAR connection
TRACCAR_PSQL=`grep traccar ~/.pgpass | gawk -F: '{ print "psql --csv -h " $1 " -p " $2 " " $3 " " $4 }'`

# SQL for extracting data from Traccar
EXPORT_SQL="SELECT uniqueid, devicetime, speed, course FROM tc_devices AS d INNER JOIN tc_positions AS p ON d.id = p.deviceid WHERE fixtime BETWEEN '%s'::TIMESTAMP WITHOUT TIME ZONE AND '%s'::TIMESTAMP WITHOUT TIME ZONE;"

# script for inserting data into SIFIDS database
INSERT=./insert_speed_course.php

# dates for start/end of export given as first two arguments
STARTDATE=$1
ENDDATE=$2

# when no start date given, use yesterday
if [ -z "$STARTDATE" ] 
then
  STARTDATE=`date --date yesterday "+%Y-%m-%d"`
fi

# when no end date given, use day after start date
if [ -z "$ENDDATE" ]
then
  ENDDATE=`date --date "$STARTDATE + 1 day" "+%Y-%m-%d"`
fi

printf "$EXPORT_SQL" "$STARTDATE" "$ENDDATE" | $TRACCAR_PSQL | tail -n "+2" | $INSERT
