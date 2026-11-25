# 02_sea_temperature.R ----------------------------------------
# Sea temperature: Scottish Coastal Observatory, Stonehaven and Loch Ewe (reject QF 3, 4, 9)
# Step 3 of the build guide. Download links and licences are confirmed in
# that step before any code is added here, rather than guessed.
#
# Inputs:  data/raw/sea_temperature/   (not committed to Git)
# Outputs: data/processed/sea_temperature_*.csv or .gpkg (small, committed)

library(here)
library(dplyr)

raw_dir <- here("data", "raw", "sea_temperature")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Download ---------------------------------------------------------------

# 2. Clean and quality check -------------------------------------------------

# 3. Summarise ---------------------------------------------------------------

# 4. Save processed outputs --------------------------------------------------
