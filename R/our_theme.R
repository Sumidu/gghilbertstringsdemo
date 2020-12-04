# The theme used in this project

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
