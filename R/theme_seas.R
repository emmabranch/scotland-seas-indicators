# theme_seas.R ---------------------------------------------------------------
# Shared look for every chart and map, plus the status vocabulary.
# Colours are from the Okabe-Ito palette (colour-blind safe). Status is never
# shown by colour alone: every status also has an icon and a word.

library(ggplot2)
source(here::here("R", "theme_eb.R"))   # shared portfolio chart style (copy of _brand-kit/R/theme_eb.R)
eb_use("scotland-seas-indicators")      # fonts and the seaweed olive accent

# Chart colours. Status colours (Okabe-Ito, colour-blind safe) are kept as they were,
# because they carry meaning on the report card; everything else uses the shared kit.
seas_cols <- c(
  deep    = "#111111",            # ink: reference lines and labels
  accent  = "#5f6b1e",            # seaweed olive
  accent2 = "#a7b544",
  accent3 = "#dbe58a",
  grey    = "#C9C1B3",            # context
  cobalt  = "#2340FF",
  cobalt_light = "#8A9BEA",
  down    = "#A3241A",            # decline / warmer (diverging ends)
  up      = "#1F33B5",            # increase / cooler
  # Okabe-Ito, for status only
  orange  = "#E69F00",
  sky     = "#56B4E9",
  green   = "#009E73",
  yellow  = "#F0E442",
  blue    = "#0072B2",
  red     = "#D55E00",
  purple  = "#CC79A7"
)

# Categorical palette for series: the shared kit fills
seas_qual <- eb_cat_fill

# Seas maps: the shared grey basemap
seas_basemap <- "Esri.WorldGrayCanvas"

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

theme_seas <- function(base_size = 13, ...) {
  theme_eb(base_size = base_size, ...)
}

# Caption helper so every chart credits its source the same way
seas_caption <- function(source, licence = "Open Government Licence v3.0") {
  paste0("Source: ", source, ". ", licence, ".\nIndependent analysis by Emma Branch.")
}
