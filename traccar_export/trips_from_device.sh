#!/bin/bash

# TRACCAR connection
TRACCAR_PSQL=`grep traccar ~/.pgpass | awk -F: '{ print "psql -t -A -F, -h " $1 " -p " $2 " " $3 " " $4 }'`

# SQL for extracting data from Traccar
EXPORT_SQL="SELECT d.uniqueid, p.devicetime, REPLACE(p.attributes, ',', '|') AS 'attributes', p.latitude, p.longitude, p.valid FROM tc_positions AS p INNER JOIN tc_devices AS d ON p.deviceid = d.id WHERE d.uniqueid = '%s' AND p.devicetime BETWEEN '%s' AND '%s' ORDER BY p.devicetime ASC;"

# script for inserting data into SIFIDS database
INSERT=./insert_trips_from_device.php

# IMEI string for device is required
IMEI=$1
if [ -z "$IMEI" ]
then
  exit 1
fi

# dates for start/end of export given as next two arguments
STARTDATE=$2
ENDDATE=$3

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

printf "$EXPORT_SQL" "$IMEI" "$STARTDATE" "$ENDDATE" | $TRACCAR_PSQL #| $INSERT
