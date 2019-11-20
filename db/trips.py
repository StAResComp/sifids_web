#!/usr/bin/python
# -*- coding: UTF-8 -*-

import psycopg2
import csv
import math

# maximum distance between 2 consecutive points in same track
# 1000m, roughly 1 minute at 30 knots
maxDist = 1000
# more than 5 minutes between time stamps means a new trip
maxTime = 5 * 60
# minimum length of trip
minTracks = 10

# distance in metres between two points
# https://gmigdos.wordpress.com/2010/03/31/python-calculate-the-distance-between-2-points-given-their-coordinates/
def calculate_distance(lat1, lon1, lat2, lon2): #{{{
    """
    * Calculates the distance between two points given their (lat, lon) co-ordinates.
    * It uses the Spherical Law Of Cosines (http://en.wikipedia.org/wiki/Spherical_law_of_cosines):
    *
    * cos(c) = cos(a) * cos(b) + sin(a) * sin(b) * cos(C)                        (1)
    *
    * In this case:
    * a = lat1 in radians, b = lat2 in radians, C = (lon2 - lon1) in radians
    * and because the latitude range is  [-π/2, π/2] instead of [0, π]
    * and the longitude range is [-π, π] instead of [0, 2π]
    * (1) transforms into:
    *
    * x = cos(c) = sin(a) * sin(b) + cos(a) * cos(b) * cos(C)
    *
    * Finally the distance is arccos(x)
    """
    
    if ((lat1 == lat2) and (lon1 == lon2)):
        return 0
    
    try:
        delta = lon2 - lon1
        a = math.radians(lat1)
        b = math.radians(lat2)
        C = math.radians(delta)
        x = math.sin(a) * math.sin(b) + math.cos(a) * math.cos(b) * math.cos(C)
        distance = math.acos(x) # in radians
        distance  = math.degrees(distance) # in degrees
        distance  = distance * 60 # 60 nautical miles / lat degree
        distance = distance * 1852 # conversion to meters
        distance  = round(distance)
        return distance;
    except:
        return 0
#}}}

# create new trip record and return ID
def newTrip(): #{{{
    cur = con.cursor()
    cur.execute('INSERT INTO trips VALUES (DEFAULT) RETURNING trip_id')
    
    return cur.fetchone()[0]
#}}}

# set the trip for a track point
def setTrip(trip, row): #{{{
    cur = con.cursor()
    cur.execute('UPDATE tracks SET trip_id = %s, tripped = TRUE WHERE upload_id = %s AND time_stamp = %s AND lat = %s AND lon = %s', 
                (trip, row[1], row[2], row[3], row[4]))
#}}}

# read in database details from ~/.pgpass
deets = []
line = 0 # this is the line we want
with open('/home/sifids/.pgpass', 'r') as passfile:
    reader = csv.reader(passfile, delimiter=':')
    for row in reader:
        deets.append(row)

# connect to database
con = psycopg2.connect(host=deets[line][0],
                       port=deets[line][1],
                       database=deets[line][2],
                       user=deets[line][3],
                       password=deets[line][4])

with con:
    # get tracks ordered by vessel and timestamp which don't have trip id and are older than a day
    cur = con.cursor()
    cur.execute("SELECT v.vessel_id, t.upload_id, t.time_stamp, t.lat, t.lon FROM vessels AS v INNER JOIN  uploads USING (vessel_id) INNER JOIN tracks AS t USING (upload_id) WHERE trip_id IS NULL AND tripped IS NULL AND t.time_stamp < now() - INTERVAL '1 DAY' ORDER BY vessel_id ASC, t.upload_id ASC, t.time_stamp ASC")
    
    # remember previous row
    oldRow = (None, None, None, None, None)
    trip = None
    oldTrip = None
    
    # loop over rows
    row = cur.fetchone()
    while row:
        # when vessel changes, or time/distance between points too great
        if oldRow[0] != row[0]:
            print('Different vessels')
            trip = newTrip()
        elif (row[2] - oldRow[2]).total_seconds() > maxTime:
            print('Time difference %d (%d, %s - %s)' % ((row[2] - oldRow[2]).total_seconds(), row[1], oldRow[2], row[2]))
            trip = newTrip()
        elif calculate_distance(oldRow[3], oldRow[4], row[3], row[4]) > maxDist:
            print('Distance difference %d (%d, (%f, %f) - (%f, %f))' % (calculate_distance(oldRow[3], oldRow[4], row[3], row[4]), row[1], oldRow[3], oldRow[4], row[3], row[4]))
            trip = newTrip()
        
        # set trip for current row
        setTrip(trip, row)
        
        # remember current row
        oldRow = row[:]
        
        # get next row
        row = cur.fetchone()
    
    # remove trips with fewer than X tracks
    cur.execute('UPDATE tracks SET trip_id = NULL FROM (SELECT trip_id FROM tracks GROUP BY trip_id HAVING COUNT(*) < %s) AS t WHERE tracks.trip_id = t.trip_id',
               (minTracks,))
    
    # commit changes
    con.commit()
