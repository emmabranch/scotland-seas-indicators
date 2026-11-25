# Build guide

Target: site live by **Mon 1 Dec 2026**, a day before the application closes.

| Step | What | Status |
|---|---|---|
| 1 | Setup, repo, empty site live on GitHub Pages | ← you are here |
| 2 | MPAs: download boundaries, % of Scottish seas designated | |
| 3 | Sea temperature: Stonehaven and Loch Ewe | |
| 4 | Salmon: river gradings 2021 to 2026, map | |
| 5 | Seals: SMU trends | |
| 6 | Seabirds deep dive | |
| 7 | Fill the framework map, README sources, polish, brand theme | |

---

## Step 1: setup and repo structure (about 45 minutes)

### 1.1 Check your tools (Terminal)

```bash
R --version          # 4.3+
quarto --version     # 1.4+ (for lightbox and gt interactive tables)
git --version
gh --version         # GitHub CLI; if missing: brew install gh
gh auth status       # should say logged in as emmabranch
```

If Quarto is older than 1.4, update from quarto.org.

### 1.2 The files are already on your Mac

Everything is in `~/projects/scotland-seas-indicators`. Check:

```bash
cd ~/projects/scotland-seas-indicators
ls -a     # _quarto.yml, index.qmd, R/, data/, indicators/, .gitignore
```

### 1.3 Turn it into a Git repo and create it on GitHub

```bash
git init -b main
git add .
git commit -m "Scaffold site, report card, and pipeline structure"
gh repo create emmabranch/scotland-seas-indicators --public \
  --description "Independent indicator report card for Scotland's seas (R, Quarto, sf)" \
  --source=. --remote=origin --push
```

### 1.4 Open it as an RStudio project

- RStudio: File > New Project > Existing Directory > choose the folder.
- This creates `scotland-seas-indicators.Rproj`, which keeps `here::here()` pointing at the root.

### 1.5 Install packages with renv

In the R console:

```r
source("R/00_setup.R")
```

This creates `renv.lock`. If `sf` complains about GDAL, run `brew install gdal` in Terminal and retry. If install time hurts, you can skip renv and just `install.packages()` the list in the script; renv is nice to have, not essential.

### 1.6 Preview the empty site

```bash
quarto preview
```

You should see the ocean hero, five grey "Not yet assessed" tiles (seabirds full width on top), and working navigation to each indicator page and the framework map.

Quick checks:

- Tiles are links and keyboard focusable (press Tab).
- Framework map table is searchable.
- No R errors in the Terminal output.

### 1.7 Commit the lockfile and publish

```bash
git add .
git commit -m "Add renv lockfile"
git push
quarto publish gh-pages
```

Then on GitHub: Settings > Pages > Source: Deploy from a branch > `gh-pages` / root. Wait a minute and visit https://emmabranch.github.io/scotland-seas-indicators.

### 1.8 How the report card works

- Every tile and every "at a glance" box reads from `data/lookup/indicator_status.csv`.
- When an analysis is done, change that row's `status` (good, mixed, poor, unknown), `trend` (improving, stable, declining, context, unknown), `confidence` (low, medium, high), `period`, and `headline`. The homepage updates on the next render.
- `featured = TRUE` makes the seabird tile span the full width.

### 1.9 Theme

`styles/seas.scss` is a placeholder sea palette. When you swap in your brand kit, keep the `.report-tile`, `.glance`, and `.seas-hero` rules, or move them into the brand kit file.

---

**Done with Step 1?** Tell me "Step 1 done" plus anything that broke, and we'll start Step 2 (MPAs).
