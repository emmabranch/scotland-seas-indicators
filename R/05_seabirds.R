# 05_seabirds.R ---------------------------------------------------------------
# Featured deep dive: seabirds after the 2021-22 HPAI outbreak.
#
# Source: Tremlett, C.J., Morley, N. and Wilson, L.J. (2024). UK seabird
# colony counts in 2023 following the 2021-22 outbreak of Highly Pathogenic
# Avian Influenza. RSPB Research Report 76.
#   Pre-outbreak baselines are mainly from Seabirds Count (2015-2021).
#   2023 counts are from the coordinated HPAI seabird survey.
#
# The report publishes SPA-level tables only in PDF, so the Scottish rows
# are transcribed by hand into data/lookup/seabirds_rr76_*.csv with the table
# and page they came from. Check each row against the PDF and set
# verified = TRUE before publishing.
#
# Epidemiological framing
#   - Measure: % change in breeding count at the same surveyed sites,
#     baseline vs 2023 (a before-after comparison with no control group).
#   - Uncertainty: a Poisson 95% CI for the count ratio. This reflects
#     counting noise only. Observer error, survey timing, and site coverage
#     add more uncertainty, so these intervals are a MINIMUM.
#   - Secular trend: for Gannet the report also gives a predicted 2021
#     baseline (pre-outbreak growth projected forward). Comparing the two
#     shows how sensitive the answer is to the choice of baseline.
#
# Inputs:  data/lookup/seabirds_rr76_*.csv
#          data/raw/mpas/spa/  (SPA boundaries, downloaded by 01_mpas.R)
# Outputs: data/processed/seabirds_*.csv, seabirds_spa_points.csv

library(here)
library(dplyr)
library(readr)
library(stringr)
library(sf)

lk <- \(f) here("data", "lookup", f)
proc_dir <- here("data", "processed")

spa_tab <- read_csv(lk("seabirds_rr76_scotland_spa.csv"), show_col_types = FALSE)
uk_tab  <- read_csv(lk("seabirds_rr76_uk_summary.csv"),  show_col_types = FALSE)

n_unverified <- sum(!spa_tab$verified) + sum(!uk_tab$verified)
if (n_unverified > 0) message("NOTE: ", n_unverified,
  " transcribed rows are not yet marked verified against the PDF.")

# 1. Transcription checks against totals printed in the report -----------------
skua <- spa_tab |> filter(species == "Great Skua")
stopifnot(sum(skua$baseline) == 6570, sum(skua$count_2023) == 1524)   # Table 9 total row
message("Great Skua rows match the Table 9 totals (6,570 and 1,524).")

# 2. Change with a Poisson (counting-noise-only) 95% CI ----------------------
ratio_ci <- function(a, b) {
  # a = 2023 count, b = baseline. log(a/b) has variance 1/a + 1/b (Poisson).
  se <- sqrt(1 / pmax(a, 0.5) + 1 / pmax(b, 0.5))
  rr <- a / b
  tibble(pct = 100 * (rr - 1),
         lo  = 100 * (exp(log(pmax(rr, 1e-9)) - 1.96 * se) - 1),
         hi  = 100 * (exp(log(pmax(rr, 1e-9)) + 1.96 * se) - 1))
}

spa_change <- spa_tab |>
  bind_cols(ratio_ci(spa_tab$count_2023, spa_tab$baseline)) |>
  mutate(small = baseline < 50,
         low_conf = !is.na(note) & grepl("low confidence|preliminary", note, ignore.case = TRUE))

# Totals across surveyed Scottish SPAs, by species
# Gannet colonies are counted as nests (AON) or sites (AOS); the report
# combines them, so units are pooled within species here too.
species_tot <- spa_tab |>
  group_by(species) |>
  summarise(unit = paste(sort(unique(unit)), collapse = "/"),
            n_spa = n(), baseline = sum(baseline), count_2023 = sum(count_2023), .groups = "drop") |>
  (\(d) bind_cols(d, ratio_ci(d$count_2023, d$baseline)))()

# 3. Gannet: sensitivity to the choice of baseline --------------------------------
gannet <- spa_tab |>
  filter(species == "Northern Gannet") |>
  transmute(spa, baseline_year, baseline, predicted_2021, count_2023, note,
            pct_observed_baseline = 100 * (count_2023 / baseline - 1),
            pct_trend_adjusted    = 100 * (count_2023 / predicted_2021 - 1))

gannet_tot <- gannet |>
  summarise(baseline = sum(baseline), predicted_2021 = sum(predicted_2021),
            count_2023 = sum(count_2023)) |>
  mutate(pct_observed_baseline = 100 * (count_2023 / baseline - 1),
         pct_trend_adjusted    = 100 * (count_2023 / predicted_2021 - 1))

message("\nScottish SPA totals by species:")
print(species_tot |> mutate(across(c(pct, lo, hi), round)))
message("\nGannet, six Scottish SPAs: change vs observed baseline ",
        round(gannet_tot$pct_observed_baseline), "%, vs trend-adjusted 2021 baseline ",
        round(gannet_tot$pct_trend_adjusted), "%")

# 4. Locate SPAs (centroids of NatureScot SPA boundaries) --------------------
norm <- \(x) x |> str_to_lower() |> str_replace_all("[–—-]", " ") |>
  str_replace_all("[^a-z ]", "") |> str_squish()

spa_file <- list.files(here("data", "raw", "mpas", "spa"), pattern = "\\.gpkg$",
                       recursive = TRUE, full.names = TRUE)[1]
if (is.na(spa_file)) stop("SPA boundaries not found. Run R/01_mpas.R first.", call. = FALSE)

spa_poly <- st_read(spa_file, quiet = TRUE) |>
  st_zm(drop = TRUE) |>
  st_make_valid() |>
  mutate(key = norm(NAME)) |>
  group_by(key, NAME) |>
  summarise(.groups = "drop")          # sf unions the geometry within each group

cent <- suppressWarnings(st_point_on_surface(spa_poly)) |> st_transform(4326)
xy <- st_coordinates(cent)
spa_pts <- tibble(key = cent$key, spa_official = cent$NAME, lon = xy[, 1], lat = xy[, 2])

spa_change <- spa_change |>
  mutate(key = norm(spa)) |>
  left_join(spa_pts, by = "key")

unmatched <- unique(spa_change$spa[is.na(spa_change$lon)])
if (length(unmatched)) {
  message("\nSPAs not matched to boundaries (check names): ", paste(unmatched, collapse = "; "))
} else message("\nAll SPAs matched to NatureScot SPA boundaries.")

# 5. Save ---------------------------------------------------------------------------------
write_csv(spa_change,  file.path(proc_dir, "seabirds_spa_change.csv"))
write_csv(species_tot, file.path(proc_dir, "seabirds_species_totals.csv"))
write_csv(gannet,      file.path(proc_dir, "seabirds_gannet_sensitivity.csv"))
write_csv(gannet_tot,  file.path(proc_dir, "seabirds_gannet_totals.csv"))
write_csv(uk_tab,      file.path(proc_dir, "seabirds_uk_summary.csv"))

message("\nDone. Outputs in data/processed/")
