# run_all.R ------------------------------------------------------------------
# Rebuild every processed dataset from raw, in order.
scripts <- sort(list.files(here::here("R"), pattern = "^0[1-9]_.*\\.R$", full.names = TRUE))
for (s in scripts) { message("Running ", basename(s)); source(s, local = new.env()) }
