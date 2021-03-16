library(shiny)
library(shinydashboard)
library(tidyverse)
library(lubridate)
library(gghilbertstrings)
library(ggnewscale)
library(DT)
library(shinyBS)
source("helper.R")


menu <- dashboardSidebar(collapsed = TRUE,
  sidebarMenu(
    id = "tabs",
    menuItem("Introduction", tabName = "intro", icon = icon("dashboard")),
    menuItem("App", tabName = "app", icon = icon("th"))
  )
)

# ui:body ---
body <- dashboardBody(tabItems( # First tab content
  # tab: start ----
  tabItem(tabName = "intro",
          fluidRow(
            box(width = 12,
                title = "Introduction",
                p("Welcom to our user study. In this study we want to understand how a novel visualization is understood by new users."),
                p("Youtube Video in here:"),
                p("Please click on \"Start the Task\" as soon as you are ready."),
                shinycssloaders::withSpinner(
                  shiny::uiOutput("ui_start_app"))
            )

          )
  ),
  # tab: app ----
  tabItem(tabName = "app",
          fluidRow(
            shiny::column(width = 3,
                          box(width = 12,
                              title = "General Settings",
                              #sliderInput("data_fraction", "How much data do you want to work with?",
                              #            min = 1, max = 100, value = 100, step = .5, post = "%"),
                              #shiny::textOutput("nrows"),
                              shiny::uiOutput("ui_party_selector"),
                              shiny::checkboxInput("show_labels", "Show most frequent Domains", value = T),
                              sliderInput("anim_speed", "Animation delay", min = 15, max = 1000, value = 200, step = 5)
                          ),
                          box(
                            width = 12,
                            collapsible = T,
                            collapsed = T,
                            title = "Screen Options",
                            sliderInput(
                              "top_n_level",
                              label = "How many labels to show",
                              min = 10,
                              max = 100,
                              step = 1,
                              value = 30
                            ),
                            sliderInput(
                              "alpha",
                              label = "Alpha of Hilbert Curve",
                              min = 0.01,
                              max = 1,
                              step = 0.1,
                              value = .5
                            ),
                            sliderInput(
                              "label_size",
                              label = "Size of labels",
                              min = 0.5,
                              max = 10,
                              step = 0.5,
                              value = 5
                            ),
                            br(),
                            sliderInput(
                              "data_size",
                              label = "Scale of data points",
                              min = 1,
                              max = 10,
                              step = 0.5,
                              value = 10
                            )

                          )

            ),
            shiny::column(width = 9,
                          box(
                            width = 12,
                            title = "Visualization",
                            uiOutput("ui_date_selector"),
                            shiny::actionButton("cache_invalidation","Re-Render")
                          ),
                          shiny::fluidRow(
                            box(width = 6, title = "Main plot",
                                plotOutput(
                                  "vis",
                                  #width = "600px",
                                  height = "600px",
                                  hover = "vis_hover",
                                  click = "vis_click",
                                  brush = "vis_brush"
                                )),
                            box(width = 6, title = "Brush to select:",
                                plotOutput("zoomedview",
                                           #width = "600px",
                                           height = "600px",
                                           hover = "vis2_hover"
                                           )
                            ),
                            box(width = 6, title = "Near the cursor",
                                shiny::tableOutput("tooltip")
                            ),
                            box(width = 6, title = "Selected data:",
                                DT::DTOutput("info"),
                                shiny::textOutput("debug")
                            ),
                          )
            )


          )
  )
)
)



shinyUI(dashboardPage(
           dashboardHeader(title = "DataDonationVis"),
           menu,
           body
       ))



