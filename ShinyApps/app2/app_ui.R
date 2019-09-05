source('tab_intro.R', local=TRUE)
source('tab_catch.R', local=TRUE)
source('tab_track.R', local=TRUE)
source('tab_effort.R', local=TRUE)
source('tab_layers.R', local=TRUE)
source('tab_admin.R', local=TRUE)

# load whatever is in 'page'
appUI <- (htmlOutput('page'))

# show login page
loginPage <- function() {
  fluidPage(
    theme="style.css",
    fluidRow(
      column(4, imageOutput('marine_scotland', height="180px")), 
      column(4, imageOutput('emff', height="180px")),
      column(4, imageOutput('seascope', height="180px"))
      ),
    fluidRow(
      column(6, imageOutput('sifids', height="180px")), 
      column(6, imageOutput('st_andrews', height="180px"))
      ),
    fluidRow(
      column(6, offset=3,
        wellPanel(
          textInput('username', 'User name'),
          passwordInput('password', 'Password'),
          br(),
          actionButton('login', 'Log in')
          )
        )
      )
    )
}

# show tabs
tabs <- function() {
  navbarPage(
    theme = "style.css", # style.css loads shinytheme("flatly")
    title = "SIFIDS Application",
    id = "navbar", 
    introTab,
    catchTab,
    trackTab,
    effortTab,
    layerTab
    )
}

# show tabs for admin user
tabs_admin <- function() {
  navbarPage(
    theme = "style.css", # style.css loads shinytheme("flatly")
    title = "SIFIDS Application (Admin view)",
    id = "navbar", 
    introTab,
    adminTab,
    catchTab,
    trackTab,
    effortTab,
    layerTab
    )
}