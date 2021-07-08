# global database connection
con <- NA

# onStart function
global <- function() {
  # get connection details from ~/.pgpass
  deets <- scan(file="~/.pgpass", sep=":", what=list('', '', '', '', ''))
  # which line to use
  line <- 15
  con <<- dbConnect(RPostgreSQL::PostgreSQL(max.con=50), 
    host=deets[[1]][line], 
    dbname=deets[[3]][line], 
    port=deets[[2]][line], 
    user=deets[[4]][line], 
    password=deets[[5]][line]
    )
}

# function to call stored procedure with arguments
dbProc <- function(proc_name, arg_list) {
  # put together right number of placeholder ?s
  placeholders <- ''
  if (length(arg_list) > 0) {
    placeholders <- paste0('$', paste(seq_along(arg_list), collapse=',$'))
  }
  
  # generate SQL string
  sql <- sprintf('SELECT * FROM %s(%s);',
    proc_name, placeholders)
  
  # prepare stmt and bind arguments
  stmt <- dbSendQuery(con, sql, arg_list)

  # get results
  results <- dbFetch(stmt)
  
  # finished with stmt
  dbClearResult(stmt)
  
  # return results
  results
}

# get named array from DB procedure
dbProcNamed <- function(proc_name, arg_list, id_column, named_column) {
  arr <- dbProc(proc_name, arg_list)
  col <- arr[[id_column]]
  names(col) <- arr[[named_column]]
  
  return(col)
}

# query database using st_read (for PostGIS stuff)
dbProcST <- function(proc_name, arg_list) {
  # generate SQL string
  query <- sprintf('SELECT * FROM %s(%s);',
    proc_name, paste(arg_list, collapse=","))
  
  # run query and return results
  st_read(con, query=query)
}