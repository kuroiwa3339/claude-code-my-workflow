# =============================================================================
# 07_validate.R — Automated data quality validation for flood panel datasets.
#
# Runs a battery of checks on the assembled panels and writes a structured
# report to quality_reports/diagnoses/. All checks produce PASS / WARN / FAIL
# results; any FAIL halts and prints a summary before exiting with status 1.
#
# Checks:
#   V01  Panel completeness — all dates 2000-02-24 to present present
#   V02  Spatial completeness — all 3143 CONUS counties present each year
#   V03  Flood fraction bounds — all values in [0, 1] (or NA)
#   V04  No duplicate county-date rows
#   V05  FIPS code format — all 5-digit numeric strings
#   V06  Known-event spot checks — Katrina (2005-08-29), Sandy (2012-10-29)
#   V07  Low-coverage frequency — flag if >20% of obs have low_coverage = 1
#   V08  ZIP panel: ZCTA count within expected range (~33k)
#
# Inputs:  data/final/county_flood_panel.rds
#          data/final/zip_flood_panel.rds
# Outputs: quality_reports/diagnoses/validate_YYYY-MM-DD.md
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(lubridate)
  library(glue)
  library(readr)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

DIAG_DIR <- here("quality_reports", "diagnoses")
dir.create(DIAG_DIR, showWarnings = FALSE, recursive = TRUE)
out_path <- file.path(DIAG_DIR, glue("validate_{Sys.Date()}.md"))

# ---- Load panels -----------------------------------------------------------
message("Loading panels for validation ...")
county_path <- here("data", "final", "county_flood_panel.rds")
zip_path    <- here("data", "final", "zip_flood_panel.rds")

if (!file.exists(county_path)) stop("county_flood_panel.rds not found.")
if (!file.exists(zip_path))    stop("zip_flood_panel.rds not found.")

county <- readRDS(county_path)
zip    <- readRDS(zip_path)
message(sprintf("  County panel: %s rows", format(nrow(county), big.mark = ",")))
message(sprintf("  ZIP panel:    %s rows", format(nrow(zip), big.mark = ",")))

# ---- Validation framework --------------------------------------------------
results <- list()

check <- function(id, description, test_expr, warn_expr = NULL) {
  passed <- isTRUE(test_expr)
  warned <- if (!is.null(warn_expr)) isTRUE(warn_expr) else FALSE
  status <- if (passed) "PASS" else if (warned) "WARN" else "FAIL"
  results[[id]] <<- list(id = id, desc = description, status = status)
  message(sprintf("  [%s] %s: %s", status, id, description))
  invisible(status)
}

message("")
message("=== Running validation checks ===")

# V01: Date completeness (county panel)
expected_start <- as.Date("2000-02-24")
expected_dates  <- seq(expected_start, max(county$date), by = "day")
observed_dates  <- unique(county$date)
missing_dates   <- setdiff(as.character(expected_dates), as.character(observed_dates))
check("V01",
      glue("Date completeness: {length(observed_dates)} / {length(expected_dates)} dates present"),
      length(missing_dates) == 0L,
      length(missing_dates) <= 10L)  # WARN if ≤ 10 days missing

# V02: Spatial completeness (are all counties present in the most recent full year?)
latest_full_yr <- max(county$year[county$year < year(Sys.Date())])
n_counties_yr  <- county |> filter(year == latest_full_yr) |> pull(fips5) |> n_distinct()
check("V02",
      glue("Spatial completeness in {latest_full_yr}: {n_counties_yr} distinct counties"),
      n_counties_yr >= 3100L,   # CONUS has 3143 counties; allow small variation
      n_counties_yr >= 3000L)

# V03: Flood fraction bounds
out_of_bounds <- county |>
  filter(!is.na(flood_fraction)) |>
  filter(flood_fraction < 0 | flood_fraction > 1) |>
  nrow()
check("V03",
      glue("Flood fraction in [0,1]: {out_of_bounds} out-of-bounds values"),
      out_of_bounds == 0L)

# V04: No duplicate county × date rows
n_dups <- county |>
  count(fips5, date) |>
  filter(n > 1L) |>
  nrow()
check("V04",
      glue("No duplicate county-date rows: {n_dups} duplicates found"),
      n_dups == 0L)

# V05: FIPS code format
bad_fips <- sum(!grepl("^[0-9]{5}$", county$fips5), na.rm = TRUE)
check("V05",
      glue("FIPS format (5-digit): {bad_fips} malformed values"),
      bad_fips == 0L)

# V06: Known-event spot checks (Hurricane Katrina 2005-08-29, Sandy 2012-10-29)
katrina_date <- as.Date("2005-08-29")
sandy_date   <- as.Date("2012-10-29")

katrina_flooded <- county |>
  filter(date == katrina_date, any_flood == 1L) |>
  nrow()
sandy_flooded <- county |>
  filter(date == sandy_date, any_flood == 1L) |>
  nrow()

katrina_ok <- katrina_flooded >= 10L   # expect ≥ 10 counties flooded during Katrina
sandy_ok   <- sandy_flooded   >= 5L

check("V06a",
      glue("Katrina spot check ({katrina_date}): {katrina_flooded} flooded counties"),
      katrina_ok,
      katrina_flooded >= 1L)
check("V06b",
      glue("Sandy spot check ({sandy_date}): {sandy_flooded} flooded counties"),
      sandy_ok,
      sandy_flooded >= 1L)

# V07: Low coverage frequency
pct_low_cov <- 100 * mean(county$low_coverage == 1L, na.rm = TRUE)
check("V07",
      glue("Low-coverage rate: {round(pct_low_cov, 1)}% of county-days"),
      pct_low_cov <= 20,   # FAIL if >20% obs have low coverage
      pct_low_cov <= 35)   # WARN if 20–35%

# V08: ZIP panel ZCTA count
n_zctas <- n_distinct(zip$ZCTA5CE20)
check("V08",
      glue("ZCTA count in ZIP panel: {format(n_zctas, big.mark=',')}"),
      n_zctas >= 30000L,
      n_zctas >= 25000L)

# ---- Write report ----------------------------------------------------------
statuses <- sapply(results, `[[`, "status")
n_pass   <- sum(statuses == "PASS")
n_warn   <- sum(statuses == "WARN")
n_fail   <- sum(statuses == "FAIL")

overall <- if (n_fail > 0L) "FAIL" else if (n_warn > 0L) "WARN" else "PASS"

report_lines <- c(
  glue("# Flood Panel Validation Report"),
  glue("**Date:** {Sys.Date()}"),
  glue("**Overall:** {overall} ({n_pass} PASS / {n_warn} WARN / {n_fail} FAIL)"),
  "",
  "## Check Results",
  "",
  "| ID | Status | Description |",
  "|---|---|---|",
  sapply(results, function(r) glue("| {r$id} | **{r$status}** | {r$desc} |")),
  "",
  "## Data Summary",
  glue("- County panel: {format(nrow(county), big.mark=',')} rows"),
  glue("- ZIP panel:    {format(nrow(zip), big.mark=',')} rows"),
  glue("- Date range:   {min(county$date)} to {max(county$date)}"),
  glue("- Counties:     {n_distinct(county$fips5)}"),
  glue("- ZCTAs:        {n_distinct(zip$ZCTA5CE20)}"),
  "",
  glue("_Generated by 07_validate.R on {Sys.time()}_")
)

writeLines(report_lines, out_path)
message("")
message(glue("Validation {overall}: {n_pass} PASS / {n_warn} WARN / {n_fail} FAIL"))
message("Report: ", out_path)

if (n_fail > 0L) {
  failed_ids <- names(statuses[statuses == "FAIL"])
  message("FAILED checks: ", paste(failed_ids, collapse = ", "))
  quit(status = 1L)
}
