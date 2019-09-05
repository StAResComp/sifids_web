# Fish 1 form data
catchTab <- tabPanel("Fish 1 catch",
  sidebarLayout(
    sidebarPanel(
      h3('Total catch'),
      
      # dynamic list of vessels
      uiOutput('catchVessels'),
      
      # date range - up until today
      uiOutput('catchDaterange'),
      
      uiOutput('catchPortOfDeparture'),
      
      uiOutput('catchPortOfLanding'),
      
      uiOutput('catchFisheryOffice'),
      
      h3('Catch over time for selected species'),
      
      uiOutput('catchSpecies'),
      
      h3('Download data'),
      
      downloadButton('catchDownload', 'Download catch data')
      ),
    mainPanel(
      h3(textOutput('totalCatch', inline=TRUE)),
      
      DT::dataTableOutput('catchSummary'),
      
      h3(textOutput('totalCatchOverTime', inline=TRUE)),
      
      plotOutput('catchOverTime'),
      
      textOutput('catchAnonMessage')
      )
    )
  )

