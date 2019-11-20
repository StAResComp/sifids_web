# server code for handling authentication

# user profile - reactive so that reactive functions can access this
user <- reactiveValues(id=NULL, role=NULL, vessel_ids=c(), vessel_names=c())

# user trying to log in
observe({
    if (is.null(user$id) && !is.null(input$login) && input$login > 0) {
      logged <- dbProc('appLogin', list(isolate(input$username), isolate(input$password)))
      if (!is.null(logged$user_id)) {
        user$id <- logged$user_id[1]
        user$role <- logged$user_role[1]
        user$vessel_ids <- logged$vessel_ids
        
        if (user$role %in% c('fisher', 'admin')) {
          user$vessel_names <- logged$vessel_names
        } else {
          user$vessel_names <- logged$vessel_codes
        }
      }
    }
  })

# which page to display - based on whether user is logged in or not
observe({
    output$page <- renderUI({
        if (is.null(user$id)) {
          loginPage()
        }
      else if (user$role == 'admin') {
          tabs_admin()
        }
      else if (user$role == 'fisher') {
          tabs_fisher()
        }
      else {
        tabs()
      }
      })
  })