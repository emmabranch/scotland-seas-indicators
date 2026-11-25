# 01_mpas.R ----------------------------------------
# MPA coverage: Scottish Nature Conservation MPAs plus offshore MPAs, % of Scottish seas
# Step 2 of the build guide. Download links and licences are confirmed in
# that step before any code is added here, rather than guessed.
#
# Inputs:  data/raw/mpas/   (not committed to Git)
# Outputs: data/processed/mpas_*.csv or .gpkg (small, committed)

library(here)
library(dplyr)

raw_dir <- here("data", "raw", "mpas")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Download ---------------------------------------------------------------

# 2. Clean and quality check -------------------------------------------------

# 3. Summarise ---------------------------------------------------------------

# 4. Save processed outputs --------------------------------------------------
