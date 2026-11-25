# 04_seals.R ------------------------------------------------------------------
# Harbour and grey seal August counts by Seal Management Unit (SMU),
# six national census periods from 1996-97 to 2021-25.
#
# Source: Morris, C.D., Duck, C.D., Riddoch, N.G., Thompson, D. and
# Russell, D.J.F. (2026). Aerial surveys of seals in Scotland during the
# harbour seal moult, 2021-2025. NatureScot Research Report 1421.
#   Table 2: harbour seal counts by SMU and census period
#   Table 3: harbour seal trend results by SMU and SAC
#   Table 6: grey seal counts by SMU and census period
#
# Boundaries: Seal Management Areas (Marine Directorate / SMRU, OGL).
#
# Important: these are counts of seals hauled out on land during the August
# moult, not total population size. Total population is estimated by scaling
# counts for the proportion of seals hauled out (the report does this for
# the latest period only).
#
# Inputs:  data/raw/seals/   (not committed)
# Outputs: data/processed/seals_*.csv, seals_map.gpkg

library(here)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(rvest)
library(sf)

raw_dir  <- here("data", "raw", "seals")
proc_dir <- here("data", "processed")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)

# 1. Report tables ------------------------------------------------------------------
report_url <- "https://www.nature.scot/doc/naturescot-research-report-1421-aerial-surveys-seals-scotland-during-harbour-seal-moult-2021-2025"
report_html <- file.path(raw_dir, "naturescot_rr1421.html")

if (!file.exists(report_html) || !any(grepl("<table", readLines(report_html, warn = FALSE)))) {
  message("Downloading NatureScot Research Report 1421 ...")
  pg <- tryCatch(read_html(report_url), error = function(e) NULL)
  if (is.null(pg)) stop("Could not download the report page. Open it in your browser, ",
                        "save as 'Webpage, HTML Only' to ", report_html, call. = FALSE)
  xml2::write_html(pg, report_html)
}

tabs <- read_html(report_html) |> html_elements("table") |> html_table(convert = FALSE)
message("Tables found in report: ", length(tabs))

is_census <- \(t) any(grepl("1996", names(t))) && any(grepl("2021", names(t)))
census_tabs <- Filter(is_census, tabs)
if (length(census_tabs) < 2) stop("Expected two census tables (harbour and grey seals), found ",
                                  length(census_tabs), call. = FALSE)

num <- \(x) suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))

tidy_census <- function(t, species) {
  names(t) <- str_squish(names(t))
  names(t)[1] <- "unit"
  period_cols <- grep("^(19|20)[0-9]{2}\\s*-\\s*(19|20)[0-9]{2}$", names(t), value = TRUE)
  t |>
    mutate(unit = str_squish(unit)) |>
    filter(unit != "") |>
    select(unit, all_of(period_cols)) |>
    pivot_longer(-unit, names_to = "period", values_to = "count") |>
    mutate(count   = num(count),
           species = species,
           period  = str_replace_all(period, "\\s", ""),
           start   = as.integer(substr(period, 1, 4)),
           end     = as.integer(substr(period, 6, 9)),
           mid     = (start + end) / 2,
           smu_no  = str_extract(unit, "^[0-9]+[a-z]?"),
           level   = case_when(unit == "Scotland total" | grepl("^Scotland", unit) ~ "Scotland",
                               grepl("^[0-9]+[a-z]$", smu_no) ~ "Subdivision",
                               !is.na(smu_no) ~ "SMU",
                               TRUE ~ "Other"),
           smu_name = str_squish(str_remove(unit, "^[0-9]+[a-z]?\\s*")))
}

counts <- bind_rows(
  tidy_census(census_tabs[[1]], "Harbour seal"),
  tidy_census(census_tabs[[2]], "Grey seal")
)

# Population estimates for the latest period (harbour and grey)
tidy_estimates <- function(t, species) {
  names(t) <- str_squish(names(t)); names(t)[1] <- "unit"
  est <- grep("pop", names(t), ignore.case = TRUE, value = TRUE)[1]
  ci  <- grep("confidence", names(t), ignore.case = TRUE, value = TRUE)[1]
  t |>
    transmute(species = species, unit = str_squish(unit),
              estimate = num(.data[[est]]),
              ci = str_squish(.data[[ci]]))
}
estimates <- bind_rows(tidy_estimates(census_tabs[[1]], "Harbour seal"),
                       tidy_estimates(census_tabs[[2]], "Grey seal"))

# Checks against the report's stated totals
chk <- counts |> filter(level == "Scotland", period == "2021-2025")
message("\nScotland totals 2021-2025 (report: harbour 19,978; grey 16,042):")
print(chk |> select(species, count))
stopifnot(isTRUE(all.equal(sort(chk$count), sort(c(19978, 16042)))))

# Harbour seal trend table (Table 3), kept as published
trend_tab <- Filter(\(t) any(grepl("Change since", names(t), ignore.case = TRUE)), tabs)
trend <- if (length(trend_tab)) {
  t <- trend_tab[[1]]; names(t) <- make.unique(str_squish(names(t))); t
} else tibble()
message("Trend table rows: ", nrow(trend))

# 2. Change between census periods ---------------------------------------------------
change <- counts |>
  filter(level %in% c("SMU", "Scotland")) |>
  group_by(species, unit, smu_no, smu_name, level) |>
  arrange(start, .by_group = TRUE) |>
  summarise(
    first_count  = first(count),
    prev_count   = nth(count, -2),
    latest_count = last(count),
    pct_vs_prev  = 100 * (latest_count / prev_count - 1),
    pct_vs_first = 100 * (latest_count / first_count - 1),
    .groups = "drop"
  )

print(change |> filter(species == "Harbour seal") |>
        mutate(across(starts_with("pct"), \(x) round(x))) |>
        select(unit, first_count, prev_count, latest_count, pct_vs_prev, pct_vs_first))

# 3. Seal Management Area boundaries ---------------------------------------------------
# Public download link pattern from the data.gov.uk / spatialdata.gov.scot
# catalogue (same service and token as the MPA assessment areas).
sma_dir <- file.path(raw_dir, "seal_management_areas")
dir.create(sma_dir, showWarnings = FALSE)
sma_url <- paste0(
  "https://msmap1.atkinsgeospatial.com/geoserver/nmpwfs/ows?",
  "token=d46ffd2a-e192-4e51-8a6a-b3292c20f1ee&service=wfs&request=getFeature",
  "&typeName=nmpwfs:area_management_seal_management_areas",
  "&outputFormat=shape-zip&srsName=EPSG:4326")

shp <- list.files(sma_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
if (!length(shp)) {
  zip <- file.path(sma_dir, "sma.zip")
  ok <- tryCatch({ download.file(sma_url, zip, mode = "wb", quiet = TRUE); unzip(zip, exdir = sma_dir); TRUE },
                 error = function(e) FALSE)
  shp <- list.files(sma_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
  if (!length(shp)) message("Could not download Seal Management Areas; the page will skip the map. ",
                            "Manual route: https://www.data.gov.uk/dataset/area-management-seal-licensing-seal-management-areas")
}

if (length(shp)) {
  sma <- st_read(shp[1], quiet = TRUE) |> st_make_valid()
  message("Seal Management Areas columns: ", paste(names(sma), collapse = ", "))
  name_col <- names(sma)[sapply(sma, \(x) is.character(x) && any(grepl("Shetland", x)))][1]
  message("Area name column: ", name_col, ". Values: ",
          paste(sort(unique(sma[[name_col]])), collapse = "; "))

  # Match area names to SMU numbers in the report
  lookup <- c("South West Scotland" = "1", "Southwest Scotland" = "1",
              "West Scotland" = "2", "Western Isles" = "3",
              "Orkney and North Coast" = "4", "North Coast and Orkney" = "4", "Orkney & North Coast" = "4",
              "Shetland" = "5", "Moray Firth" = "6",
              "East Coast" = "7", "East Scotland" = "7")
  sma <- sma |>
    mutate(area_name = str_squish(.data[[name_col]]),
           # Prefer the file's own SMU number; fall back to matching names
           smu_no = if ("smuno" %in% names(sma)) as.character(as.integer(smuno))
                    else unname(lookup[area_name])) |>
    group_by(smu_no, area_name) |>
    summarise(geometry = st_union(geometry), .groups = "drop") |>
    st_simplify(dTolerance = 0.005, preserveTopology = TRUE)

  if (any(is.na(sma$smu_no))) warning("Unmatched area names: ",
                                      paste(sma$area_name[is.na(sma$smu_no)], collapse = ", "))
  map_file <- file.path(proc_dir, "seals_map.gpkg")
  if (file.exists(map_file)) invisible(file.remove(map_file))
  st_write(sma, map_file, quiet = TRUE)
}

# 4. Save ---------------------------------------------------------------------------------
write_csv(counts,    file.path(proc_dir, "seals_counts.csv"))
write_csv(change,    file.path(proc_dir, "seals_change.csv"))
write_csv(estimates, file.path(proc_dir, "seals_estimates.csv"))
write_csv(trend,     file.path(proc_dir, "seals_trend_table.csv"))

message("\nDone. Outputs in data/processed/")
