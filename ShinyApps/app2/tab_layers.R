# plot different map data
layerTab <- tabPanel('Historic data',
  sidebarLayout(
    sidebarPanel(
      radioButtons("layer", "Options",
        c("Hauls per day (ScotMap data)" = "hauls",
          "Vessels with creels" = "vessels",
          "Creel sightings" = "sightings",
          "Minke strandings" = "minke"),
        selected = character(0)
        ),
      
      conditionalPanel(condition="input.layer == 'hauls'",
        p("Source: ", a(href="https://www2.gov.scot/Resource/0046/00466802.pdf", "https://www2.gov.scot/Resource/0046/00466802.pdf")),
        p("Reference: Kafas, A., McLay, A., Chimienti, M. and Gubbins, M., ScotMap
          Inshore Fisheries Mapping in Scotland: Recording Fishermen’s use of the
          Sea. Scottish Marine and Freshwater Science. Volume 5 Number 17"
          )
        ),
      
      conditionalPanel(condition="input.layer == 'vessels'",
        p("Source: ", a(href="http://marine.gov.scot/information/creel-fishing-effort-study", "http://marine.gov.scot/information/creel-fishing-effort-study")),
        p("Reference: Marine Scotland Science, 2017, Creel Fishing Effort Study, Scottish Government")
        ),
      
      conditionalPanel(condition="input.layer == 'sightings'",
        radioButtons("hwdt_year", "Year",
          choices=c(
            "2008" = 2008,
            "2009" = 2009,
            "2010" = 2010
            )
          ),
        p("Source: Hebridean Whale and Dolphin Trust"),
        p("Time period: 2008 - 2010")
        ),
      
      conditionalPanel(condition="input.layer == 'minke'",
        p("Data presented through the SIFIDS user interface show the location of
          stranded Minke whales that were identified as having been entangled from
          1990 to 2018."
          ),
        p("Data source: Scottish Marine Animal Stranding Scheme (2019)"),
        p("Time period: 1990 to 2018")
        )
      ),
    
    # main panel to show map
    mainPanel(
      leafletOutput('mapLayers', width='800px', height='800px')
      )
    )
  )
