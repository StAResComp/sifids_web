library(shiny)
library(leaflet)

shinyUI(
  pageWithSidebar(
    # header
    headerPanel('Track fishing boats'),
    
    # select vessel
    sidebarPanel(
      # dynamic list of vessels
      uiOutput('vessels'),
      
      # date range - up until today
      #dateRangeInput('dates', 'Between these dates', start=dateStart, end=NULL)
      uiOutput('daterange'),
      
      # only use every nth track point
      numericInput('nth', 'Display every nth point', 1)
    ),
    
    # main panel to show map
    mainPanel(
      h3(textOutput('Map')),
      
      leafletOutput('map', width='800px', height='800px')
    )
  )
)