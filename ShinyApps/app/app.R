#libraries and versions below
library(shinythemes)    # version 1.1.1
library(dplyr)          # version 0.7.4
library(reshape2)       # version 1.4.2
library(likert)         # version 1.3.5
library(rgdal)          # version 1.2-16
library(rgeos)          # version 0.3-26
library(shiny)          # version 1.0.5
library(ggplot2)        # version 2.2.1
library(gridExtra)
library(magrittr)       # version 1.5
library(leaflet)        # version 1.1.0
library(RColorBrewer)   # version 1.1-2
#library(pool)
library(DBI)            # version 0.7
library(RPostgreSQL)    # version 0.5-2
library(sf)             # version 0.5-5
library(sp)
library(shinydashboard) # version 0.6.0
library(maps)           # version 3.2.0
library(DT)             # version 0.2
library(rmarkdown)      # version 1.8
library(viridis)        # version 0.4.0
library(shinyTree)      # version 0.2.2
library(shinyjs)        # version 1.0
library(leaflet.extras)
library(raster)

# load DB connection code
source('db.R', local=FALSE)

# load UI and server code
source('app_ui.R', local=FALSE)
source('app_server.R', local=FALSE)

shinyApp(
  ui <- appUI,
  server <- appServer,
  onStart <- global
  )
