effortIsAnon <- reactiveValues(
  #{{{
  effortHeading = 'Catch per unit of effort',
  message = ''
  )
#}}}

# different measures of effort
measures <- c('distance', 'creels', 'trips')
procs <- c('effortDistance', 'effortCreels', 'effortTrips')
effortLabels <- c('Distance travelled per week (km)', 'Creels used per week (estimate)', 'Trips per week')
effortCatchLabels <- c('Catch (kg) per km travelled per week', 'Catch (kg) per creel used per week', 'Catch (kg) per trip per week')
measuresDF <- data.frame(measures, procs, effortLabels, effortCatchLabels, stringsAsFactors=FALSE)

# output dates as date range control
output$effortDaterange <- renderUI({ 
    #{{{
    dateArr <- dbProc('datesForEffort', list(user$id))
    dateRangeInput('effortDaterange', 'Between these dates', 
      start=dateArr[[1]], end=dateArr[[2]], format='dd-mm-yyyy')
  })
#}}}

# output list of vessels
output$effortVessels <- renderUI({
    #{{{
    vessels <- dbProcNamed('effortVessels', list(user$id), 'vessel_id', 'vessel_pln')
    selectInput('effortVessels', 'Vessels', vessels, multiple=TRUE)
  })
#}}}

# output list of species
output$effortSpecies <- renderUI({
    #{{{
    species <- dbProcNamed('effortSpecies', list(user$id), 'animal_id', 'animal_name')
    selectInput('effortSpecies', 'Species', species, multiple=TRUE)
  })
#}}}

# output list of effort measures
output$effortEffort <- renderUI({
    #{{{
    choices <- measuresDF$measures
    names(choices) <- measuresDF$effortLabels
    
    radioButtons('effortEffort', 'Measure of effort', choices)
  })
#}}}

# get data on effort
effortData <- reactive({
    #{{{
    # need dates
    dates <- getDateRange(input$effortDaterange)
    if (is.null(dates)) {
      return()
    }

    # if no date, then current user has no effort data, and any date will do
    if (is.na(dates)) {
      dates <- c('2010-01-01', '2010-01-01')
    }

    # which procedure to run
    proc <- 'effortDistance'
    if (!is.null(input$effortEffort) && length(input$effortEffort) == 1 && input$effortEffort %in% measuresDF$measures) {
      proc <- measuresDF[measuresDF$measures == input$effortEffort,]$procs
    }
    
    dbProc(proc, 
      list(user$id, 
        getArray(input$effortVessels),
        dates[1], dates[2],
        getArray(input$effortSpecies)))
  })
#}}}

# output plot showing catch/effort
output$effortPlot <- renderPlot({ #{{{
    effortArr <- effortData()
    
    if (length(effortArr) == 0) {
      return()
    }

    # update strings depending on whether data is anonymous or not
    if (effortArr[1,]$anon == 1) {
      effortIsAnon$effortHeading = 'Catch per unit of effort (average data)'
      effortIsAnon$message = 'Data collected by users of SeaScope kit.'
    } else {
      effortIsAnon$effortHeading = 'Catch per unit of effort'
      effortIsAnon$message = ''
    }
    
    data <- effortArr %>% group_by(week_start) %>% mutate(sum.effort = sum(effort))
    
    effortLabel <- measuresDF[measuresDF$measures == input$effortEffort,]$effortLabels
    effortCatchLabel <- measuresDF[measuresDF$measures == input$effortEffort,]$effortCatchLabels
    
    # create plots for effort, catch and catch/effort
    effortPlot <- ggplot() + 
    geom_line(data=data, aes(x=week_start, y=sum.effort)) + 
    theme_bw() + 
    ylab(effortLabel) + 
    xlab('Date') + 
    theme(legend.position="bottom", text = element_text(size=16))
    
    catchPlot <- ggplot() + 
    labs(colour='Animals') + 
    geom_line(data=data, aes(x=week_start, y=catch, colour=animal_name)) + 
    theme_bw() + 
    ylab('Catch (kg) per week') + 
    xlab('Date') + 
    theme(legend.position="bottom", text = element_text(size=16))
    
    effortCatchPlot <- ggplot() + 
    labs(colour='Animals') + 
    geom_line(data=data, aes(x=week_start, y=catch/effort, colour=animal_name)) + 
    theme_bw() + 
    ylab(effortCatchLabel) + 
    xlab('Date') + 
    theme(legend.position="bottom", text = element_text(size=16))
    
    grid.arrange(effortPlot, catchPlot, effortCatchPlot, ncol=1)
  }, height=900)
#}}}

output$effortDownload <- downloadHandler(
  #{{{
  filename = 'effort.csv',
  
  content = function(file) {
    effortArr <- effortData()
    data <- effortArr %>% group_by(week_start) %>% mutate(sum.effort = sum(effort))
    write.csv(data, file)
  }
  )
#}}}

output$effortHeading <- renderText({
    effortIsAnon$effortHeading
  })

output$effortAnonMessage <- renderText({
    effortIsAnon$message
  })