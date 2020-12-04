# move all files to sharelatex

target_folder <- "~/Dropbox/Apps/ShareLaTeX/2021 Eurovis - HilbertVisualization (Fullpaper)/figures/"


files <- dir("output/", pattern = "*.png|*.pdf", full.names = TRUE)

if (FALSE) {
  file.copy(files, target_folder, overwrite = TRUE)
}
