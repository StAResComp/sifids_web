library(shiny)
library(RPostgreSQL)
library(leaflet)

shinyServer(function(input, output) {
    # get database connection details
    deets <- scan('~/.pgpass', sep=':', what=list('', '', '', '', ''))
    i <- 1 # which line to use
    
    # make connection
    conn = dbConnect(dbDriver('PostgreSQL'), 
      host=deets[[1]][i], port=deets[[2]][i], dbname=deets[[3]][i],
      user=deets[[4]][i], password=deets[[5]][i])
    
    postgresqlpqExec(conn, "SET client_encoding='UTF8'")
    
    # get first/last dates of tracks for given vessel
    # reactive, so only called when input$vessel changes
    dates <- reactive({
        if (!is.null(input$vessel)) {
            query <- sprintf('SELECT MIN(t.time_stamp)::date AS minDate, MAX(t.time_stamp)::date AS maxDate FROM vessels INNER JOIN uploads USING (vessel_id) INNER JOIN tracks AS t USING (upload_id) WHERE vessel_id = %d;', 
              strtoi(input$vessel, 10))
            dbGetQuery(conn, query)
        }
      })
    
    # get track data for given vessel in given date range
    tracks <- reactive({
        if (!is.null(input$trips)) {
          query <- sprintf("SELECT t.trip_id, t.lat AS lat, t.lon AS long FROM vessels INNER JOIN uploads USING (vessel_id) INNER JOIN tracks AS t USING (upload_id) WHERE trip_id IN (%s) ORDER BY t.time_stamp ASC;",
            paste(input$trips, collapse=','))
          dbGetQuery(conn, query)
        }
      })
    
    # get trips made by vessel between dates
    trips <- reactive({
        if (!is.null(input$dates[1]) && !is.null(input$dates[2])) {
          query <- sprintf("SELECT t.trip_id, TO_CHAR(MIN(t.time_stamp), 'YYYY-MM-DD HH24:MI') || ' - ' || TO_CHAR(MAX(t.time_stamp), 'YYYY-MM-DD HH24:MI') AS rep FROM vessels INNER JOIN uploads USING (vessel_id) INNER JOIN tracks AS t USING (upload_id) WHERE trip_id IS NOT NULL AND vessel_id = %d AND t.time_stamp BETWEEN '%s' AND '%s' GROUP BY t.trip_id;",
            strtoi(input$vessel, 10), input$dates[1], input$dates[2])
          dbGetQuery(conn, query)
        }
      })

    # output trips
    output$trips <- renderUI({
        tripsArr <- trips()
        trips <- tripsArr$trip_id
        names(trips) <- tripsArr$rep
        
        selectInput('trips', 'Trips', trips, multiple=TRUE)
      })
    
    # output vessels as select control
    output$vessels <- renderUI({
        # get list of vessels
        query = 'SELECT v.vessel_id, v.vessel_name FROM vessels AS v INNER JOIN uploads USING (vessel_id) INNER JOIN tracks USING (upload_id) WHERE active = 1 GROUP BY v.vessel_id, v.vessel_name;'
        vesselArr <- dbGetQuery(conn, query)
        # turn into named 1d array
        vessels = vesselArr$vessel_id
        names(vessels) = vesselArr$vessel_name
        
        selectInput('vessel', 'Vessels', vessels)
      })
    
    # output dates as date range control
    output$daterange <- renderUI({
        dateArr <- dates() # get dates from reactive function
        dateRangeInput('dates', 'Between these dates', 
          start=dateArr[[1]], end=dateArr[[2]])
      })
    
    # output map
    output$map <- renderLeaflet({
        trackArr <- tracks()
        
        if (length(trackArr) > 0) {
          map <- leaflet()
          map <- addTiles(map)
          
          for (trip in split(trackArr, trackArr$trip_id)) {
            map <- addPolylines(map, lat=trip$lat, lng=trip$long)
          }
          
          map
        }
      })
})