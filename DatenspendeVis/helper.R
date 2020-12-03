### helper functions for the app


getData <- function() {


  filenames <- dir(here::here("data"), pattern = "*.rds", full.names = T)

  all_data <- NULL
  for (file in filenames) {
    all_data <- bind_rows(all_data, read_rds(file))

  }

  all_data <- all_data %>%
    mutate(search_date = as_date(search_date)) %>% # Fix date as only days
    mutate(domain = str_replace_all(domain, "^[.](.+)", "\\1")) %>%  # fix some broken domains
    mutate(url = str_replace_all(url, "^[.](.+)", "\\1"))

  all_data
}


d <- getData()

