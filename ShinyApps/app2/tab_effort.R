# catch/effort graph
effortTab <- tabPanel('Metrics',
  sidebarLayout(
    sidebarPanel(
      # dynamic list of vessels
      uiOutput('effortVessels'),
      
      # date range
      uiOutput('effortDaterange'),
      
      # list of species
      uiOutput('effortSpecies'),
      
      # effort measure
      uiOutput('effortEffort'),

      h3('Download data'),
      
      downloadButton('effortDownload', 'Download effort data')
      ),
    
    # main panel to show plots
    mainPanel(
      h3(textOutput('effortHeading', inline=TRUE)),
      
      textOutput('effortAnonMessage'),
      
      plotOutput('effortPlot')
      )
    )
  )
