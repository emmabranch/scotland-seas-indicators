# 00_setup.R -----------------------------------------------------------------
# Run once, from the project root, after cloning.
# Installs packages into a project library with renv so the site is reproducible.

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

# Only initialise once (creates renv.lock and renv/)
if (!file.exists("renv.lock")) renv::init(bare = TRUE)

pkgs <- c(
  # core
  "here", "readr", "readxl", "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "janitor", "glue",
  # spatial
  "sf", "units", "leaflet", "leaflet.extras",
  # charts and tables
  "ggplot2", "scales", "ggiraph", "patchwork", "gt", "reactable",
  # site helpers
  "htmltools", "knitr", "rmarkdown",
  # downloads
  "httr2"
)

renv::install(pkgs)
renv::snapshot(prompt = FALSE)

message("Setup complete. Next: quarto preview")
