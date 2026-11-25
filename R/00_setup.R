# 00_setup.R -----------------------------------------------------------------
# Run once, from the project root, after cloning.
# Installs packages into a project library with renv so the site is reproducible.

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

# Only initialise once (creates renv/ and .Rprofile). Safe to re-run.
if (!file.exists("renv/activate.R")) {
  renv::init(bare = TRUE, restart = FALSE)
} else {
  renv::load()
}

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

renv::install(pkgs, prompt = FALSE)

missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("These packages failed to install: ", paste(missing, collapse = ", "),
                          "\nScroll up for the first error message.")

renv::snapshot(type = "all", prompt = FALSE)

message("Setup complete. Next: quarto preview")
