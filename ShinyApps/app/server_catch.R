catchIsAnon <- reactiveValues(
  #{{{
  totalCatch = 'Total catch',
  totalCatchOverTime = 'Total catch over time for selected species',
  message = ''
  )
#}}}

# get catch per species for the vessels selected inside the given date range
catchCatch <- reactive({ #{{{
    # need dates
    dates <- getDateRange(input$catchDates)
    if (is.null(dates)) {
      return()
    }

    # if no date, then current user has no fish1 data, and any date will do
    if (is.na(dates)) {
      dates <- c('2010-01-01', '2010-01-01')
    }
    
    dbProc('catchPerSpecies', 
      list(user$id, 
        getArray(input$catchVessels), 
        dates[1], dates[2],
        getInt(input$catchPortOfDeparture),
        getInt(input$catchPortOfLanding),
        getInt(input$catchFisheryOffice),
        getArray(input$catchSpecies)
        )
      )
  })
#}}}

# get weight of species caught each week
catchSpeciesOverTime <- reactive({ #{{{
    # need dates
    dates <- getDateRange(input$catchDates)
    if (is.null(dates)) {
      return(NA)
    }
    
    # if no date, then current user has no fish1 data, and any date will do
    if (is.na(dates)) {
      dates <- c('2010-01-01', '2010-01-01')
    }
    
    dbProc('catchPerSpeciesWeek', 
      list(user$id, 
        getArray(input$catchVessels), 
        dates[1], dates[2],
        getInt(input$catchPortOfDeparture),
        getInt(input$catchPortOfLanding),
        getInt(input$catchFisheryOffice),
        getArray(input$catchSpecies)
        )
      )
  })
#}}}

catchVessels <- reactive({
    #{{{
    dbProcNamed('vesselsFish1', 
      list(user$id), 
      'vessel_id', 'vessel_pln')
  })
#}}}

# output vessels as select control
output$catchVessels <- renderUI({ 
    #{{{
    vessels <- catchVessels()
    selectInput('catchVessels', 'Vessels', choices=c('All'='', vessels), selected=TRUE, multiple=TRUE)
  })
#}}}

catchPortOfDeparture <- reactive({
    #{{{
    dbProcNamed('portOfDeparture', 
      list(user$id),
      'port_id', 'port_name')
  })
#}}}

# ports of departure and landing
output$catchPortOfDeparture <- renderUI({ 
    #{{{
    ports <- catchPortOfDeparture()
    selectInput('catchPortOfDeparture', 'Port of departure', choices=c('', ports), selected=FALSE)
  })
#}}}

output$catchPortOfLanding <- renderUI({ #{{{
    ports <- dbProcNamed('portOfLanding', list(user$id), 'port_id', 'port_name')
    selectInput('catchPortOfLanding', 'Port of landing', choices=c('', ports), selected=FALSE)
  })
#}}}

# fishery office
output$catchFisheryOffice <- renderUI({ #{{{
    fos <- dbProcNamed('fisheryOffice', list(user$id), 'fo_id', 'fo_town')
    selectInput('catchFisheryOffice', 'Fishery Office', choices=c("", fos), selected=FALSE)
  })
#}}}

# species
output$catchSpecies <- renderUI({ #{{{
    species <- dbProcNamed('catchSpecies', list(user$id), 'animal_id', 'animal_name')
    selectInput('catchSpecies', 'Species', choices=c("", species), selected=FALSE, multiple=TRUE)
  })
#}}}

# get first/last dates of tracks for given vessel, or all vessels if none given
catchDates <- reactive({ #{{{
    dbProc('datesForVesselFish1', 
      list(user$id, 
        getArray(input$catchVessels)#,
#        getInt(input$catchPortOfDeparture),
#        getInt(input$catchPortOfLanding),
#        getInt(input$catchFisheryOffice),
#        getArray(input$catchSpecies)
        )
      )
  })
#}}}

# output dates as date range control
output$catchDaterange <- renderUI({ #{{{
    dates <- catchDates() # get dates from reactive function
    dateRangeInput('catchDates', 'Between these dates', 
      start=dates[[1]], end=dates[[2]], format='dd-mm-yyyy')
  })
#}}}

# output data table
output$catchSummary <- DT::renderDataTable({ #{{{
    catch <- catchCatch()
    
    if (length(catch) == 0) {
      return()
    }

    # update strings depending on whether data is anonymous or not
    if (catch[1,]$anon == 1) {
      catchIsAnon$totalCatch = 'Total catch (average data)'
      catchIsAnon$message = 'Data collected by users of SIFIDS mobile app.'
    } else {
      catchIsAnon$totalCatch = 'Total catch'
      catchIsAnon$message = ''
    }
    
    data <- data.frame(species=catch$species, weight=catch$weight)
    
    datatable(data,
      colnames=c('Species', 'Weight in kg'),
      rownames=FALSE
      )
  })
#}}}

# histogram for catch of species over time
output$catchOverTime <- renderPlot({ #{{{
    sot <- catchSpeciesOverTime()
    
    if (length(sot) == 0 || is.na(sot)) {
      return()
    }
    
    if (sot[1,]$anon == 1) {
      catchIsAnon$totalCatchOverTime = 'Catch over time for selected species (average data)'
    } else {
      catchIsAnon$totalCatchOverTime = 'Catch over time for selected species'
    }
    
    data <- data.frame(week=sot$week, weight=sot$weight, species=sot$species)
    
    ggplot() + 
      geom_col(data=data, aes(x=week, y=weight, fill=species)) + 
      scale_x_discrete(name="Weeks") + 
      scale_y_continuous(name="Weight in kg") +
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size=16))
    })
#}}}

output$catchDownload <- downloadHandler(
  #{{{
  filename = 'catch.csv',
  
  content = function(file) {
    write.csv(catchSpeciesOverTime(), file)
  }
  )
#}}}

# output headings for table and graph
# modified depending on whether user has fish1 catch data
output$totalCatch <- renderText({
    catchIsAnon$totalCatch
  })

output$totalCatchOverTime <- renderText({
    catchIsAnon$totalCatchOverTime
  })

output$catchAnonMessage <- renderText({
    catchIsAnon$message
  })