# =============================================================================
# 05_build_panel.R — Assemble county × day and ZIP × day panel datasets.
#
# Stacks annual RDS files from stages 03 and 04 into two panel datasets
# ready for causal analysis. Adds date metadata, FIPS codes, and basic
# derived variables. Saves as .rds (fast) and .csv (interoperable).
#
# Inputs:  data/processed/county/county_flood_YYYY.rds  (all available years)
#          data/processed/zip/zip_flood_YYYY.rds         (all available years)
# Outputs: data/final/county_flood_panel.rds
#          data/final/county_flood_panel.csv
#          data/final/zip_flood_panel.rds
#          data/final/zip_flood_panel.csv
#
# Panel structure:
#   county: GEOID (5-digit FIPS) × date
#   zip:    ZCTA5CE20 × date
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(purrr)
  library(readr)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
COUNTY_IN  <- here("data", "processed", "county")
ZIP_IN     <- here("data", "processed", "zip")
FINAL_DIR  <- here("data", "final")
dir.create(FINAL_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Helper: stack all yearly RDS files ------------------------------------
stack_yearly <- function(in_dir, pattern) {
  files <- list.files(in_dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0L) {
    stop("No files matching '", pattern, "' in ", in_dir,
         "\nRun stages 03/04 first.")
  }
  message(sprintf("  Stacking %d annual files from %s ...", length(files), in_dir))
  purrr::map_dfr(files, readRDS)
}

# ---- Helper: add date metadata columns -------------------------------------
add_date_metadata <- function(df) {
  df |>
    dplyr::mutate(
      year    = lubridate::year(date),
      month   = lubridate::month(date),
      quarter = lubridate::quarter(date),
      week    = lubridate::isoweek(date),
      doy     = lubridate::yday(date)
    )
}

# ---- Helper: add flood intensity variables ---------------------------------
add_flood_vars <- function(df) {
  df |>
    dplyr::mutate(
      # Binary flood indicator: at least 1% of valid pixels flooded
      any_flood     = as.integer(!is.na(flood_fraction) & flood_fraction >= 0.01),
      # Moderate flood: >= 10% of area flooded
      moderate_flood = as.integer(!is.na(flood_fraction) & flood_fraction >= 0.10),
      # Severe flood: >= 25% of area flooded
      severe_flood   = as.integer(!is.na(flood_fraction) & flood_fraction >= 0.25),
      # Flag incomplete coverage (high fraction of cloud/missing)
      low_coverage   = as.integer(is.na(flood_fraction) | valid_pixels < 10L)
    )
}

# ---- County panel ----------------------------------------------------------
message("=== Building county flood panel ===")
county_panel <- stack_yearly(COUNTY_IN, "^county_flood_[0-9]{4}\\.rds$") |>
  dplyr::rename(fips5 = GEOID) |>
  dplyr::mutate(
    state_fips  = substr(fips5, 1L, 2L),
    county_fips = substr(fips5, 3L, 5L)
  ) |>
  add_date_metadata() |>
  add_flood_vars() |>
  dplyr::arrange(fips5, date)

# Basic panel coverage report
n_counties  <- dplyr::n_distinct(county_panel$fips5)
n_dates     <- dplyr::n_distinct(county_panel$date)
date_range  <- range(county_panel$date)
message(sprintf("  Counties: %d | Dates: %d (%s to %s) | Rows: %s",
                n_counties, n_dates, date_range[1L], date_range[2L],
                format(nrow(county_panel), big.mark = ",")))

county_out_rds <- file.path(FINAL_DIR, "county_flood_panel.rds")
county_out_csv <- file.path(FINAL_DIR, "county_flood_panel.csv")
saveRDS(county_panel, county_out_rds, compress = "xz")
readr::write_csv(county_panel, county_out_csv)
message(sprintf("  Saved: %s", basename(county_out_rds)))
message(sprintf("  Saved: %s (%.1f MB)", basename(county_out_csv),
                file.size(county_out_csv) / 1e6))

# ---- ZIP panel -------------------------------------------------------------
message("")
message("=== Building ZIP flood panel ===")
zip_panel <- stack_yearly(ZIP_IN, "^zip_flood_[0-9]{4}\\.rds$") |>
  add_date_metadata() |>
  add_flood_vars() |>
  dplyr::arrange(ZCTA5CE20, date)

n_zips     <- dplyr::n_distinct(zip_panel$ZCTA5CE20)
n_dates_z  <- dplyr::n_distinct(zip_panel$date)
date_rng_z <- range(zip_panel$date)
message(sprintf("  ZCTAs: %d | Dates: %d (%s to %s) | Rows: %s",
                n_zips, n_dates_z, date_rng_z[1L], date_rng_z[2L],
                format(nrow(zip_panel), big.mark = ",")))

zip_out_rds <- file.path(FINAL_DIR, "zip_flood_panel.rds")
zip_out_csv <- file.path(FINAL_DIR, "zip_flood_panel.csv")
saveRDS(zip_panel, zip_out_rds, compress = "xz")
readr::write_csv(zip_panel, zip_out_csv)
message(sprintf("  Saved: %s", basename(zip_out_rds)))
message(sprintf("  Saved: %s (%.1f MB)", basename(zip_out_csv),
                file.size(zip_out_csv) / 1e6))

message("")
message("Panel build complete. Output: ", FINAL_DIR)
