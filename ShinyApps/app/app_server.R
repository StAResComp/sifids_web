appServer <- shinyServer(function(input, output, session) {
    source('server_login.R', local=TRUE)
    source('server_intro.R', local=TRUE)
    source('server_catch.R', local=TRUE)
    source('server_tracks.R', local=TRUE)
    source('server_effort.R', local=TRUE)
#    source('server_layers.R', local=TRUE)
    source('server_admin.R', local=TRUE)
  })

# function to return array for passing to stored procedure
getArray <- function(arg) {
  arr <- '{}'
  
  if (isTruthy(arg)) {
    arr <- sprintf('{%s}', paste(arg, collapse=","))
  }
  
  arr
}

# get integer value of argument, or 0
getInt <- function(arg) {
  id <- 0
  
  if (isTruthy(arg)) {
    id <- strtoi(arg)
  }
  
  id
}

# get date range formatted for stored procedure, or return null/na
getDateRange <- function(arg) {
  if (is.null(arg[1]) || is.null(arg[2])) {
    return(NULL)
  }
  
  if (is.na(arg[1]) || is.na(arg[2])) {
    return(NA)
  }
  
  return(c(sprintf('%s', arg[1]), sprintf('%s', arg[2])))
}