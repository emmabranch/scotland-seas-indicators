# 04_seals.R ----------------------------------------
# Seals: harbour and grey seal counts by Seal Management Unit
# Step 5 of the build guide. Download links and licences are confirmed in
# that step before any code is added here, rather than guessed.
#
# Inputs:  data/raw/seals/   (not committed to Git)
# Outputs: data/processed/seals_*.csv or .gpkg (small, committed)

library(here)
library(dplyr)

raw_dir <- here("data", "raw", "seals")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Download ---------------------------------------------------------------

# 2. Clean and quality check -------------------------------------------------

# 3. Summarise ---------------------------------------------------------------

# 4. Save processed outputs --------------------------------------------------
