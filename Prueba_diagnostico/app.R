library(shiny)
library(surveydown)

db <- sd_db_connect()
ui <- sd_ui()

server <- function(input, output, session) {
  sd_server(db = db)
}

shinyApp(ui = ui, server = server)
