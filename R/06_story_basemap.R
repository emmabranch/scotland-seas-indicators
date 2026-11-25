# 06_story_basemap.R ----------------------------------------------------------
# Land polygons for the seabird outbreak story maps.
# Source: Natural Earth (public domain), 1:50m countries, via rnaturalearth.
# Output: data/processed/story_land.gpkg (UK, Ireland, Norway, Faroes; clipped)

for (pkg in c("rnaturalearth", "rnaturalearthdata")) {
  if (!requireNamespace(pkg, quietly = TRUE)) renv::install(pkg, prompt = FALSE)
}
library(sf)
sf_use_s2(FALSE)

land <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf",
                                    country = c("United Kingdom", "Ireland", "Norway", "Faroe Islands")) |>
  sf::st_make_valid() |>
  sf::st_crop(xmin = -14, xmax = 6, ymin = 53, ymax = 62.5) |>
  dplyr::select(name)

out <- here::here("data", "processed", "story_land.gpkg")
if (file.exists(out)) invisible(file.remove(out))
sf::st_write(land, out, quiet = TRUE)
message("Saved ", out)
