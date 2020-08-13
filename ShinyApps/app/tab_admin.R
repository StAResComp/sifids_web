# Fish 1 form data
adminTab <- tabPanel("System status",
  sidebarLayout(
    sidebarPanel(
      # dynamic list of vessels
      uiOutput('adminVessels'),
      
      # date range
      uiOutput('adminDates'),
      
      # atributes to plot
      uiOutput('adminAttributes')
      ),
    mainPanel(
      plotOutput('adminPlot')
      )
    )
  )

