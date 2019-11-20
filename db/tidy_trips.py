#!/usr/bin/python3

import csv
import psycopg2
from datetime import date, timedelta

# use lines (from ~/.pgpass) as connection information
def conn(lines): #{{{
    connections = {}
    
    with open('/home/sifids/.pgpass', 'r') as passfile:
        reader = csv.reader(passfile, delimiter=':')
        l = 1 # 1 indexed
        for row in reader:
            if l in lines:
                connections[l] = psycopg2.connect(host=row[0], port=row[1], database=row[2], user=row[3], password=row[4])
            l += 1
    
    return connections
#}}}

# commit all transactions
def commit(connections): #{{{
    for c in connections:
        connections[c].commit();
#}}}

# connection/s to open
connections = conn([13])

# cursor needed
cur13 = connections[13].cursor()

# get yesterday's date
yesterday = date.today() - timedelta(days=1)

# get all trips from yesterday plus number of tracks in each trip
cur13.execute("""
  SELECT trip_id, device_id
  FROM "Trips" 
  INNER JOIN "Tracks" USING (trip_id)
  WHERE trip_date = %s
  GROUP BY trip_id
  ORDER BY device_id, COUNT(*) DESC
  ;
""", (str(yesterday),))
trips = cur13.fetchall()

# prepare statement for updating tracks
cur13.execute("""
  PREPARE updateTrack(INTEGER, INTEGER) AS 
  UPDATE "Tracks" 
  SET trip_id = $2 
  WHERE trip_id = $1
  ;
""")
# prepare statement for deleting trip
cur13.execute("""
  PREPARE deleteTrip(INTEGER) AS
  DELETE
  FROM "Trips"
  WHERE trip_id = $1
  ;
""")

old_device_id = 0
old_trip_id = 0

for (trip_id, device_id) in trips:
    # different device
    if device_id != old_device_id:
        old_device_id = device_id
        old_trip_id = trip_id
        print('device %d, trip %d has most points' % (device_id, trip_id))
    # another row from the same device
    else:
        # move tracks from this trip to trip with more tracks
        cur13.execute('EXECUTE updateTrack(%s, %s);', (old_trip_id, trip_id))
        # now delete current trip
        cur13.execute('EXECUTE deleteTrip(%s);', (trip_id,))
        print('device %d, trip %d will be merged with %d' % (device_id, trip_id, old_trip_id))

# commit changes
#commit(connections)
