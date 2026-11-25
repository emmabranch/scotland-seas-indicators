# 01_mpas.R ------------------------------------------------------------------
# MPA coverage: what share of Scottish seas lies inside designated MPAs?
#
# Approach
#   1. Download site boundaries (NatureScot inshore + JNCC offshore).
#   2. Download the Scottish assessment areas (11 inshore Scottish Marine
#      Regions + 10 offshore marine regions = "Scottish seas").
#   3. Reproject to British National Grid (EPSG:27700), repair geometry.
#   4. Dissolve all sites into one footprint so overlapping designations
#      (e.g. an SPA on top of an SAC) are only counted once.
#   5. Clip to Scottish seas (this also removes the land parts of coastal
#      SACs and SPAs) and calculate % designated overall and by region.
#   6. Compare with the published figure as a sanity check.
#
# Inputs:  data/raw/mpas/   (not committed)
# Outputs: data/processed/mpas_summary.csv
#          data/processed/mpas_by_region.csv
#          data/processed/mpas_by_type.csv
#          data/processed/mpas_map.gpkg   (simplified, for the web map)

library(here)
library(dplyr)
library(sf)

sf_use_s2(FALSE)   # planar maths in EPSG:27700 (metres) is right for area here

raw_dir  <- here("data", "raw", "mpas")
proc_dir <- here("data", "processed")
dir.create(raw_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(proc_dir, recursive = TRUE, showWarnings = FALSE)
options(timeout = 900)

# 1. Download ----------------------------------------------------------------
# All OGL v3.0. Checked 25 Nov 2026.
sources <- tibble::tribble(
  ~id,        ~type,                            ~url,
  "ncmpa",    "Nature Conservation MPA",        "https://gis-downloads.nature.scot/MPA_SCOTLAND_GPKG_27700.zip",
  "sac",      "Special Area of Conservation",   "https://gis-downloads.nature.scot/SAC_SCOTLAND_GPKG_27700.zip",
  "spa",      "Special Protection Area",        "https://gis-downloads.nature.scot/SPA_SCOTLAND_GPKG_27700.zip",
  "offshore", "Offshore MPA (JNCC, all types)", "https://data.jncc.gov.uk/data/ade43f34-54d6-4084-b66a-64f0b4a5ef27/c20251203-OffshoreMPAs-WGS84.zip"
)
# The NC MPA, SPA, and JNCC links were confirmed on their catalogue pages.
# The SAC link follows NatureScot's naming pattern. If it fails, copy the
# GeoPackage link from
# https://www.data.gov.uk/dataset/special-areas-of-conservation-scotland

download_once <- function(id, url) {
  zip  <- file.path(raw_dir, paste0(id, ".zip"))
  dest <- file.path(raw_dir, id)
  if (!dir.exists(dest)) {
    if (!file.exists(zip)) {
      message("Downloading ", id, " ...")
      download.file(url, zip, mode = "wb", quiet = TRUE)
    }
    unzip(zip, exdir = dest)
  }
  dest
}

purrr::walk2(sources$id, sources$url, download_once)

# Scottish seas boundary (denominator) -----------------------------------------
# "Scottish Assessment areas: Scottish Marine Regions and Offshore Marine
# Regions" (Marine Directorate, OGL). 21 regions used for state of the sea
# assessments; offshore regions extend to the continental shelf limit.
area_dir <- file.path(raw_dir, "assessment_areas")
dir.create(area_dir, showWarnings = FALSE)

read_assessment_areas <- function() {
  local <- list.files(area_dir, pattern = "\\.(shp|gpkg|geojson)$",
                      recursive = TRUE, full.names = TRUE)
  if (length(local)) return(st_read(local[1], quiet = TRUE))

  # Public download link published on the data.gov.uk catalogue page (the
  # token is part of the published URL, no login needed). Zipped shapefile, WGS84.
  url <- paste0(
    "https://msmap1.atkinsgeospatial.com/geoserver/nmpwfs/ows?",
    "token=d46ffd2a-e192-4e51-8a6a-b3292c20f1ee&service=wfs&request=getFeature",
    "&typeName=nmpwfs:area_management_scottish_assessment_areas_marine_regions",
    "&outputFormat=shape-zip&srsName=EPSG:4326")
  zip <- file.path(area_dir, "assessment_areas.zip")
  out <- tryCatch({
    download.file(url, zip, mode = "wb", quiet = TRUE)
    unzip(zip, exdir = area_dir)
    shp <- list.files(area_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
    st_read(shp[1], quiet = TRUE)
  }, error = function(e) { message("Download failed: ", conditionMessage(e)); NULL })
  if (!is.null(out) && nrow(out) > 0) return(out)

  stop(
    "\nCould not download the Scottish assessment areas automatically.\n",
    "Please download them by hand (zipped shapefile, OGL):\n",
    "  https://www.data.gov.uk/dataset/area-management-scottish-assessment-areas-scottish-marine-regions-and-offshore-marine-regions\n",
    "Unzip into: ", area_dir, "\nthen re-run this script.", call. = FALSE)
}

areas <- read_assessment_areas() |>
  st_zm(drop = TRUE) |>
  st_transform(27700) |>
  st_make_valid()

message("Assessment areas: ", nrow(areas), " regions (expect 21). Columns: ",
        paste(names(areas), collapse = ", "))

# 2. Read and tidy site layers ------------------------------------------------
read_layer <- function(id) {
  f <- list.files(file.path(raw_dir, id), pattern = "\\.(gpkg|shp)$",
                  recursive = TRUE, full.names = TRUE)[1]
  x <- st_read(f, quiet = TRUE)
  message("\n", id, ": ", nrow(x), " features. Columns: ",
          paste(names(x), collapse = ", "))
  x
}

pick_col <- function(x, candidates) {
  hit <- intersect(candidates, names(x))
  if (length(hit)) hit[1] else NA_character_
}

tidy_sites <- function(x, type) {
  name_col <- pick_col(x, c("NAME", "SITE_NAME", "SiteName", "Site_Name", "name"))
  # NatureScot layers flag sites that form part of the MPA network
  # (MPA_NETWOR == "Y"). This drops terrestrial and freshwater SACs/SPAs.
  if ("MPA_NETWOR" %in% names(x)) x <- x[x$MPA_NETWOR == "Y", ]
  x <- x |> st_zm(drop = TRUE) |> st_transform(27700) |> st_make_valid()
  # Rebuild with a standard geometry column name ("geometry"), because
  # NatureScot layers use "geom" and JNCC uses "geometry"
  st_sf(
    site_name = if (!is.na(name_col)) as.character(x[[name_col]]) else NA_character_,
    type      = type,
    geometry  = st_geometry(x)
  )
}

sites <- purrr::map2(sources$id, sources$type,
                     \(id, type) tidy_sites(read_layer(id), type)) |>
  bind_rows()

# 3. Scottish seas ------------------------------------------------------------
scot_seas <- st_union(areas) |> st_make_valid()
sea_km2   <- as.numeric(st_area(scot_seas)) / 1e6
message("\nScottish seas area: ", format(round(sea_km2), big.mark = ","),
        " km2 (published: 618,744 km2)")

# Quick bounding-box crop first: drops English, Welsh, and NI offshore sites
sites <- suppressWarnings(st_crop(sites, st_bbox(scot_seas)))
message("Sites after filtering: ", n_distinct(sites$site_name, sites$type))

# 4. Dissolve first, then clip once (fast), so overlaps count once ------------
clip_to_seas <- function(g) {
  x <- st_union(g) |> st_make_valid() |> st_intersection(scot_seas)
  suppressWarnings(st_collection_extract(x, "POLYGON")) |> st_union()
}

message("Dissolving and clipping by designation type ...")
type_geoms <- sites |>
  group_by(type) |>
  summarise(n_sites = n_distinct(site_name), geometry = st_union(geometry),
            .groups = "drop")
clipped <- lapply(seq_len(nrow(type_geoms)), \(i) {
  g <- clip_to_seas(st_geometry(type_geoms)[i])     # [i] keeps the CRS
  message(sprintf("  %-32s %s km2", type_geoms$type[i],
                  format(round(sum(as.numeric(st_area(g))) / 1e6), big.mark = ",")))
  st_sf(type = type_geoms$type[i], n_sites = type_geoms$n_sites[i],
        geometry = st_union(g))
})
type_geoms <- do.call(rbind, clipped)

message("Combining all designations ...")
footprint      <- st_union(type_geoms) |> st_make_valid()
designated_km2 <- as.numeric(st_area(footprint)) / 1e6
pct            <- 100 * designated_km2 / sea_km2

# 5. Summaries ------------------------------------------------------------------
summary_tbl <- tibble(
  sea_km2        = sea_km2,
  designated_km2 = designated_km2,
  pct_designated = pct,
  published_pct  = 36.9,   # MPA network: 2024 report to the Scottish Parliament, Annex 1
  run_date       = Sys.Date()
)

by_type <- type_geoms |>
  mutate(km2 = as.numeric(st_area(geometry)) / 1e6,
         pct_of_seas = 100 * km2 / sea_km2) |>
  st_drop_geometry()

region_col <- pick_col(areas, c("region", "Region", "REGION", "name", "NAME", "Name",
                                "area_name", "AREA_NAME", "Region_nam", "region_nam"))
if (is.na(region_col)) stop("No region name column found. Columns are: ",
                            paste(names(areas), collapse = ", "))
message("Region name column used: ", region_col)

regions <- areas |>
  mutate(region = as.character(.data[[region_col]])) |>
  group_by(region) |>
  summarise(geometry = st_union(geometry), .groups = "drop")

by_region <- regions |>
  mutate(region_km2 = as.numeric(st_area(geometry)) / 1e6)

by_region$designated_km2 <- vapply(seq_len(nrow(by_region)), \(i) {
  g <- st_intersection(footprint, st_geometry(by_region)[i])
  if (length(g) == 0) 0 else sum(as.numeric(st_area(g))) / 1e6
}, numeric(1))

by_region <- by_region |>
  st_drop_geometry() |>
  mutate(pct_designated = 100 * designated_km2 / region_km2) |>
  arrange(desc(pct_designated))

# 6. Sanity check -------------------------------------------------------------
message(sprintf("\nDesignated: %s km2 of %s km2 = %.1f%% (published: 36.9%%)",
                format(round(designated_km2), big.mark = ","),
                format(round(sea_km2), big.mark = ","), pct))
if (abs(pct - 36.9) > 3) {
  warning("Result differs from the published 36.9% by more than 3 points. ",
          "Check the denominator boundary and which site types are included ",
          "before interpreting.", call. = FALSE)
}

# 7. Save -------------------------------------------------------------------------
readr::write_csv(summary_tbl, file.path(proc_dir, "mpas_summary.csv"))
readr::write_csv(by_type,     file.path(proc_dir, "mpas_by_type.csv"))
readr::write_csv(by_region,   file.path(proc_dir, "mpas_by_region.csv"))

map_file <- file.path(proc_dir, "mpas_map.gpkg")
if (file.exists(map_file)) invisible(file.remove(map_file))

type_geoms |>
  select(type) |>
  st_simplify(dTolerance = 250, preserveTopology = TRUE) |>
  st_transform(4326) |>
  st_write(map_file, layer = "designations", quiet = TRUE)

regions |>
  st_simplify(dTolerance = 500, preserveTopology = TRUE) |>
  st_transform(4326) |>
  st_write(map_file, layer = "regions", append = TRUE, quiet = TRUE)

message("\nDone. Outputs in data/processed/")
