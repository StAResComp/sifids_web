# tab for showing tracks to all users except fishers
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

        p(
          actionButton('clearTracks', 'Clear selected tracks')
        ),
        
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

# tab for showing tracks to fishers
trackFisherTab <- tabPanel('Track data',
  sidebarLayout(
    sidebarPanel(
      # tracks or heatmap
      uiOutput('tracksFisherMapType'),
      
      # dynamic list of vessels
      uiOutput('tracksVessels'),
      
      # date range - up until today
      uiOutput('tracksDaterange'),
      
      conditionalPanel(
        condition="input.tracksMapType == 'tracks'",
        
        # options for fishing events
        uiOutput('tracksFishingEvents'),
        
        # table for displaying trips and selecting tracks
        DT::dataTableOutput('tracksFisherTrips'),
        
        actionButton('clearFisherTracks', 'Clear selected tracks')
        ),
      
      conditionalPanel(
        condition="input.tracksMapType == 'heat_all'",
        p('Heat map showing where vessels spent time.')
        ),

      h3('Download data'),
      
      downloadButton('tracksFisherDownload', 'Download track data')
      ),
    
    # main panel to show map
    mainPanel(
      leafletOutput('tracksMap', width='800px', height='800px')
      )
    )
  )
