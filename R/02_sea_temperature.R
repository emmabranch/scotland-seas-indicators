# 02_sea_temperature.R --------------------------------------------------------
# Sea temperature at the two long-term Scottish Coastal Observatory (SCObs)
# ecosystem monitoring sites: Stonehaven (east coast, North Sea) and
# Loch Ewe (west coast, sea loch).
#
# Data: weekly boat sampling, "Environmental data" CSVs (Marine Directorate,
# OGL v3.0). Published record: 1997 (Stonehaven) / 1999 (Loch Ewe) to 2020.
#
# Quality control (data owner's recommendations, SeaDataNet L20 flags):
#   reject QF 3 (probably bad), QF 4 (bad), QF 9 (missing)
#   keep   QF 0 (not yet QC'd), 1, 2, 5, 8; QF 10 kept but counted
#
# Method
#   1. Keep the shallowest sample per visit, if it is 5 m deep or less
#      ("near-surface").
#   2. Monthly means per site.
#   3. Monthly climatology (mean for each calendar month over the baseline
#      period) and anomalies = observed minus climatology. This removes the
#      seasonal cycle, so years can be compared fairly.
#   4. Annual mean anomaly for years with at least 9 of 12 months.
#   5. Linear trend in annual anomalies with a 95% confidence interval,
#      reported in degrees C per decade.
#
# Inputs:  data/raw/sea_temperature/  (not committed)
# Outputs: data/processed/sea_temp_*.csv

library(here)
library(dplyr)
library(tidyr)
library(readr)

raw_dir  <- here("data", "raw", "sea_temperature")
proc_dir <- here("data", "processed")
dir.create(raw_dir,  recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)

baseline   <- c(1999, 2020)   # common period covered by both sites
max_depth  <- 5               # metres: "near-surface"
min_months <- 9               # months needed for an annual mean

# 1. Download -------------------------------------------------------------------
sites <- tibble::tribble(
  ~site,        ~url,                                               ~doi,
  "Stonehaven", "https://data.marine.gov.scot/node/1986/download",  "10.7489/610-1",
  "Loch Ewe",   "https://data.marine.gov.scot/node/2061/download",  "10.7489/948-1"
)
# Stonehaven link confirmed on its resource page. Loch Ewe uses the same
# pattern with its resource node (2061). If either fails, download the
# "Environmental data" CSV by hand from
#   https://data.marine.gov.scot/dataset/scottish-coastal-observatory-stonehaven-site
#   https://data.marine.gov.scot/dataset/scottish-coastal-observatory-loch-ewe-site
# and save as data/raw/sea_temperature/Stonehaven_environmental.csv or
# LochEwe_environmental.csv

raw_file <- function(site) file.path(raw_dir, paste0(gsub(" ", "", site), "_environmental.csv"))

for (i in seq_len(nrow(sites))) {
  f <- raw_file(sites$site[i])
  if (!file.exists(f)) {
    message("Downloading ", sites$site[i], " ...")
    ok <- tryCatch({ download.file(sites$url[i], f, mode = "wb", quiet = TRUE); TRUE },
                   error = function(e) FALSE)
    first <- if (ok) readLines(f, n = 1, warn = FALSE) else ""
    if (!ok || !grepl("D1_", first)) {
      if (file.exists(f)) file.remove(f)
      stop("Download failed for ", sites$site[i], ". See the comment above for the manual route.",
           call. = FALSE)
    }
  }
}

# 2. Read and select columns by their D/F number -------------------------------
col_by_prefix <- function(df, prefix) {
  hit <- grep(paste0("^", prefix, "_"), names(df), value = TRUE)
  if (length(hit) != 1) stop("Expected one column starting ", prefix, ", found: ",
                             paste(hit, collapse = ", "), call. = FALSE)
  df[[hit]]
}

read_site <- function(site) {
  df <- read_csv(raw_file(site), na = c("NaN", "NA", ""), show_col_types = FALSE,
                 guess_max = 50000)
  tibble(
    site  = site,
    lat   = col_by_prefix(df, "D5"),
    lon   = col_by_prefix(df, "D6"),
    day   = col_by_prefix(df, "D10"),
    month = col_by_prefix(df, "D11"),
    year  = col_by_prefix(df, "D12"),
    depth = col_by_prefix(df, "D16"),
    temp  = col_by_prefix(df, "D17"),
    qf    = col_by_prefix(df, "F17")
  ) |>
    mutate(date = suppressWarnings(as.Date(sprintf("%d-%02d-%02d",
                                                    as.integer(year), as.integer(month),
                                                    as.integer(day)))))
}

obs <- purrr::map_dfr(sites$site, read_site)

# 3. Quality control ----------------------------------------------------------------
reject_qf <- c(3, 4, 9)

qc_summary <- obs |>
  mutate(outcome = case_when(
    qf %in% reject_qf ~ paste0("Rejected (QF ", qf, ")"),
    is.na(temp)       ~ "Rejected (no value)",
    qf == 10          ~ "Kept, use with caution (QF 10)",
    qf == 0           ~ "Kept, not yet quality controlled (QF 0)",
    TRUE              ~ "Kept (QF 1, 2, 5, 8)"
  )) |>
  count(site, outcome, name = "n") |>
  group_by(site) |>
  mutate(pct = 100 * n / sum(n)) |>
  ungroup()

message("\nQuality control outcome (all depths):")
print(qc_summary, n = Inf)

clean <- obs |> filter(!qf %in% reject_qf, !is.na(temp), !is.na(date))

message("\nSample depths after QC (m), first 40 rows:")
print(clean |> count(site, depth) |> arrange(site, depth), n = 40)

# 4. Near-surface: shallowest sample per visit, if <= max_depth ------------------
surface <- clean |>
  group_by(site, date) |>
  slice_min(depth, n = 1, with_ties = FALSE) |>
  ungroup() |>
  filter(depth <= max_depth)

# Plausibility screen for anything the flags missed
odd <- surface |> filter(temp < 0 | temp > 22)
if (nrow(odd)) {
  message("\nImplausible values removed:")
  print(odd)
  surface <- surface |> filter(temp >= 0, temp <= 22)
}

# 5. Monthly means, climatology, anomalies ---------------------------------------
monthly <- surface |>
  group_by(site, year, month) |>
  summarise(temp = mean(temp), n_obs = n(), .groups = "drop")

clim <- monthly |>
  filter(between(year, baseline[1], baseline[2])) |>
  group_by(site, month) |>
  summarise(clim = mean(temp), clim_sd = sd(temp), .groups = "drop")

monthly <- monthly |>
  left_join(clim, by = c("site", "month")) |>
  mutate(anom = temp - clim,
         date = as.Date(sprintf("%d-%02d-15", as.integer(year), as.integer(month))))

annual <- monthly |>
  group_by(site, year) |>
  summarise(n_months = n(), anom = mean(anom), temp = mean(temp), .groups = "drop") |>
  filter(n_months >= min_months)

# 6. Trends ---------------------------------------------------------------------
fit_trend <- function(d) {
  m  <- lm(anom ~ year, data = d)
  ci <- confint(m)["year", ]
  # lag-1 autocorrelation of residuals, reported so readers can judge the CI
  r1 <- acf(residuals(m), plot = FALSE, lag.max = 1)$acf[2]
  tibble(
    first_year   = min(d$year), last_year = max(d$year), n_years = nrow(d),
    slope_decade = 10 * coef(m)[["year"]],
    lo_decade    = 10 * ci[[1]], hi_decade = 10 * ci[[2]],
    p_value      = summary(m)$coefficients["year", 4],
    resid_lag1   = r1
  )
}

trends <- annual |>
  group_by(site) |>
  group_modify(\(d, ...) fit_trend(d)) |>
  ungroup()

site_info <- surface |>
  group_by(site) |>
  summarise(lat = median(lat, na.rm = TRUE), lon = median(lon, na.rm = TRUE),
            first = min(date), last = max(date), n_visits = n_distinct(date),
            median_depth = median(depth), .groups = "drop") |>
  left_join(sites |> select(site, doi), by = "site")

message("\nSites:")
print(site_info)
message("\nTrend in annual mean near-surface temperature anomaly (degrees C per decade):")
print(trends |> mutate(across(where(is.numeric), \(x) round(x, 3))))

# 7. Save ---------------------------------------------------------------------------
write_csv(monthly,    file.path(proc_dir, "sea_temp_monthly.csv"))
write_csv(annual,     file.path(proc_dir, "sea_temp_annual.csv"))
write_csv(trends,     file.path(proc_dir, "sea_temp_trends.csv"))
write_csv(qc_summary, file.path(proc_dir, "sea_temp_qc.csv"))
write_csv(site_info,  file.path(proc_dir, "sea_temp_sites.csv"))

message("\nDone. Outputs in data/processed/")
