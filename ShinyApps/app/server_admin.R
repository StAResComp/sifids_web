# get first/last dates of attributes for given vessel
attributeDates <- reactive({
    #{{{
    dbProc('datesForAttributes', list(user$id, getArray(input$adminVessels)))
  })
#}}}

# get plot data
plotData <- reactive({
    #{{{
    # need attributes for plot
    req(input$adminAttributes)
    
    # need dates
    dates <- getDateRange(input$adminDates)
    if (is.null(dates)) {
      return()
    }
    
    dbProc('attributePlotData', 
      list(user$id, 
        getArray(input$adminVessels),
        dates[1], dates[2],
        getArray(input$adminAttributes)))
  })
#}}}

# output vessels as select control
output$adminVessels <- renderUI({ 
    #{{{
    vessels <- dbProcNamed('attributeVessels', list(user$id), 'vessel_id', 'vessel_pln')
    
    selectInput('adminVessels', 'Vessels', vessels, multiple=TRUE)
  })
#}}}

output$adminDates <- renderUI({
    #{{{
    dateArr <- attributeDates() # get dates from reactive function
    dateRangeInput('adminDates', 'Between these dates', 
      start=dateArr[[1]], end=dateArr[[2]], format='dd-mm-yyyy')
  })
#}}}

output$adminAttributes <- renderUI({
    #{{{
    choices <- dbProcNamed('getAttributes', list(), 'attribute_id', 'attribute_display')
    selectInput('adminAttributes', 'Attributes', choices, multiple=TRUE)
  })
#}}}

# plot attribute values over time
output$adminPlot <- renderPlot({
    #{{{
    pd <- plotData()
    data <- data.frame(x=pd$time_stamp, y=pd$attribute_value, vessel=pd$vessel_pln, att=pd$attribute_name)
    
    if (length(data) > 0) {
      data$is_line <- data$att %in% c('power', 'battery', 'totalDistance')
      data$is_point <- data$att %in% c('sat', 'distance')
      
      data$y_line <- with(data, ifelse(is_line, y, NA))
      data$y_point <- with(data, ifelse(is_point, y, NA))
      
      p <- ggplot(data)
      
      if (length(data[!is.na(data$y_line),]$y_line) > 0) {
        cat(file=stderr(), "have line data\n")
        p <- p + geom_line(aes(x=x, y=y_line, color=vessel))
      }
      
      if (length(data[!is.na(data$y_point),]$y_point) > 0) {
        cat(file=stderr(), paste(data[!is.na(data$y_point),], collapse="\n"))
        p <- p + geom_point(aes(x=x, y=y_point, color=vessel))
      }
      
      p + theme_bw() +
      ylab(NULL) + 
      xlab('Time') +
      theme(legend.position='bottom', text=element_text(size=16)) +
      facet_grid(att ~ ., scales='free_y', 
        labeller=as_labeller(c(
            power='Power (volts)', battery='Battery (volts)', sat='Number of satellites', distance='Distance (km)', totalDistance='Total distance (km)')))
    }
  }, height=900)
#}}}