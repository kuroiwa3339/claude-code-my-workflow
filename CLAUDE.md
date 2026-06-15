# CLAUDE.MD -- MCDWD Flood Panel Dataset

**Project:** MCDWD Flood Panel Dataset
**Institution:** [YOUR INSTITUTION]
**Branch:** main

---

## Core Principles

- **Plan first** -- enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** -- run the pipeline stage and confirm outputs before moving on
- **Single source of truth** -- raw HDF rasters in `data/raw/mcdwd/` are authoritative; all processed files derive from them
- **Quality gates** -- nothing ships below 80/100; R scripts must parse clean and produce expected outputs
- **[LEARN] tags** -- when corrected, save `[LEARN:category] wrong → right` to [MEMORY.md](MEMORY.md)

Cross-session context lives in [MEMORY.md](MEMORY.md); past plans, specs, and session logs are in [quality_reports/](quality_reports/).

---

## Folder Structure

```
flood-panel/
├── CLAUDE.md                    # This file
├── .claude/                     # Rules, skills, agents, hooks
├── data/
│   ├── raw/
│   │   ├── mcdwd/               # Downloaded HDF tiles (GITIGNORED — large)
│   │   └── boundaries/          # Census TIGER shapefiles (GITIGNORED — large)
│   ├── processed/
│   │   ├── county/              # County-day flood aggregates (.rds)
│   │   └── zip/                 # ZIP-day flood aggregates (.rds)
│   └── final/                   # Analysis-ready panel datasets (.rds, .csv)
├── scripts/
│   ├── R/                       # Numbered pipeline scripts (00–07)
│   └── R/_outputs/              # Figures, tables, sessionInfo (GITIGNORED)
├── quality_reports/             # Plans, session logs, diagnostics
├── explorations/                # Research sandbox
└── master_supporting_docs/      # Reference papers
```

---

## Pipeline Commands

```bash
# Run full pipeline (all stages)
Rscript scripts/R/00_run_all.R

# Run a single stage
Rscript scripts/R/02_process_rasters.R

# Validate panel outputs
Rscript scripts/R/07_validate.R

# Surface-count sync check
./scripts/check-surface-sync.sh
```

**Credentials:** NASA EarthData login must be in `~/.Renviron` as `EARTHDATA_USER` and `EARTHDATA_PASS`. Run `usethis::edit_r_environ()` to open the file.

---

## Quality Thresholds (advisory)

| Score | Checkpoint | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for deployment |
| 95 | Excellence | Aspirational |

Enforced by `/commit` (halts + asks for override) **and** — once you run `./scripts/install-hooks.sh` — by a real git pre-commit hook. Bypass with `SKIP_QUALITY_GATE=1` or `--no-verify`.

---

## Skills Quick Reference

Most-used skills for this project:

- **Data / reproducibility:** `/data-analysis` `/audit-reproducibility` `/diagnose` `/replication-package` `/capture-environment`
- **Papers / review:** `/review-paper` `/seven-pass-review` `/respond-to-referees` `/verify-claims` `/proofread`
- **Research / writing:** `/interview-me` `/lit-review` `/research-ideation` `/preregister`
- **Meta / workflow:** `/commit` `/learn` `/checkpoint` `/context-status` `/deep-audit`

Full skill index in [README.md](README.md#skills-claudeskills).

---

## Spatial Data Notes

| Item | Value |
| --- | --- |
| Flood product | NASA MCDWD_L3 (MODIS 250m daily flood detection) |
| SDS name | `"Flood_1Day"` (daily) or `"Flood_3Day"` (3-day composite) |
| Raw projection | MODIS sinusoidal (SINU) |
| Analysis CRS | EPSG:5070 — NAD83 / Conus Albers (reproject before all joins) |
| Admin boundaries | `tigris` package (counties, ZCTAs) |
| Zonal stats | `exactextractr::exact_extract()` — NOT `terra::extract()` |

---

## Pipeline Status

| Stage | Script | Status | Output |
| --- | --- | --- | --- |
| 1: Download | `01_download.R` | Scaffold | `data/raw/mcdwd/YYYY/` |
| 2: Process rasters | `02_process_rasters.R` | Scaffold | `data/raw/mcdwd/processed/YYYY/flood_YYYYMMDD.tif` |
| 3: County aggregation | `03_aggregate_county.R` | Scaffold | `data/processed/county/county_flood_YYYY.rds` |
| 4: ZIP aggregation | `04_aggregate_zip.R` | Scaffold | `data/processed/zip/zip_flood_YYYY.rds` |
| 5: Build panel | `05_build_panel.R` | Scaffold | `data/final/county_flood_panel.rds` |
| 6: Descriptives | `06_descriptives.R` | Scaffold | `scripts/R/_outputs/` |
| 7: Validate | `07_validate.R` | Scaffold | `quality_reports/diagnoses/` |
