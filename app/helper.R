### helper functions for the app


create_summary_data <- function() {

  library(tidyverse)
  filenames <- dir(here::here("data"), pattern = "*.rds", full.names = T)

  all_data <- NULL
  for (file in filenames) {
    all_data <- bind_rows(all_data, read_rds(file))

  }

  all_data <- all_data %>%
    mutate(search_date = lubridate::as_date(search_date)) %>% # Fix date as only days
    mutate(domain = str_replace_all(domain, "^[.](.+)", "\\1")) %>%  # fix some broken domains
    mutate(url = str_replace_all(url, "^[.](.+)", "\\1")) %>%
    mutate(url = str_remove(url, pattern = "&sa=.*$")) # remove left over google analytics url fragments

  all_data %>% group_by(keyword, country, search_date, url, domain) %>%
    filter(rank < 20) %>%
    summarise(rank = sum(1/(rank + 1))) %>%
    ungroup() %>%
    #ggplot() + aes(x = rank) + geom_histogram() + scale_x_log10()
  write_rds("data/summary_data.RDS", compress = "xz")
}


my_theme <- theme(
  plot.background = element_rect(fill = "grey50", color = "grey50"),
  plot.title = element_text(color = "white"),
  plot.subtitle = element_text(color = "white"),
  plot.margin = margin(15, 15, 15, 15),
  plot.caption = element_text(color = "white"),
  panel.background = element_rect(fill = "grey30", color = "grey50"),
  panel.grid = element_line(color = "grey50", size = 1),
  axis.title.x = element_text(color = "white"),
  axis.title.y = element_text(color = "white"),
  axis.text = element_text(color = "white"),
  legend.position = "None"
)



