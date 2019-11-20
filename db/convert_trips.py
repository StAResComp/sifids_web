#!/usr/bin/python

import psycopg2
import csv
from datetime import datetime

# read in database details from ~/.pgpass
deets = []
line = 8 # this is the line we want
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

# format for parsing time stamps
time_fmt = '%Y-%m-%d %H:%M:%S%z'

with con:
    cur = con.cursor()
    # switch to traccar schema
    cur.execute("SET SCHEMA 'traccar';")
    
    # get tracks and trips
    cur.execute("SELECT trip_id, device_id, DATE_TRUNC('day', time_stamp) FROM traccar_trips INNER JOIN traccar_track USING (trip_id) GROUP BY trip_id, DATE_TRUNC('day', time_stamp) ORDER BY trip_id, device_id, DATE_TRUNC('day', time_stamp);")
    data = cur.fetchall()
    
    old_device = 0
    old_day = ''
    old_trip = 0
    
    l = len(data)
    
    new_data = {}
    
    for i, row in enumerate(data):
        key = (row[1], row[2].strftime(time_fmt))
        
        if not key in new_data:
            new_data[key] = []
        
        new_data[key] += [str(row[0])]
    
    # set schema
    print("SET SCHEMA 'traccar';")
    
    for device_id, date in new_data:
        # get trip IDs
        ids = new_data[(device_id, date)]
        
        # skip when there is just 1 ID
        if 1 == len(ids):
            continue
        
        # ID to keep, ones to move and last ID
        keep, move, last = ids[0], ids[1:-1], ids[-1]
        
        update = "UPDATE traccar_track SET trip_id = %s WHERE (trip_id = %s AND DATE_TRUNC('day', time_stamp) = '%s')" % (keep, last, date)
        if move:
            update += " OR trip_id IN (%s)" % (','.join(move))
        update += ";"
        
        print(update)
