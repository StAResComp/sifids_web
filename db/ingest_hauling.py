#!/usr/bin/python
# -*- coding: UTF-8 -*-

# usage: ./ingest_hauling.py tracks.csv creels.csv distances.csv

import psycopg2
import csv
import sys
import utm

# read in database details from ~/.pgpass
deets = []
line = 0 # this is the line we want
with open('/home/sifids/.pgpass', 'r') as passfile:
    reader = csv.reader(passfile, delimiter=':')
    l = 0
    for row in reader:
        if l == line:
            deets = row
            break
        l += 1

# connect to database
con = psycopg2.connect(host=deets[0], port=deets[1], database=deets[2], user=deets[3], password=deets[4])

# remember activity, vessel and trip names/IDs
activities = {}
vessels = {}
trips = {}
grid = {}

# columns of interest
# track file
vessel_name = 1
track_trip_id = 2
x = 5
y = 6
date = 7
latitude = 13
longitude = 12
activity = 15
# creel file
trip_id = 1
creels_low = 2
creels_high = 3
# distance file
distance = 2
# effort file
vessel_week = 1
effort_vessel_name = 2
dist_week = 5
creels_week = 6
species = 8
catch = 9
trips_week = 10
midweek = 12

# size of grid squares
gridSize = 200
# UTM zone
zone = 30

with con:
    cur = con.cursor()
    
    # prepare statements
    cur.execute('PREPARE insertActivity (VARCHAR(255)) AS INSERT INTO tm_activities (activity) VALUES ($1) RETURNING activity_id;')
    cur.execute('PREPARE insertVessel (VARCHAR(255)) AS INSERT INTO tm_vessels (vessel_name) VALUES ($1) RETURNING vessel_id;')
    cur.execute('PREPARE insertTrip (INTEGER, VARCHAR(255)) AS INSERT INTO tm_trips (vessel_id, trip_name) VALUES ($1, $2) RETURNING trip_id;')
    cur.execute('PREPARE insertGrid (NUMERIC(15,12), NUMERIC(15,12), NUMERIC(15,12), NUMERIC(15,12)) AS INSERT INTO tm_grid (latitude1, longitude1, latitude2, longitude2) VALUES ($1, $2, $3, $4) RETURNING grid_id;')
    cur.execute('PREPARE insertTrack (INTEGER, NUMERIC(15,12), NUMERIC(15,12), TIMESTAMP WITH TIME ZONE, INTEGER) AS INSERT INTO tm_tracks (trip_id, latitude, longitude, time_stamp, activity_id, segment, grid_id) VALUES ($1, $2, $3, $4, $5, $6, $7);')
    cur.execute('PREPARE insertDummyTrack (INTEGER, NUMERIC(15,12), NUMERIC(15,12), TIMESTAMP WITH TIME ZONE, INTEGER) AS INSERT INTO tm_tracks (trip_id, latitude, longitude, time_stamp, activity_id, segment, dummy, grid_id) VALUES ($1, $2, $3, $4, $5, $6, 1, $7);')
    cur.execute('PREPARE insertCreels (VARCHAR(255), INTEGER, INTEGER) AS UPDATE tm_trips SET creels_low = $2, creels_high = $3 WHERE trip_name = $1;')
    cur.execute('PREPARE insertDistance (VARCHAR(255), NUMERIC(20,12)) AS UPDATE tm_trips SET distance = $2 WHERE trip_name = $1;')
    cur.execute('PREPARE insertEffort (VARCHAR(255), INTEGER, NUMERIC(20,12), NUMERIC(20,12), VARCHAR(255), NUMERIC(20,12), INTEGER, DATE) AS INSERT INTO tm_effort (vessel_week, vessel_id, distance, creels, species, catch, trips, midweek) VALUES ($1, $2, $3, $4, $5, $6, $7, $8);')
    
    # track data
    with open(sys.argv[1], 'r') as datafile:
        
        # read datafile as CSV
        reader = csv.reader(datafile, delimiter=',', quotechar='"')
        # skip first line
        next(reader)
        l = 0
        segment = 0
        oldTrack = [None, None, None, None, None, None]
        oldGrid = None
        
        for row in reader:
            # see if trip exists
            if not(trips.has_key(row[track_trip_id])):
                if not(vessels.has_key(row[vessel_name])):
                    cur.execute('EXECUTE insertVessel (%s)', (row[vessel_name],))
                    vessels[row[vessel_name]] = cur.fetchone()[0]
                    
                cur.execute('EXECUTE insertTrip (%s, %s)', (vessels[row[vessel_name]], row[track_trip_id]))
                trips[row[track_trip_id]] = cur.fetchone()[0]
                
            # see if activity exists
            if not(activities.has_key(row[activity])):
                cur.execute('EXECUTE insertActivity (%s)', (row[activity],))
                activities[row[activity]] = cur.fetchone()[0]
            
            # get the grid (x and y) that this point is in
            gridX = int(float(row[x]) - (float(row[x]) % gridSize))
            gridY = int(float(row[y]) - (float(row[y]) % gridSize))
            
            # grid ID set to NULL by default
            grid_id = None
            
            # hauling and in different grid square to last row
            if row[activity] == 'hauling' and (not(grid.has_key((gridX, gridY))) or grid[(gridX, gridY)] != oldGrid):
                # insert if new grid square
                if not(grid.has_key((gridX, gridY))):
                    (lat1, long1) = utm.to_latlon(gridX, gridY, zone, northern=True)
                    (lat2, long2) = utm.to_latlon(gridX + gridSize, gridY + gridSize, zone, northern=True)
                    cur.execute('EXECUTE insertGrid (%s, %s, %s, %s)', (lat1, long1, lat2, long2))
                    grid[(gridX, gridY)] = cur.fetchone()[0]
                # set grid ID now
                grid_id = grid[(gridX, gridY)]
            
            # remember current grid for next row
            if grid.has_key((gridX, gridY)):
                oldGrid = grid[(gridX, gridY)]
            
            # put track row together
            track = [trips[row[track_trip_id]], row[latitude], row[longitude], row[date], activities[row[activity]], segment, grid_id]
            
            # new segment when trip or activity changed from previous row
            if track[0] != oldTrack[0] or track[4] != oldTrack[4]:
                # when activity changes in same trip, add dummy track point using old activity
                if track[0] == oldTrack[0]:
                    track[4] = oldTrack[4]
                    # insert dummy track point with new location but old segment
                    cur.execute('EXECUTE insertDummyTrack(%s, %s, %s, %s, %s, %s, %s)', track)
                    track[4] = activities[row[activity]]
                
                # increment segment and update new track
                segment += 1
                track[5] = segment
            
            # add track row
            cur.execute('EXECUTE insertTrack(%s, %s, %s, %s, %s, %s, %s)', track)
            
            # remember track for next row
            oldTrack = track[:]
            
            # commit every 10000 rows
            l += 1
            if l % 10000 == 0:
                con.commit()
    
    # creels data
    with open(sys.argv[2], 'r') as datafile:
        
        # read datafile as CSV
        reader = csv.reader(datafile, delimiter=',', quotechar='"')
        # skip first line
        next(reader)
        
        for row in reader:
            cur.execute('EXECUTE insertCreels(%s, %s, %s);', (row[trip_id], int(float(row[creels_low])), int(float(row[creels_high]))))
    
    # distance data
    with open(sys.argv[3], 'r') as datafile:
        
        # read datafile as CSV
        reader = csv.reader(datafile, delimiter=',', quotechar='"')
        # skip first line
        next(reader)
        
        for row in reader:
            cur.execute('EXECUTE insertDistance(%s, %s);', (row[trip_id], row[distance]))
    
    # effort data
    with open(sys.argv[4], 'r') as datafile:
        
        # read datafile as CSV
        reader = csv.reader(datafile, delimiter=',', quotechar='"')
        # skip first line
        next(reader)
        
        for row in reader:
            # skip rows if catch or creels is NA
            if row[catch] == 'NA' or row[creels_week] == 'NA':
                continue
            cur.execute('EXECUTE insertEffort(%s, %s, %s, %s, %s, %s, %s, %s);', (row[vessel_week], vessels[row[effort_vessel_name]], row[dist_week], row[creels_week], row[species], row[catch], row[trips_week], row[midweek]))
        
        
    # commit data
    con.commit()
