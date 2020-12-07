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
library(ggnewscale)
source("helper.R")


body <- dashboardBody(
    fluidRow(
        box(width = 9, title = "Visualization",
            plotOutput("vis", width = "100%", height = "auto", hover = "vis_click"),
            verbatimTextOutput("info"),
            shiny::textOutput("debug")
            ) ,
        box(width = 3, title = "Options",
            sliderInput("alpha", label = "Alpha", min = 0.01, max = 1, step = 0.1, value = .3),
            sliderInput("bkg_size", label = "Size of background points", min = 0.1, max = 5, step = 0.1, value = 2),
            sliderInput("label_size", label = "Size of labels", min = 0.5, max = 10, step = 0.5, value = 1),
            br(),
            sliderInput("data_size", label = "Base size of data points", min = 1, max = 10, step = 0.5, value = 1),
            uiOutput("ui_date_selector")

            )

    )
)





# Server ----
server <- function(input, output, session) {

    raw_data <- reactive({
        all_data <- read_rds("data/small.rds")
            #getData()# %>% sample_frac(0.01)
        message("Data loaded.")
        all_data
    })

    id_data <- reactive({
        all_data <- raw_data()
        i_data <- all_data %>% create_id_column(url)
        i_data
    })

    selected_data <- reactive({
        i_data <- id_data()
        req(input$date_selector)
        my_date <- input$date_selector
        #my_date <- "2017-09-20"
        i_data %>% filter(search_date == my_date)
    })

    upper_limit_re <- reactive({
        i_data <- id_data()
        upper_limit <- i_data %>% pull(gghid) %>% max()
        upper_limit
    })

    regions_data <- reactive({
        i_data <- id_data()
        regions <- i_data %>%
            select(gghid, domain, url) %>% unique() %>%
            mutate(domain_number = as.numeric(factor(domain))) %>%  ## used to be %% 2
            mutate(domain_number = factor(domain_number)) %>%
            create_coordinates(gghid) %>%
            arrange(gghid)
    })



    top_domains_re <- reactive({
        all_data <- raw_data()
        top_count <- 30
        top_domains <- all_data %>%
            group_by(domain) %>%
            count() %>%
            arrange(desc(n)) %>%
            head(top_count)
        top_domains
    })


    label_positions_re <- reactive({
        i_data <- id_data()
        top_domains <- top_domains_re()
        upper_limit <- upper_limit_re()

        #cat("mean positionts")
        mean_positions <- i_data %>%
            select(domain, gghid) %>%
            right_join(top_domains) %>%
            bind_rows(tibble(domain = c("aaaa","zzzz"), gghid = c(1,upper_limit))) %>%
            create_coordinates(gghid) %>%
            group_by(domain) %>%  # find the average domain position
            summarize(x = round(mean(x),2),
                      y = round(mean(y),2)
            ) %>%
            ungroup()

        mean_positions %>%
            # bind_rows(tibble(domain = c("aaaa","zzzz"), gghid = c(1,upper_limit))) %>%
            # create_coordinates(gghid) %>%
            filter(!str_detect(domain, "aaaa")) %>%
            filter(!str_detect(domain, "zzzz"))
    })

    plot_data_re <- reactive({
        i_data <- selected_data()
        plot_data <- i_data %>%
            filter(country == "DE") %>%
            #filter(search_date == "2017-09-20") %>%
            mutate(rank = 10 - rank) %>%
            filter(rank > 0) %>%
            mutate(rank = factor(rank, levels = c(1:10), labels = paste("Rank", 10:1))) %>%
            create_coordinates(gghid)
        plot_data
    })


    # Renderplot ----
    output$vis <- renderPlot({

        all_data <- raw_data()
        i_data <- id_data()
        regions <- regions_data()
        upper_limit <- max(i_data$gghid)

        alpha_val <- input$alpha
        size_bkg_val <- input$bkg_size
        txt_size <- input$label_size
        data_size <- input$data_size
        # find all domains that occur most frequently
       # top_domains <- top_domains_re()


        # add artificial start and endpoints to the label data to prevent truncated coordinate system
        label_positions <- label_positions_re()

        n_colors <- nrow(regions %>% select(domain_number) %>% unique())
        color_scheme <- grDevices::topo.colors(n_colors) %>% sample()

        plot_data <- plot_data_re()


        message("Render new plot.")
        # --- plot
        ggplot(plot_data) +
            scale_color_manual(values = color_scheme) +
            geom_point(
                data = regions,
                mapping = aes(x = x, y = y, color = domain_number, group = "1"),
                alpha = alpha_val,
                size = size_bkg_val,
                shape = 15
            ) +
            new_scale_color() +
            geom_point(
                data = plot_data,
                mapping = aes(x = x, y = y, color = keyword, size = as.numeric(rank)*data_size),
                color = "white",
                alpha = 0.1
            ) +
            ggrepel::geom_label_repel(
                data = label_positions,
                mapping = aes(x = x, y = y, label = domain),
                seed = 123,
                size = txt_size,
                show.legend = F,
                min.segment.length = 0,
                segment.size = 0.3,
                fill = "black",
                color = "grey80",
                alpha = 0.5
            ) +
            coord_fixed() +
            #facet_wrap(. ~ keyword) +
            my_theme +
            theme(
                panel.grid = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                axis.text = element_blank(),
                axis.ticks = element_blank()
            )

    }, height = function() {
        session$clientData$output_vis_width
    })


    output$debug <- renderText({
        nrow(id_data())
    })

    output$info <- renderPrint({
        regions <- regions_data()
        # With base graphics, need to tell it what the x and y variables are.
        nearPoints(regions, input$vis_click) %>% select(url)
        # nearPoints() also works with hover and dblclick events
    })


    output$ui_date_selector <- renderUI({
        all_data <- raw_data()
        start <- all_data$search_date %>% min()
        stop <- all_data$search_date %>% max()

        dateInput("date_selector", label = "Pick a date", min = start, max = stop, value = stop)
    })
}






# App ----
shinyApp(
    ui = dashboardPage(
        dashboardHeader(title = "DataDonationVis"),
        dashboardSidebar(),
        body
    ),

    server = server,
)
