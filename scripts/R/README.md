# `scripts/R/` — MCDWD Flood Panel Pipeline

This directory contains the numbered R pipeline that processes NASA MCDWD_L3
satellite flood detection data into analysis-ready county × day and ZIP × day
panel datasets covering the contiguous United States from 2000 to present.

## Pipeline Overview

```
01_download.R   → data/raw/mcdwd/YYYY/*.hdf
                        ↓
02_process_rasters.R → data/raw/mcdwd/processed/YYYY/flood_YYYYMMDD.tif
                        ↓
03_aggregate_county.R → data/processed/county/county_flood_YYYY.rds
04_aggregate_zip.R    → data/processed/zip/zip_flood_YYYY.rds
                        ↓
05_build_panel.R → data/final/county_flood_panel.rds   (.csv)
                   data/final/zip_flood_panel.rds       (.csv)
                        ↓
06_descriptives.R → scripts/R/_outputs/{figures, tables}
07_validate.R     → quality_reports/diagnoses/validate_YYYY-MM-DD.md
```

## Scripts

| Script | Responsibility |
| --- | --- |
| `00_run_all.R` | Orchestrator — sources 01–07 in order, logs timing, writes sessionInfo |
| `01_download.R` | Download MCDWD_L3 HDF tiles from NASA EarthData (resume-safe) |
| `02_process_rasters.R` | Reproject sinusoidal → EPSG:5070, mosaic tiles, write COG GeoTIFFs |
| `03_aggregate_county.R` | Exact zonal stats → county × day flood fractions |
| `04_aggregate_zip.R` | Exact zonal stats → ZCTA × day flood fractions |
| `05_build_panel.R` | Stack annual files → analysis-ready panels with flood indicators |
| `06_descriptives.R` | Summary figures (map, time series) and tables |
| `07_validate.R` | Automated QA checks; exits with status 1 on any FAIL |

## Conventions

- **Run everything from `00_run_all.R`** (or specify `--stages=02,03` for a subset).
- **Paths via `here::here()`** — never `setwd()`. Root = git repo root.
- **CRS contract**: EPSG:5070 (NAD83 / Conus Albers) for all vector and processed raster data.
- **One date in memory at a time** — do not modify scripts to batch-load years.
- **`exactextractr` for zonal stats**, never `terra::extract()`.
- Fixed seed in `00_run_all.R`: `set.seed(20260615L)`. Change only with a reason in the session log.

## First-time setup

### 1. NASA EarthData credentials

Register at <https://urs.earthdata.nasa.gov/> (free). Then add to `~/.Renviron`:

```
EARTHDATA_USER=your_username
EARTHDATA_PASS=your_password
```

Run `usethis::edit_r_environ()` to open the file. Restart R after editing.

### 2. Install required R packages

```r
install.packages(c(
  "here",           # path resolution
  "terra",          # raster processing
  "sf",             # vector data / CRS
  "exactextractr",  # sub-pixel accurate zonal stats
  "tigris",         # Census boundary downloads
  "httr2",          # HTTP requests for downloads
  "lubridate",      # date arithmetic
  "dplyr", "tidyr", "purrr", "readr",  # tidyverse core
  "furrr", "future",  # parallel processing
  "ggplot2", "scales", # figures
  "glue"            # string interpolation
))
```

Optional but recommended:
```r
install.packages("renv")
renv::init()  # pin package versions for reproducibility
```

### 3. Disk space

Budget **~10–30 GB per year** for raw HDF tiles. Processed GeoTIFFs (COG,
DEFLATE) are ~80% smaller. Final panel RDS files are a few hundred MB total.
Raw and processed directories are gitignored — only `data/final/` is committed.

## Runtime estimates (8-core machine)

| Stage | Per year | Full 2000–present |
| --- | --- | --- |
| 01 download | 2–6 hrs (network) | — |
| 02 process | 5–15 min | 2–5 hrs |
| 03 county agg | 5–15 min | 2–5 hrs |
| 04 ZIP agg | 15–30 min | 5–10 hrs |
| 05 build panel | < 1 min | < 5 min |

## Expected outputs (after full pipeline run)

| File | Notes |
| --- | --- |
| `data/final/county_flood_panel.rds` | ~270M obs (3143 counties × ~25 yrs × ~365 days) |
| `data/final/county_flood_panel.csv` | Interoperable with Stata/Python |
| `data/final/zip_flood_panel.rds` | ~300M+ obs (33k ZCTAs) |
| `scripts/R/_outputs/fig_flood_days_per_year.pdf` | Time series |
| `scripts/R/_outputs/fig_county_total_flood_days.pdf` | Choropleth map |
| `scripts/R/_outputs/sessionInfo.txt` | Environment snapshot |
| `quality_reports/diagnoses/validate_YYYY-MM-DD.md` | QA report |

## Reviewing

`/review-r scripts/R/03_aggregate_county.R` — runs the R code-review agent.
`/audit-reproducibility` — verifies numeric claims against panel outputs.
`/diagnose` — root-cause analysis for a specific pipeline failure.
