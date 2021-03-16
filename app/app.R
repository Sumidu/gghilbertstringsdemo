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
library(DT)
library(shinyBS)
source("helper.R")


# UI ----







# Server ----
shinyServer(function(input, output, session) {


    # reactive values ----
    sem <- reactiveValues(setting = 1)


    # data management ----
    getData <- reactive({


        #filenames <- dir(here::here("app","data"), pattern = "*.rds", full.names = T)
        all_data <- NULL

        #withProgress(message = 'Reading in Data', value = 0, {
            all_data <- read_rds("../data/summary_data.RDS")
            # Number of times we'll go through the loop
            #n <- length(filenames) + 2

            #for (file in filenames) {
                # Increment the progress bar, and update the detail text.
            #   incProgress(1/n, detail = paste("Reading file", basename(file)))

             #   all_data <- bind_rows(all_data, read_rds(file))

          #  }
           # incProgress((n - 1)/n, detail = paste("Finalizing Data"))
           # all_data <- all_data # %>%
                #mutate(search_date = as_date(search_date)) %>% # Fix date as only days
             #   mutate(domain = str_replace_all(domain, "^[.](.+)", "\\1")) %>%  # fix some broken domains
              #  mutate(url = str_replace_all(url, "^[.](.+)", "\\1"))

       # })




        all_data #%>%
        #    group_by(keyword, country, search_date, url, domain) %>%
        #    summarise(rank = sum(1/(rank + 1))) %>%
        #    ungroup()
    })



    # ui: start button ----
    output$ui_start_app <- shiny::renderUI({
        req(raw_data())
        p(
            p(em("Data was successfully loaded")),
            shiny::actionButton("start_app", "Start the task")
        )
    })


    observeEvent(input$start_app, {
        updateTabItems(session, "tabs", "app")
    })


    observeEvent(input$cache_invalidation, {
        sem$setting <- sem$setting + 1
    })


    # Data handling ----
    raw_data <- reactive({
        # for debug purposes use small data
        #all_data <- read_rds("data/small.rds") %>% sample_frac(input$data_fraction / 100)
        # normally load all data
         all_data <- getData() %>%
             sample_frac(input$data_fraction / 100)
        message("Data loaded.")
        all_data
    })

    id_data <- reactive({
        all_data <- raw_data()
        i_data <- all_data %>% create_id_column(url)
        i_data
    })


    # UI generation ----
    output$nrows <- renderText({
        paste(nrow(raw_data()) %>% scales::number(big.mark = ",") , " rows of data")
    })



    # UI reactives ----

    selected_data <- reactive({
        i_data <- id_data()
        req(input$date_selector)
        my_date <- input$date_selector
        #my_date <- "2017-09-20"
        i_data %>% filter(search_date == my_date) %>%
        filter(keyword %in% input$party_selector)
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
            #mutate(rank = 10 - rank) %>%
            #filter(rank > 0) %>%
            #mutate(rank = factor(rank, levels = c(1:10), labels = paste("Rank", 10:1))) %>%
            create_coordinates(gghid)
        plot_data
    })





    # Renderplot ----
    output$vis <- renderPlot({
        req(input$date_selector)

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

        sizemax = max(i_data$rank)
        xmax = max(regions$x)
        ymax = max(regions$y)

        #message("Render new plot.")
        # --- plot
        ggplot(plot_data) +
            scale_color_manual(values = color_scheme) +
            #geom_point(
            #    data = regions,
            #    mapping = aes(x = x, y = y, color = domain_number, group = "1"),
            #    alpha = alpha_val,
            #    size = size_bkg_val,
            #    shape = 15
            #) +
            new_scale_color() +
            geom_point(
                data = plot_data,
                mapping = aes(x = x, y = y, color = keyword, size = as.numeric(rank)*data_size),
                #color = "white",
                alpha = 0.5
            ) +
            #geom_bin2d(data = plot_data,
            #               mapping = aes(x = x, y = y, color = keyword, size = as.numeric(rank)*data_size),
            #           binwidth = 3) +

            coord_fixed() +
            scale_x_continuous(limits = c(0, xmax)) +
            scale_y_continuous(limits = c(0, ymax)) +
            scale_size_continuous(limits = c(0, sizemax*10), range=c(1,30)) +
            #facet_wrap(. ~ keyword) +
            my_theme +
            theme(
                panel.grid = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                axis.text = element_blank(),
                axis.ticks = element_blank()
            ) -> p


        if (input$show_labels) {
            p <- p +
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
                )
        }
        p
    },
    height = function() {
        session$clientData$output_vis_width
    }

    ) %>% shiny::bindCache(input$date_selector, sem$setting)






    output$debug <- renderText({
        #nrow(id_data())
        ""
    })

    # UI table output ----
    output$info <- renderDT({
        regions <- regions_data()
        # With base graphics, need to tell it what the x and y variables are.
        brushedPoints(regions, input$vis_brush) %>%
            dplyr::bind_rows(
                nearPoints(regions, input$vis_click)
            ) %>%
            select(url) %>% unique() %>%
            mutate(link = paste0(paste0("<a href='http://",url,"', target ='_blank'>","Open","</a>")))
        # nearPoints() also works with hover and dblclick events
    }, escape = FALSE)



    # UI tooltip ----
    output$tooltip <- shiny::renderTable({
        regions <- regions_data()
        # With base graphics, need to tell it what the x and y variables are.
        outputvariable <- nearPoints(regions, input$vis_hover) %>% pull(url)
        #outputvariable <- brushedPoints(regions, input$vis_brush) %>% pull(url)

        content <- c()

        for (i in seq_along(outputvariable)) {
            content <- c(content, outputvariable[i])
        }
        data.frame(`URL` = content)
    })


    output$zoomedview <- shiny::renderPlot({
        req(input$date_selector)
        req(input$vis_brush)

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

        sizemax = max(i_data$rank)
        xmax = max(regions$x)
        ymax = max(regions$y)

        if (!is.null(input$vis_brush )) {
            ymin <- input$vis_brush$ymin
            ymax <- input$vis_brush$ymax
            xmin <- input$vis_brush$xmin
            xmax <- input$vis_brush$xmax

        } else {
            ymin <- 0
            ymax <- max(regions$y)
            xmin <- 0
            xmax = max(regions$x)

        }

        #xlim1 <- input$vis_brush$x1

        #message("Render new plot.")
        # --- plot
        ggplot(plot_data) +
            scale_color_manual(values = color_scheme) +
            #geom_point(
            #    data = regions,
            #    mapping = aes(x = x, y = y, color = domain_number, group = "1"),
            #    alpha = alpha_val,
            #    size = size_bkg_val,
            #    shape = 15
            #) +
            new_scale_color() +
            geom_point(
                data = plot_data,
                mapping = aes(x = x, y = y, color = keyword, size = as.numeric(rank)*data_size),
                #color = "white",
                alpha = 0.5
            ) +
            #geom_bin2d(data = plot_data,
            #               mapping = aes(x = x, y = y, color = keyword, size = as.numeric(rank)*data_size),
            #           binwidth = 3) +

            coord_fixed() +
            scale_x_continuous(limits = c(xmin, xmax)) +
            scale_y_continuous(limits = c(ymin, ymax)) +
            scale_size_continuous(limits = c(0, sizemax*10), range=c(1,30)) +
            #facet_wrap(. ~ keyword) +
            my_theme +
            theme(
                panel.grid = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                axis.text = element_blank(),
                axis.ticks = element_blank()
            ) -> p


        if (input$show_labels) {
            p <- p +
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
                )
        }
        p
    },
    height = function() {
        session$clientData$output_vis_width

    })


    # date selector ----
    output$ui_date_selector <- renderUI({
        all_data <- raw_data()
        start <- all_data$search_date %>% min()
        stop <- all_data$search_date %>% max()

        shiny::sliderInput("date_selector", label = "Pick a date",
                           min = start, max = stop, value = start,
                           timeFormat = "%d %b",
                           animate = animationOptions(interval = input$anim_speed))

        #dateInput("date_selector", label = "Pick a date", min = start, max = stop, value = stop)
    })

    output$ui_party_selector <- renderUI({
        all_data <- raw_data()
        all_data %>% pull(keyword) %>% unique() -> party_list

        shiny::selectInput("party_selector", label = "Pick Parties to visualize", choices = party_list, selected = party_list,
                           multiple = T, selectize = T)

    })
})






# # App ----
# shinyApp(
#     ui = dashboardPage(
#         dashboardHeader(title = "DataDonationVis"),
#         menu,
#         body
#     ),
#
#     server = server,
#
# )
