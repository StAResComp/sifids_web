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
library(geosphere)
library(nlme)
library(lme4)

# functions for database
source('../ShinyApps/app/db.R', local=FALSE)

# get date to do analysis for
argv <- commandArgs(trailingOnly=TRUE)

if (length(argv) < 1) {
  stop("Usage: ./analysis.R YYYY-MM-DD [device_id]", call.=FALSE)
}

date <- argv[1]
deviceID = NA
if (length(argv) == 2) {
  deviceID = as.integer(argv[2])
}

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

# stats for distance and length of vessel (m)
DIST_MEAN <- 384.83
DIST_SD <- 249.84
LENGTH_MEAN <- 8.959044
LENGTH_SD <- 1.606637

# maximum plausible length of haul (m)
MAX_HAUL_LENGTH <- 2500

# maximum gap between points (in meters)
MAX_GAP <- 500

# date/time formats
DATE_FMT <- "%Y-%m-%d %H:%M:%S"
TIME_FMT <- "%H:%M:%S"

# see if x is empty in some way
empty <- function(x) { #{{{
  return((!isS4(x) && is.na(x)) || is.null(x) || 0 == length(x) || 0 == nrow(x) || isFALSE(x))
}
#}}}

# is gap between two points too big
gapTooBig <- function(dist) { #{{{
  return (dist > (MAX_GAP))
}
#}}}

# delete any analysis already done for given date
deleteAnalysis <- function() { #{{{
  if (is.na(deviceID)) {
    dbProc('deleteAnalysis', list(date))
  } else {
    dbProc('deleteDeviceAnalysis', list(date, deviceID))
  }
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
  if (is.na(deviceID)) {
    dbProc('tracksForAnalysis', list(date, OBVS, METERS, TIME))
  } else {
    dbProc('tracksDeviceForAnalysis', list(date, deviceID, OBVS, METERS, TIME))
  }
}
#}}}

# convert to trajectories
trajectorise <- function(df) { #{{{
  # calculate trajectories within dataframe df
  sp <- SpatialPoints(df[, c("longitude", "latitude")],
    proj4string=CRS("+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"))
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

# delete observations based on unrealistic speeds 
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

# rediscretisize trajectories - every 1 minute
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

# add vessel information to data frame
addVessels <- function(df) { #{{{
  trips_device_vessel <- dbGetQuery(con, 
    sprintf("SELECT * FROM vesselsForAnalysis('%s');", date))
  
  # get back trip_id from data frame
  df$trip_id <- gsub(" .*$", "", df$id)

  merge(df,
    trips_device_vessel[, c("trip_id", 
      "vessel_pln", "vessel_name", "vessel_length",
      "gear_name", "animal_code")], 
    by.x="trip_id", by.y="trip_id", all.x=TRUE)
}
#}}}

# apply random forest analysis of activity
randomForestHauling <- function(df) { #{{{
  df$date <- as.POSIXct((df$date), format=DATE_FMT, origin="1970-01-01")
  df$time <- as.numeric(times(format(df$date, format=TIME_FMT)))

  load("model1.rda")
  predValid <- as.data.frame(predict(model1, df, type="class"))
  df$rf_behaviour <- predValid$`predict(model1, df, type = "class")`
  
  # remove rows with NA for trip_id
  df <- df[!is.na(df$trip_id), ]

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

  # treat NAs as steaming
  df$activity <- ifelse(is.na(df$fishing) | 'steaming' == df$fishing, 1, 2)
  
  df
}
#}}}

# add contents of hauling activity dataframe to database
addHaulingToDatabase <- function(df) { #{{{
  # get time stamp from pkey field, and trip_id from id
  df$time_stamp <- gsub("^.*\\.", "", df$pkey)
    
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

# add distance to database
addDistanceToDatabase <- function(df) { #{{{
  # get back trip_id from data frame
  df$trip_id <- gsub(" .*$", "", df$id)
  
  x <- apply(df, 1,
    function(x)
      dbProc('addDistanceEstimate', list(x['trip_id'], x['total_dist'])))
}
#}}}

# calculate distance per trip
distancePerTrip <- function(df) { #{{{
  df$id <- as.factor(df$id)
  
  distance <- df %>% 
    group_by(id) %>% 
    summarise(total_dist = sum(dist, na.rm=TRUE))
  
  distance
}
#}}}

# calculate distance per haul
distancePerHaul <- function(df) { #{{{
  crow <- df %>% 
    group_by(haul_group) %>%
    arrange(haul_group) %>%
    filter(row_number() == 1 | row_number() == n())
  
  # filter out singleton hauls - 95% of observed hauls last more than 1 minute
  check <- crow %>% count(haul_group)
  check <- check[check$n > 1, ]
  sel <- unique(check$haul_group)
  
  crow <- crow[crow$haul_group %in% sel, ]
  
  crow <- as.data.table(crow)
  crow[, longitude_end := shift(lon, 1L, type="lead"), by=haul_group]
  crow[, latitude_end := shift(lat, 1L, type="lead"), by=haul_group]
  crow[, date_end := shift(date, 1L, type="lead"), by=haul_group]
  
  crow <- crow[!is.na(crow$date_end), ]
  
  crow$distance <- distHaversine(crow[, c("lon", "lat")], crow[, c("longitude_end", "latitude_end")])
  
  # return only hauls below maximum plausible haul length
  crow[crow$distance < MAX_HAUL_LENGTH, ]
}
#}}}

# estimate number of creels used
creelEstimate <- function(df) { #{{{
  # reformat date
  df$date <- as.POSIXct((df$date), format=DATE_FMT)
  
  # reorder data by trip ID and timestamp
  df <- df[order(df$id, df$date), ]
  
  # if vessel not hauling then it is steaming
  df$fishing[is.na(df$fishing)] <- "steaming"
  
  # count each episode of consecutive behavious
  df$counter <- rleid(df$fishing)
  df$haul_group <- paste(df$id, df$fishing, df$counter)
  df$haul_group <- as.factor(df$haul_group)
  
  # get distance per haul
  df <- distancePerHaul(df[df$fishing == "hauling", ])
  
  # standardise
  df$distance_crow_st <- (df$distance - DIST_MEAN) / DIST_SD
  df$overalllength_st <- (df$vessel_length - LENGTH_MEAN) / LENGTH_SD
  
  df$newspeciescode <- factor(df$animal_code)
  
  # load model for creel estimates
  load("gm1.rda")
  
  prediction <- predict(gm1, newdata=df, re.form=~0, type="response")
  bootfit <- bootMer(gm1, FUN=function(x)predict(x, df, re.form=NA), nsim=999)
  
  df$lci <- apply(bootfit$t, 2, quantile, 0.025, na.rm=TRUE)
  df$hci <- apply(bootfit$t, 2, quantile, 0.975, na.rm=TRUE)
  df$fit <- prediction
  
  sum <- df %>% 
    group_by(id) %>%
    summarise(total_creels = sum(fit), total_creels_high=sum(hci), total_creels_low=sum(lci))
  
  sum$total_creels_adj <- as.integer(41.14 + (1.06 * sum$total_creels))
  sum$total_creels_adj_low <- as.integer(41.14 + (1.06 * sum$total_creels_low))
  sum$total_creels_adj_high <- as.integer(41.14 + (1.06 * sum$total_creels_high))
  
  sum
}
#}}}

# add creel estimates to database
addCreelsToDatabase <- function(df) { #{{{
  # get back trip_id from data frame
  df$trip_id <- gsub(" .*$", "", df$id)
  
  x <- apply(df, 1,
    function(x)
      dbProc('addCreelEstimates', list(x['trip_id'], 
          x['total_creels_adj'], x['total_creels_adj_low'], x['total_creels_adj_high'])))
}
#}}}

main <- function() { #{{{
  #df <- read.table("2019-12-23_data.txt", sep=",")
  # create connection to database
  global()
  
  # delete any analysis for given date
  deleteAnalysis()
  
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

  # add vessel information to data frame
  df <- addVessels(df)
  #write.table(df, "2019-12-23_data.txt", sep=",")
  
  # calculate distance per trip
  distance <- distancePerTrip(df)
  
  addDistanceToDatabase(distance)
  
  # apply random forest analysis of activity
  # only for vessels which have pots/creels
  df <- randomForestHauling(df[df$gear_name == 'Pots creels', ])
  if (empty(df)) {
    return(FALSE)
  }

  # add hauling activity to database
  addHaulingToDatabase(df)
  
  # estimate creel numbers
  creels <- creelEstimate(df)
  addCreelsToDatabase(creels)
}
#}}}

main()
