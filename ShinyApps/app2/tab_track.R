# Tanias track data analysis
trackTab <- tabPanel('Track data',
  sidebarLayout(
    sidebarPanel(
      # tracks or heatmap
      uiOutput('tracksMapType'),
      
      # dynamic list of vessels
      uiOutput('tracksVessels'),
      
      # date range - up until today
      uiOutput('tracksDaterange'),
      
      conditionalPanel(
        condition="input.tracksMapType == 'tracks'",
        
        # options for fishing events
        uiOutput('tracksFishingEvents'),
        
        # table for displaying trips and selecting tracks
        DT::dataTableOutput('tracksTrips'),
        
        p('Red sections of track represent periods of estimated hauling activity.'),
        p('* Estimated values')
        ),
      
      conditionalPanel(
        condition="input.tracksMapType == 'heat'",
        p('Heat map showing where vessels spent (estimated) time hauling pots.')
        ),
      
      conditionalPanel(
        condition="input.tracksMapType == 'revisits'",
        p('Shows how often vessels re-entered 200m square areas while hauling (estimated).')
        ),
      
      h3('Download data'),
      
      downloadButton('tracksDownload', 'Download track data')
      ),
    
    # main panel to show map
    mainPanel(
      leafletOutput('tracksMap', width='800px', height='800px')
      )
    )
  )
