# theme_seas.R ---------------------------------------------------------------
# Shared look for every chart and map, plus the status vocabulary.
# Colours are from the Okabe-Ito palette (colour-blind safe). Status is never
# shown by colour alone: every status also has an icon and a word.

library(ggplot2)

seas_cols <- c(
  deep    = "#0B3C5D",
  shallow = "#328CC1",
  sand    = "#E8DCC4",
  grey    = "#8C8C8C",
  # Okabe-Ito
  orange  = "#E69F00",
  sky     = "#56B4E9",
  green   = "#009E73",
  yellow  = "#F0E442",
  blue    = "#0072B2",
  red     = "#D55E00",
  purple  = "#CC79A7"
)

# Categorical palette for series (Okabe-Ito order, minus yellow for contrast)
seas_qual <- unname(seas_cols[c("blue", "orange", "green", "red", "purple", "sky")])

# Status vocabulary used on the report card and every indicator page.
# Wording is deliberately cautious: this is an independent summary, not an
# official assessment.
status_key <- tibble::tribble(
  ~status,        ~label,                     ~icon, ~col,
  "good",         "Generally positive",       "✓",   "#009E73",
  "mixed",        "Mixed or some concern",    "◐",   "#E69F00",
  "poor",         "Clear concern",            "✕",   "#D55E00",
  "context",      "Context indicator",        "i",   "#56B4E9",
  "unknown",      "Not yet assessed",         "?",   "#8C8C8C"
)

trend_key <- tibble::tribble(
  ~trend,        ~trend_label,     ~arrow,
  "improving",   "Improving",      "↗",
  "stable",      "No clear change","→",
  "declining",   "Declining",      "↘",
  "context",     "Context indicator (no good/bad direction)", "↔",
  "unknown",     "Trend not yet assessed", "·"
)

conf_dots <- function(conf) {
  n <- match(conf, c("low", "medium", "high"))
  ifelse(is.na(n), "○○○", paste0(strrep("●", n), strrep("○", 3 - n)))
}

theme_seas <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.title    = element_text(face = "bold", colour = seas_cols[["deep"]]),
      plot.subtitle = element_text(colour = "#33414E", margin = margin(b = 8)),
      plot.caption  = element_text(colour = "#5A6B7B", size = rel(0.75), hjust = 0),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.title = element_text(colour = "#33414E"),
      legend.position = "top",
      legend.justification = "left"
    )
}

# Caption helper so every chart credits its source the same way
seas_caption <- function(source, licence = "Open Government Licence v3.0") {
  paste0("Source: ", source, ". ", licence, ".\nIndependent analysis by Emma Branch.")
}
