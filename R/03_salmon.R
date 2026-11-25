# 03_salmon.R ----------------------------------------
# Wild salmon: annual river gradings and Salmon Stock Assessment Areas
# Step 4 of the build guide. Download links and licences are confirmed in
# that step before any code is added here, rather than guessed.
#
# Inputs:  data/raw/salmon/   (not committed to Git)
# Outputs: data/processed/salmon_*.csv or .gpkg (small, committed)

library(here)
library(dplyr)

raw_dir <- here("data", "raw", "salmon")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Download ---------------------------------------------------------------

# 2. Clean and quality check -------------------------------------------------

# 3. Summarise ---------------------------------------------------------------

# 4. Save processed outputs --------------------------------------------------
