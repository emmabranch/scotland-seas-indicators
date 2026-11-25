# State of Scotland's Seas: an independent indicator report card

**Live site:** https://emmabranch.github.io/scotland-seas-indicators

A reproducible Quarto website that summarises five indicators of the state of Scotland's seas, built from open and published data. Each indicator page reports what it measures, why it matters, status, trend, confidence, limitations, and sources. A framework map links every indicator to the Scottish Biodiversity Strategy, the Natural Environment (Scotland) Act 2026, the Habitats Regulations, OSPAR, the UK Marine Strategy, and the Kunming-Montreal Global Biodiversity Framework.

> **Independent personal project.** This work is not affiliated with, commissioned by, or endorsed by NatureScot, the Scottish Government Marine Directorate, JNCC, RSPB, BTO, SMRU, or any other organisation whose data it uses. No organisational logos or branding are used. Status calls are my own reading of published data, not official assessments.

## Indicators

| Indicator | Headline | Status |
|---|---|---|
| **Seabirds after avian flu** (featured deep dive) | Great Skua territories at nine Scottish SPAs fell 77% after the 2021-22 HPAI outbreak; Gannet nests at six SPAs fell 22% (28% against a trend-adjusted baseline) | Clear concern |
| Harbour and grey seals | 19,978 harbour seals counted in 2021-25: the lowest since the first census, 26% below 2016-19 | Clear concern |
| Wild Atlantic salmon | 115 of 173 assessed stocks in poor conservation status for 2026, up from 102 in 2021 | Clear concern |
| Sea temperature | No clear trend at Stonehaven or Loch Ewe over 1997-2020, against a background of longer-term warming | Context |
| MPA coverage and 30x30 | 36.9% of Scottish seas designated, above the 30% area threshold; effectiveness of management is the open question | Generally positive |

## Methods summary

- **MPAs:** NC MPA, SAC, and SPA boundaries (MPA network sites only) plus JNCC offshore MPAs, dissolved so overlaps count once, clipped to the 21 Scottish marine assessment regions. Validated against the published 36.9%.
- **Sea temperature:** weekly near-surface samples (shallowest sample per visit, 5 m or less), quality flags QF 3, 4, and 9 rejected, monthly anomalies against a 1999-2020 climatology, linear trend in annual anomalies with 95% CI.
- **Salmon:** river-level gradings scraped from the published tables, grouped into the 173 stocks, mapped by OS grid reference outflow point. Validated exactly against official counts for 2021-2026.
- **Seals:** census counts by Seal Management Unit from NatureScot Research Report 1421 (Tables 2, 3, and 6), checked against the report's totals.
- **Seabirds:** SPA-level counts transcribed from RSPB Research Report 76, percentage change with Poisson 95% CIs (counting noise only), and a secular-trend sensitivity analysis for Gannet.

Full details are on the [Methods page](https://emmabranch.github.io/scotland-seas-indicators/methods.html).

## Repository structure

```
scotland-seas-indicators/
├── _quarto.yml              Site configuration
├── index.qmd                Homepage report card
├── framework.qmd            Framework mapping table
├── methods.qmd, about.qmd
├── indicators/              One page per indicator
├── R/
│   ├── 00_setup.R           Install packages with renv (run once)
│   ├── 01_mpas.R ... 05_seabirds.R   Download, check, summarise
│   ├── run_all.R            Rebuild all processed data
│   ├── theme_seas.R         Shared chart theme and status vocabulary
│   └── report_card.R        Report card tiles, page summaries, map keys
├── data/
│   ├── raw/                 Downloaded data (not in Git)
│   ├── processed/           Small tidy outputs used by pages
│   └── lookup/              Indicator status, framework map, transcribed tables
└── styles/seas.scss         Site styling
```

## Reproduce

```bash
git clone https://github.com/emmabranch/scotland-seas-indicators.git
cd scotland-seas-indicators
Rscript R/00_setup.R      # or renv::restore()
Rscript R/run_all.R       # downloads raw data and builds processed files
quarto preview
```

Requires R (4.3 or later), Quarto (1.4 or later), and GDAL via `sf`.

**Manual steps.** Two sources block scripted downloads:

- **Salmon 2021-2025 gradings:** the consultation pages are in the National Records of Scotland web archive. Save each table page from your browser (using `view-source:` on the archive's `mp_` address) into `data/raw/salmon/html/` as `proposed_<page>.html`. See the comments in `R/03_salmon.R`.
- **Seal report:** save NatureScot Research Report 1421 from your browser as `data/raw/seals/naturescot_rr1421.html`.

## Accessibility

- Colours from the Okabe-Ito palette, distinguishable with common forms of colour vision deficiency.
- Status is never shown by colour alone: every status has an icon and a text label.
- Map keys sit outside the maps so they never hide data.
- Charts have descriptive titles and alt text.

## Data sources, licences, and attribution

Contains public sector information licensed under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

| Dataset | Publisher | Licence and attribution |
|---|---|---|
| Nature Conservation MPAs; Special Areas of Conservation; Special Protection Areas | NatureScot (via spatialdata.gov.scot) | OGL v3.0 |
| UK Offshore Marine Protected Areas (version 20251203) | JNCC | OGL v3.0. Contains Joint Nature Conservation Committee data © copyright and database right. Contains NatureScot data © copyright and database right. |
| Scottish Assessment areas (Scottish Marine Regions and Offshore Marine Regions); Seal Management Areas | Scottish Government Marine Directorate (seal areas provided by SMRU) | Contains information from the Scottish Government (Marine Scotland) licensed under the Open Government Licence v3.0. © Sea Mammal Research Unit (seal areas). |
| Scottish Coastal Observatory: Stonehaven (doi:10.7489/610-1) and Loch Ewe (doi:10.7489/948-1) environmental data | Marine Scotland Science | OGL v3.0. Near-surface temperature, 1997-2020, excluding QF 3, 4, and 9. |
| Salmon fishing river gradings (proposed 2026, with 2021-2025; final 2026) | Scottish Government | OGL v3.0 |
| Aerial surveys of seals in Scotland during the harbour seal moult, 2021-2025 (NatureScot Research Report 1421; Morris et al. 2026) | NatureScot / SMRU | Figures reproduced from Tables 2, 3, and 6 with full citation. |
| UK seabird colony counts in 2023 following the 2021-22 outbreak of HPAI (RSPB Research Report 76; Tremlett, Morley & Wilson 2024) | RSPB | Not openly licensed. A limited set of published figures transcribed with full citation for non-commercial analysis. |
| Marine Protected Area network: 2024 report to the Scottish Parliament | Scottish Government | OGL v3.0 (comparison figure) |
| Basemap tiles | Esri (Ocean Basemap); OpenStreetMap contributors | Per provider terms, credited on each map |

## Limitations

- These are independent summaries for a portfolio project, not official assessments.
- Each indicator page has its own limitations section. The main project-wide ones: several indicators depend on published summary tables rather than raw data; the sea temperature record ends in 2020; and status calls are judgements made against rules set out on the Methods page.

## Licence

Code: MIT. Text and figures: CC BY 4.0. Third-party data remain under their own licences listed above.
