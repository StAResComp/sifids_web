# what data to show based on input$layer
observeEvent(c(input$layer, input$hwdt_year), ignoreNULL=FALSE, {
    map <- leafletProxy("mapLayers")

    clearMarkers(map)
    clearShapes(map)
    clearControls(map)
    
    # clear any previous heat map
    map <- clearGroup(map, group="heat")
    
    if (is.null(input$layer) || input$layer == "hauls") {
      data <- dbProcST('geographyHauls', list())
      breaks <- c(0.5, 5, 7.3, 430)
      pal <- colorBin("Reds", data$combined, breaks, pretty=F)
      
      addPolygons(map, data=data, fillOpacity=0.5, stroke=F, color=~pal(combined), 
        popup=paste("<strong>hauls</strong>:", data$combined))
      addLegend(map, pal=pal, values=data$combined, title="Hauls per day")
    }
  else if (input$layer == "vessels") {
      data <- dbProcST('geographyVessels', list())
      pal <- colorFactor("Greens", data$vessel_count)
      
      addPolygons(map, data=data, fillOpacity=0.5, stroke=F, color=~pal(vessel_count))
      addLegend(map, pal=pal, values=data$vessel_count, title="Vessels with creels")
    }
  else if (input$layer == "sightings") {
      data <- dbProcST('geographySightings', list(input$hwdt_year))
      map <- addHeatmap(map, data=data, group="heat",
        blur=25, radius=15, max=0.1)
    }
  else if (input$layer == "minke") {
      data <- dbProcST('geographyMinke', list())
      
      addCircles(map, data=data, fillOpacity=0.5, stroke=F, radius=3000, color="blue", 
        popup=paste("<strong>Year</strong>", data$year))
    }
  })

# output map
output$mapLayers <- renderLeaflet({
    map <- leaflet(options = leafletOptions(preferCanvas = TRUE))
    map <- addTiles(map)
    map <- setView(map, -4, 57, zoom=7) # centre on Scotland
    map <- addScaleBar(map)
    
    map
  })