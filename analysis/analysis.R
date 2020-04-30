#!/usr/bin/Rscript --vanilla

# libraries
library(DBI)
library(RPostgreSQL)
library(tidyverse)
library(raster)
library(ggplot2)
library(rgeos)
library(adehabitatLT)
library(data.table)
library(chron)
library(randomForest)
library(lubridate)
library(dplyr)

# functions for database
source('../ShinyApps/app2/db.R', local=FALSE)

# get date to do analysis for
argv <- commandArgs(trailingOnly=TRUE)

if (length(argv) != 1) {
  stop("Usage: ./analysis.R YYYY-MM-DD", call.=FALSE)
}

date <- argv[1]

# parameters for query
OBVS <- 50 # need more observations than this
METERS <- 5000 # trip needs to be longer than this (in meters)
TIME <- 3600 # trip needs to be longer than this (in seconds)

# convert speed to knots
KNOTS <- 1.943
# maximum plausible speed
MAX_SPEED <- 25

# size of grid for revisits (in meters)
GRID_SIZE <- 200

# period for rediscretisizing data (seconds)
DISCRETE_TIME <- 60

# see if x is empty in some way
empty <- function(x) { #{{{
  return((!isS4(x) && is.na(x)) || is.null(x) || 0 == length(x) || 0 == nrow(x) || isFALSE(x))
}
#}}}

# get initial data from database
getData <- function() { #{{{
  # get tracks for given date
  # tracksForAnalysis returns distinct tracks for trips
  # after vessels have left 200m buffer and before vessels return to 200m buffer
  # and where latitude > 40 and longitude between -8 and 0 (roughly Scottish waters)
  # and the trips have minimum number of observations and length (in meters and seconds)
  # and where vessels are more than 10m from shore
  dbProc('tracksForAnalysis', list(date, OBVS, METERS, TIME))
}
#}}}

# convert to trajectories
trajectorise <- function(df) { #{{{
  # calculate trajectories within dataframe df
  sp <- SpatialPoints(df[, c("longitude", "latitude")],
    proj4string=CRS("+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "))
  sp2 <- as.data.frame(spTransform(sp, 
      CRS("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0")))

  # add long/lat as meters to dataframe
  df$x <- sp2$lon
  df$y <- sp2$lat
  
  df$trip_id <- factor(df$trip_id)
  df$date <- as.Date(df$time_stamp)
  df$trip_id_date <- paste(df$trip_id, df$date)
  
  # return trajectories
  ld(as.ltraj(df[, c("x", "y")], df$time_stamp, df$trip_id_date))
}
#}}}

#**************************
#7.- Delete observations based on unrealistic speeds 
#**************************
filterOnSpeed <- function(trajdf) { #{{{
  # From conversations with observers and fishers, these vessels move at 25 knots maximum - delete any observations where speed greater than 25 knots
  trajdf$speed <- trajdf$dist / trajdf$dt * KNOTS

  # first look at the proportion of observations in each trip with speeds greater than 25
  prop_speed_high <- trajdf %>% 
    filter(speed > MAX_SPEED) %>% 
    group_by(burst) %>%
    tally

  prop_speed_low <- trajdf %>% 
    filter(speed <= MAX_SPEED) %>% 
    group_by(burst) %>%
    tally

  prop_speed <- merge(prop_speed_high, prop_speed_low, by="burst")
  prop_speed$prop <- prop_speed$n.x / prop_speed$n.y * 100

  # Erase trajectories or trips where the proportion of high speeds (>6.5 knots) is above 50% of the total number of data points
  prop_speed_s <- prop_speed[prop_speed$prop > 50, ]
  sel <- factor(prop_speed_s$burst)

  trajdf <- trajdf[!trajdf$burst %in% sel, ]

  # construct trajectories again
  trajdf$burst <- factor(trajdf$burst)
  
  traj <- NA

  # now erase speeds greater than 25 knots in a repeat loop
  repeat { 
    traj <- as.ltraj(trajdf[, c("x", "y")], trajdf$date, trajdf$burst)
    trajdf <- ld(traj)
    trajdf$speed <- trajdf$dist / trajdf$dt * KNOTS
    
    df <- trajdf[trajdf$speed > MAX_SPEED, ]
    df <- df[complete.cases(df), ]
 
    sel <- factor(df$pkey)

    if (length(sel) == 0) {
      break
    } else {
      trajdf <- trajdf[!trajdf$pkey %in% sel, ]
    }
  }
  
  traj
}
#}}}

#**************************
#8.- Rediscretisize trajectories - every 1 minute
#**************************
rediscretisize <- function(traj) { #{{{
  # the hauling events are so long (min, max, mean that a 1 minute "ping" ok to identify fishig activities?)
  traj <- redisltraj(na.omit(traj), DISCRETE_TIME, type="time")
  df <- ld(traj)

  # convert to lat and lon
  sp <- SpatialPoints(df[, c("x","y")], 
    proj4string=CRS("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"))
  sp2 <- spTransform(sp, 
    CRS("+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "))
  sp2 <- as.data.frame(sp2)

  df$lon <- sp2$x
  df$lat <- sp2$y
  
  df
}
#}}}

# Add vessel information  to data frame
# (not used)
addVessels <- function(df) { #{{{
  trips_device_vessel <- dbGetQuery(con, 
    sprintf("SELECT * FROM vesselsForAnalysis('%s');", date))
  
  # get back trip_id from data frame
  df$trip_id <- gsub(" .*$", "", df$id)

  merge(df,
    trips_device_vessel[, c("trip_id", "vessel_pln", "vessel_name")], 
    by.x="trip_id", by.y="trip_id", all.x=TRUE)
}
#}}}

# apply random forest analysis of activity
randomForest <- function(df) { #{{{
  load("model1.rda")
  
  df$date <- as.POSIXct((df$date), format="%Y-%m-%d %H:%M:%S", origin="1970-01-01")
  df$time <- as.numeric(times(format(df$date, format="%H:%M:%S")))

  predValid <- as.data.frame(predict(model1, df, type="class"))

  df$rf_behaviour <- predValid$`predict(model1, df, type = "class")`

  # now change if 2 no before and 2 no after yes, then change to no
  # if 2 yes before and 2 yes after no then change to yes

  df$rf_behaviour_1 <- lead(df$rf_behaviour, n=1L)
  df$rf_behaviour_2 <- lead(df$rf_behaviour, n=2L)
  df$rf_behaviour__1 <- lag(df$rf_behaviour, n=1L)
  df$rf_behaviour__2 <- lag(df$rf_behaviour, n=2L)

  df$fishing <- ifelse(df$rf_behaviour=="steaming" & df$rf_behaviour_1=="hauling" & df$rf_behaviour_2=="hauling" & df$rf_behaviour__1=="hauling" & df$rf_behaviour__2=="hauling", 
    "hauling", as.character(df$rf_behaviour))

  df$fishing <- ifelse(df$rf_behaviour=="hauling" & df$rf_behaviour_1=="steaming" & df$rf_behaviour_2=="steaming" & df$rf_behaviour__1=="steaming" & df$rf_behaviour__2=="steaming", 
    "steaming",as.character(df$fishing))
  
  df
}
#}}}

# add contents of dataframe to database
addToDatabase <- function(df) { #{{{
  # get time stamp from pkey field, and trip_id from id
  df$time_stamp <- gsub("^.*\\.", "", df$pkey)
  df$trip_id <- gsub(" .*$", "", df$id)
  
  # treat NAs as steaming
  df$activity <- ifelse(is.na(df$fishing) | 'steaming' == df$fishing, 1, 2)
  
  # apply callback function to each row in data frame
  x <- apply(df, 1, 
    function(x) 
      dbProc('addAnalysedTrack', list(x['lat'], x['lon'], x['time_stamp'], x['trip_id'], x['activity'])))
  
  # complete analysis by finding grid IDs when vessel is hauling and enters new grid
  x <- lapply(unique(df$trip_id),
    function(x)
      dbProc('addSegmentAnalysis', list(x, GRID_SIZE)))
}
#}}}

main <- function() { #{{{
  # create connection to database
  global()
  
  # get data from database
  df <- getData()
  
  if (empty(df)) {
    return(FALSE)
  }
  
  # calculate trajectories
  df <- trajectorise(df)
  
  if (empty(df)) {
    return(FALSE)
  }
  
  # filter tracks based on speed
  traj <- filterOnSpeed(df)

  # redescretisize points
  df <- rediscretisize(traj)
  
  if (empty(df)) {
    return(FALSE)
  }
 
  # apply random forest analysis of activity
  df <- randomForest(df)
  
  if (empty(df)) {
    return(FALSE)
  }

  # add to database
  addToDatabase(df)
}
#}}}

main()
