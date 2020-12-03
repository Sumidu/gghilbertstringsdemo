#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(tidyverse)
library(lubridate)
library(gghilbertstrings)

source("helper.R")


body <- dashboardBody(
    fluidRow(
        box(width = 9, title = "Visualization",
            shiny::textOutput("debug")
            ) ,
        box(width = 3, title = "Options")
    )
)





# Server ----
server <- function(input, output) {

    raw_data <- reactive({
        getData()
    })

    id_data <- reactive({
        raw_data() %>% create_id_column(url)
    })


    # The currently selected tab from the first box


    output$debug <- renderText({
        nrow(id_data())
    })
}






# App ----
shinyApp(
    ui = dashboardPage(
        dashboardHeader(title = "DataDonationVis"),
        dashboardSidebar(),
        body
    ),

    server = server

)
