# 03_salmon.R -----------------------------------------------------------------
# Wild Atlantic salmon: annual conservation status of Scotland's assessed
# salmon stocks, 2021 to 2026 fishing seasons.
#
# Each year the Scottish Government assesses 173 stocks (single rivers or
# groups of rivers) under the Conservation of Salmon (Scotland) Regulations
# 2016. Status = probability of meeting the stock's conservation limit over
# five years:  Good >= 80%,  Moderate 60-80%,  Poor < 60% (mandatory catch
# and release).
#
# Sources (Scottish Government, OGL v3.0):
#   - "Salmon fishing: proposed river gradings for 2026 season" (tables with
#     2021 to 2025 gradings plus the proposed 2026 grading)
#   - "Salmon fishing: final river gradings for the 2026 season"
#
# Boundaries: the Salmon Stock Assessment Area polygons are not openly
# downloadable (they derive from CEH-licensed data), so rivers are mapped at
# their official outflow point (OS grid reference in the tables).
#
# Inputs:  data/raw/salmon/   (cached HTML, not committed)
# Outputs: data/processed/salmon_*.csv

library(here)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

if (!requireNamespace("rvest", quietly = TRUE)) renv::install("rvest")
library(rvest)

raw_dir  <- here("data", "raw", "salmon")
proc_dir <- here("data", "processed")
dir.create(file.path(raw_dir, "html"), recursive = TRUE, showWarnings = FALSE)

roots <- c(
  proposed = "https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/",
  final    = "https://www.gov.scot/publications/salmon-fishing-final-river-gradings/"
)

# 1. Download and cache the table pages ------------------------------------------
# gov.scot sometimes shows a bot check to scripts. If that happens, open each
# gradings page in your browser, File > Save Page As (HTML only), and save it
# into data/raw/salmon/html/ named proposed_<anything>.html or
# final_<anything>.html. The script will use those instead.

fetch <- function(url) {
  tryCatch(read_html(url), error = function(e) NULL)
}

cache_pages <- function(kind) {
  have <- list.files(file.path(raw_dir, "html"), pattern = paste0("^", kind, "_.*\\.html$"),
                     full.names = TRUE)
  real <- Filter(\(f) any(grepl("<table", readLines(f, warn = FALSE))), have)
  if (length(real)) return(invisible())
  root <- fetch(roots[[kind]])
  links <- if (is.null(root)) character(0) else root |> html_elements("a") |> html_attr("href")
  links <- unique(links[grepl("/pages/", links) & grepl("grading|to-", links)])
  links <- ifelse(startsWith(links, "http"), links, paste0("https://www.gov.scot", links))
  # The consultation's contents page does not link every table page, so add
  # the known page addresses (seen on gov.scot); 404s are skipped.
  if (kind == "proposed") {
    # Archived copies (National Records of Scotland web archive, raw "mp_" view)
    known <- c(
      "20260327035736mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-add-to-cree/",
      "20260327043031mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-creed-to-ewe/",
      "20260327051541mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-fincastle-to-glenelg/",
      "20260327055952mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-gour-to-iorsa/",
      "20260327063336mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-irvine-to-loch-long/",
      "20260327070539mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-loch-roag-to-ruel/",
      "20260327073744mp_/https://www.gov.scot/publications/salmon-fishing-proposed-river-gradings-for-2026-season/pages/gradings-sandra-to-ythan/"
    )
    known <- paste0("https://webarchive.nrscotland.gov.uk/public/", known)
    links <- unique(c(links, known))
  }
  for (u in links) {
    pg <- fetch(u)
    if (is.null(pg)) next
    slug <- basename(sub("/$", "", u))
    xml2::write_html(pg, file.path(raw_dir, "html", paste0(kind, "_", slug, ".html")))
    message("  saved ", kind, ": ", slug)
    Sys.sleep(1)   # be polite
  }
}

cache_pages("proposed")
cache_pages("final")

# 2. Parse tables -----------------------------------------------------------------------
norm_status <- function(x) {
  x <- str_squish(x)
  case_when(
    x %in% c("G", "Good", "1")     ~ "Good",
    x %in% c("M", "Moderate", "2") ~ "Moderate",
    x %in% c("P", "Poor", "3")     ~ "Poor",
    TRUE ~ NA_character_
  )
}

read_tables <- function(kind) {
  files <- list.files(file.path(raw_dir, "html"), pattern = paste0("^", kind, "_.*\\.html$"),
                      full.names = TRUE)
  if (!length(files)) stop("No ", kind, " pages found. See the manual route in section 1.",
                           call. = FALSE)
  # Skip pages that are bot checks rather than content
  files <- Filter(\(f) any(grepl("<table", readLines(f, warn = FALSE))), files)
  if (!length(files)) stop("No pages with tables found for ", kind, ". Save the pages from ",
                           "your browser instead (see section 1).", call. = FALSE)
  purrr::map_dfr(files, \(f) {
    tabs <- read_html(f) |> html_elements("table") |> html_table(convert = FALSE, header = FALSE)
    # gov.scot marks headers with <td> not <th>, so promote the first row
    tabs <- lapply(tabs, \(t) {
      if (nrow(t) > 1 && any(grepl("Outflow", unlist(t[1, ]), ignore.case = TRUE))) {
        names(t) <- make.unique(str_squish(unlist(t[1, ])))
        t <- t[-1, ]
      }
      t
    })
    tabs <- Filter(\(t) any(grepl("Outflow", names(t), ignore.case = TRUE)), tabs)
    purrr::map_dfr(tabs, \(t) janitor::clean_names(t) |> mutate(across(everything(), as.character)))
  })
}

prop  <- read_tables("proposed")
final <- read_tables("final")
message("Proposed-table rows: ", nrow(prop), "; final-table rows: ", nrow(final))
message("Proposed columns: ", paste(names(prop), collapse = ", "))
message("Final columns: ", paste(names(final), collapse = ", "))

year_cols <- grep("^x20(2[1-5])$", names(prop), value = TRUE)
col_2026p <- grep("^x2026", names(prop), value = TRUE)[1]
col_2026f <- grep("^x2026", names(final), value = TRUE)[1]

key <- \(d, r) paste(str_squish(d), str_squish(r), sep = " | ")

rivers <- prop |>
  transmute(district = str_squish(district), river = str_squish(river_name),
            outflow = str_squish(outflow_point),
            across(all_of(year_cols), norm_status, .names = "{.col}"),
            proposed_2026 = norm_status(.data[[col_2026p]])) |>
  filter(!is.na(river), river != "", !grepl("No individual river data", river)) |>
  distinct(district, river, .keep_all = TRUE) |>
  mutate(k = key(district, river))

fin <- final |>
  transmute(k = key(district, river_name), final_2026 = norm_status(.data[[col_2026f]])) |>
  distinct(k, .keep_all = TRUE)

rivers <- rivers |>
  left_join(fin, by = "k") |>
  mutate(x2026 = coalesce(final_2026, proposed_2026))

message("Rivers: ", nrow(rivers), ". Matched to final 2026 table: ",
        sum(!is.na(rivers$final_2026)), ". Final differs from proposed: ",
        sum(rivers$final_2026 != rivers$proposed_2026, na.rm = TRUE))

# 3. Stocks (assessment areas) ---------------------------------------------------
# Grouped rivers appear as "Group name - River name"; the group is the stock.
# Two quirks fixed here, found by checking against the official counts:
#   - one row uses an en dash ("Eishken Estate – ...") instead of a hyphen
#   - "North Harris SAC" spans two districts (Fincastle and Resort) but is
#     one stock, so grouped stocks are identified by name alone
rivers <- rivers |>
  mutate(river   = str_replace_all(river, " \u2013 ", " - "),
         grouped = str_detect(river, " - "),
         stock   = ifelse(grouped, str_extract(river, "^.*?(?= - )"), river),
         stock_id = ifelse(grouped, stock, key(district, stock)))

message("Distinct stocks: ", n_distinct(rivers$stock_id), " (official: 173)")

# 4. OS grid reference -> easting/northing -> lon/lat -----------------------------
gridref_to_en <- function(gr) {
  gr <- toupper(gsub("\\s+", "", gr))
  ok <- grepl("^[A-Z]{2}[0-9]{8}$", gr)
  out <- matrix(NA_real_, length(gr), 2, dimnames = list(NULL, c("E", "N")))
  if (!any(ok)) return(out)
  L <- "ABCDEFGHJKLMNOPQRSTUVWXYZ"           # no I
  l1 <- vapply(substr(gr[ok], 1, 1), \(ch) regexpr(ch, L, fixed = TRUE)[1] - 1, numeric(1))
  l2 <- vapply(substr(gr[ok], 2, 2), \(ch) regexpr(ch, L, fixed = TRUE)[1] - 1, numeric(1))
  e100 <- ((l1 - 2) %% 5) * 5 + (l2 %% 5)
  n100 <- (19 - floor(l1 / 5) * 5) - floor(l2 / 5)
  out[ok, "E"] <- e100 * 1e5 + as.numeric(substr(gr[ok], 3, 6)) * 10 + 5
  out[ok, "N"] <- n100 * 1e5 + as.numeric(substr(gr[ok], 7, 10)) * 10 + 5
  out
}

en <- gridref_to_en(rivers$outflow)
rivers$easting  <- en[, "E"]
rivers$northing <- en[, "N"]

pts <- rivers |>
  filter(!is.na(easting)) |>
  sf::st_as_sf(coords = c("easting", "northing"), crs = 27700, remove = FALSE) |>
  sf::st_transform(4326)
ll <- sf::st_coordinates(pts)
rivers <- rivers |>
  left_join(tibble(k = pts$k, lon = ll[, 1], lat = ll[, 2]), by = "k")

message("Rivers with a mappable outflow point: ", sum(!is.na(rivers$lon)))

# 5. Long format, transitions ---------------------------------------------------------
long <- rivers |>
  select(district, stock, stock_id, river, outflow, lon, lat, all_of(year_cols), x2026) |>
  pivot_longer(c(all_of(year_cols), x2026), names_to = "season", values_to = "status") |>
  mutate(season = as.integer(sub("x", "", season)))

first_season <- min(long$season)
stock_status <- long |>
  group_by(stock_id, stock, season) |>
  summarise(district = paste(sort(unique(district)), collapse = " / "),
            status = first(status), .groups = "drop") |>
  relocate(district, .after = stock_id)      # all rivers in a stock share a grade

transitions <- stock_status |>
  filter(season %in% c(first_season, 2026)) |>
  pivot_wider(names_from = season, values_from = status, names_prefix = "s") |>
  rename(from = 4, to = 5) |>
  count(from, to, name = "n_stocks")

# Official national counts, as published (consultation page summary table,
# 2026 = proposed). Kept separately as the authoritative headline.
national <- tibble::tribble(
  ~season, ~Good, ~Moderate, ~Poor, ~note,
  2021, 36, 35, 102, "",
  2022, 37, 35, 101, "",
  2023, 29, 31, 113, "",
  2024, 32, 29, 112, "",
  2025, 31, 24, 118, "",
  2026, 32, 26, 115, "proposed"
) |>
  pivot_longer(Good:Poor, names_to = "status", values_to = "n_stocks")

my_counts <- stock_status |> count(season, status, name = "my_n")
check <- national |> left_join(my_counts, by = c("season", "status")) |>
  mutate(diff = my_n - n_stocks)
message("\nCheck against official counts (my count minus official):")
print(check |> select(season, status, n_stocks, my_n, diff) |> pivot_wider(
  id_cols = season, names_from = status, values_from = diff))

# 6. Save ---------------------------------------------------------------------------------
write_csv(long,         file.path(proc_dir, "salmon_rivers_long.csv"))
write_csv(stock_status, file.path(proc_dir, "salmon_stocks_long.csv"))
write_csv(transitions,  file.path(proc_dir, "salmon_transitions.csv"))
write_csv(national,     file.path(proc_dir, "salmon_national.csv"))
write_csv(check,        file.path(proc_dir, "salmon_check.csv"))

message("\nDone. Outputs in data/processed/")
