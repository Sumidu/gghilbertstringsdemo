# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
# This file upload all html output to the OSF repository

# Setup ----
library(osfr)
library(rmarkdown)
osf_auth()

## Paramters ----
anon_folder <- "output/anonymized_html/"
normal_folder <- "output/html/"
normal_authors <- list(authors = "Poornima Belavadi, Nils Plettenberg, Johannes Nakayama, André Calero Valdez")
anon_params <- list(authors = "Anonymized")

# Remove all html output ----
delfiles <- c(dir(anon_folder, patter = "*.html", full.names = TRUE),
              dir(normal_folder, patter = "*.html", full.names = TRUE))
unlink(delfiles)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
# Render files ----

# Which files to render?
rmds <- c("00_Teaser.Rmd", "15_Figure_Hilbert_Order.Rmd", "20_Compare_Performance.Rmd", "30_Spatial_Stability.Rmd", "40_Demonstration.Rmd")

#render files in to versions
for (rmd in rmds) {
  rmarkdown::render(rmd, output_dir = anon_folder, params = anon_params)
  rmarkdown::render(rmd, output_dir = normal_folder, params = normal_authors)

}

beep(2)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
# Upload files to OSF ----

# Anonymized folder
node <- osf_retrieve_node("d3u5z")
files <- dir(path = anon_folder, pattern = "*.html", full.names = TRUE)
osf_upload(x = node, path = files, progress = TRUE, conflicts = "overwrite")

# Normal folder
node <- osf_retrieve_node("y2gqt")
files <- dir(path = normal_folder, pattern = "*.html", full.names = TRUE)
osf_upload(x = node, path = files, progress = TRUE, conflicts = "overwrite")


beep(2)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
# Upload figures to sharelatex ----
### FIX THIS

# move all files to sharelatex

if (FALSE) {
target_folder <- "~/Dropbox/Apps/ShareLaTeX/2021 Eurovis - HilbertVisualization (Fullpaper)/figures/"
files <- dir("output/", pattern = "*.png|*.pdf", full.names = TRUE)
  file.copy(files,
            target_folder, overwrite = TRUE)
}

beepr::beep(2)
