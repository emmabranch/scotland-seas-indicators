# State of Scotland's Seas: an independent indicator report card

**Live site:** https://emmabranch.github.io/scotland-seas-indicators

A reproducible Quarto website that summarises five marine indicators for Scotland, in the spirit of an assessment report card, using only open data. Each indicator page reports what it measures, why it matters, status, trend, confidence, limitations, and sources. A framework map links every indicator to the Scottish Biodiversity Strategy, Habitats Regulations, OSPAR, the UK Marine Strategy, and the Kunming-Montreal Global Biodiversity Framework.

> **Independent personal project.** This work is not affiliated with, commissioned by, or endorsed by NatureScot, the Scottish Government Marine Directorate, JNCC, RSPB, BTO, SMRU, or any other organisation whose data it uses. No organisational logos or branding are used. Status calls are my own independent reading of published data, not official assessments.

## Indicators

| Indicator | Question | Main data | Status |
|---|---|---|---|
| Seabirds after avian flu (featured) | How did Scottish colony counts change after the 2021-22 HPAI outbreak? | Seabirds Count census; RSPB Research Report 76 | In progress |
| Harbour and grey seals | How are counts changing by Seal Management Unit? | SCOS / SMRU August counts | In progress |
| Wild Atlantic salmon | How has the conservation grading of salmon stocks changed? | Marine Directorate river gradings | In progress |
| Sea temperature | How much have Scottish coastal waters warmed? | Scottish Coastal Observatory | In progress |
| MPA coverage and 30x30 | What share of Scottish seas is designated? | NatureScot and JNCC MPA boundaries | In progress |

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
│   ├── 01_mpas.R ... 05_seabirds.R   Download, clean, summarise
│   ├── run_all.R            Rebuild all processed data
│   ├── theme_seas.R         Shared chart theme and status vocabulary
│   └── report_card.R        Builds tiles from indicator_status.csv
├── data/
│   ├── raw/                 Downloaded data (not in Git)
│   ├── processed/           Small tidy outputs used by pages
│   └── lookup/              indicator_status.csv, framework_mapping.csv
└── styles/seas.scss         Site styling
```

## Reproduce

```bash
git clone https://github.com/emmabranch/scotland-seas-indicators.git
cd scotland-seas-indicators
Rscript R/00_setup.R      # or renv::restore() once renv.lock exists
Rscript R/run_all.R       # downloads raw data and builds processed files
quarto preview
```

Requires R (4.3 or later), Quarto (1.4 or later), and GDAL via the `sf` package.

## Methods summary

<!-- Short summary per indicator, completed as each analysis is finished. -->

## Accessibility

- Colours from the Okabe-Ito palette, which is distinguishable with common forms of colour vision deficiency.
- Status is never shown by colour alone: every status has an icon and a text label.
- Charts have descriptive titles and alt text.

## Data sources, licences, and attribution

<!-- Completed and checked per dataset. Template wording for OGL sources: -->

Contains public sector information licensed under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

| Dataset | Publisher | Licence | Attribution |
|---|---|---|---|
| To be added | | | |

## Limitations

<!-- Project-wide limitations, plus a link to each indicator page. -->

## Licence

Code: MIT. Text and figures: CC BY 4.0. Third-party data remain under their own licences listed above.
