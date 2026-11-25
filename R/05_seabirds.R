# 05_seabirds.R ----------------------------------------
# Seabirds: Seabirds Count census vs 2023 post-HPAI counts, Scottish colonies
# Step 6 of the build guide. Download links and licences are confirmed in
# that step before any code is added here, rather than guessed.
#
# Inputs:  data/raw/seabirds/   (not committed to Git)
# Outputs: data/processed/seabirds_*.csv or .gpkg (small, committed)

library(here)
library(dplyr)

raw_dir <- here("data", "raw", "seabirds")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Download ---------------------------------------------------------------

# 2. Clean and quality check -------------------------------------------------

# 3. Summarise ---------------------------------------------------------------

# 4. Save processed outputs --------------------------------------------------
