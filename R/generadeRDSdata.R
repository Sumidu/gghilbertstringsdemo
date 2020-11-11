# This file contains old code to generate the datasets from a non-public source.
# We share it only to be transparent in how the RDS files were generated.


# where is the data?
pth <- here::here("data")
# should I recreate the data from original raw CSV data?
create_rds_files_from_csv <- FALSE



# get all entry names for file system
get_terms <- function(){
  #files <- dir(pth, pattern = ".*csv")
  #terms <- str_match(files,"(.*)_.{2}.csv")[,2] %>% unique()
  #terms
  c("AfD", "CDU")
}


# function to write a term file in XZ compressed format
write_terms_rds <- function(term){
  stop("This function only works when the raw data is available, which is not shared in this repository.")
  options(readr.show_progress = FALSE)
  #read files
  files <- dir(pth, pattern = paste0(".*",term,".*.csv"), full.names = T)
  all_data <- NULL
  # setup progress bar
  pb <- progress_bar$new(
    format = paste("Reading", term, "[:bar] :percent eta: :eta"),
    total = length(files), clear = FALSE, width = 100)

  # read files
  for (file in files) {
    suppressMessages(
      suppressWarnings(
        file_data <- read_csv(file) %>% dplyr::rename(uuid = X1)
      )
    )

    all_data <- bind_rows(all_data, file_data)
    pb$tick()
  }

  message("Term: ", term, " has ", nrow(all_data), " entries. Compressing file ...")
  write_rds(all_data, here::here("debugging", paste0("datenspende",term, ".rds")), compress = "xz")
  message("Done.")
  options(readr.show_progress = TRUE)
}



# start converting data ----

terms <- get_terms()

if (create_rds_files_from_csv) {
  # run only on subset?
  term_selection <- terms #head(terms)
  i <- 1

  total <- length(term_selection)
  for (term in term_selection) {
    print(glue("Running {i} of {total} {Sys.time()}"))
    write_terms_rds(term)
    i <- i + 1
  }
}
# make noise when done! Takes a while
beep()

terms
