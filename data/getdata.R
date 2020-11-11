# This file downloads the data from the OSF

# set to true once the repositories go public
paper_is_published <- FALSE
# Libraries ----
library(tidyverse)
library(osfr)
library(here)


# READING RDS DATA FROM OSF

node_GUID <- "rwb9p"

if (!paper_is_published) {
  osf_auth()
}

# get node and download all files to the "data" directory of this project
node <- osf_retrieve_node(node_GUID)
files <-  osf_ls_files(node)
osf_download(files, path = here("data"), conflicts = "overwrite", progress = TRUE)

# CREATING CSV DATA ----
# If you need CSV data (warning large!) run these lines
if (FALSE) {

  afd <- readRDS(here("data", "datenspendeAfD.rds"))
  write_csv(afd, here("data", "datenspendeAFD.csv"))
  cdu <- readRDS(here("data","datenspendeAfD.rds"))
  write_csv(cdu, here("data", "datenspendeCDU.csv"))
}
