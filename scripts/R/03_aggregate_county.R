# =============================================================================
# 03_aggregate_county.R — Aggregate MCDWD flood rasters to US county level.
#
# For each date, computes flood statistics per county using exact zonal stats:
#   - flood_pixels:    count of pixels classified as flooded (code 3)
#   - valid_pixels:    count of pixels with valid (non-cloud, non-missing) data
#   - flood_fraction:  flood_pixels / valid_pixels  (NA if valid_pixels == 0)
#
# MCDWD_L3 flood codes (Flood_1Day SDS):
#   0 = no flood (valid)
#   1 = no data / outside swath
#   2 = cloud-obscured
#   3 = flood detected
#   4 = open water (permanent)
#
# Inputs:  data/raw/mcdwd/processed/YYYY/flood_YYYYMMDD.tif
#          (boundaries fetched via tigris package)
# Outputs: data/processed/county/county_flood_YYYY.rds
#
# Runtime: ~5–15 min/year depending on machine (parallelized over dates).
# Resume-safe: skips years where .rds already exists.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
  library(exactextractr)
  library(tigris)
  library(dplyr)
  library(lubridate)
  library(purrr)
  library(furrr)   # parallel map
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
TARGET_CRS  <- "EPSG:5070"
FLOOD_CODE  <- 3L    # pixel value meaning "flooded"
VALID_CODES <- c(0L, 3L, 4L)  # codes that represent real observations (not cloud/missing)

N_WORKERS   <- max(1L, parallel::detectCores() - 2L)

PROC_DIR   <- here("data", "raw", "mcdwd", "processed")
OUT_DIR    <- here("data", "processed", "county")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

YEARS      <- 2000:year(Sys.Date())

# ---- Load county boundaries (once) ----------------------------------------
message("Loading county boundaries via tigris ...")
counties_sf <- tigris::counties(cb = TRUE, resolution = "20m", year = 2020,
                                 progress_bar = FALSE) |>
  sf::st_transform(TARGET_CRS) |>
  dplyr::select(GEOID, STATEFP, COUNTYFP, NAME) |>
  dplyr::filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78"))  # CONUS only

message(sprintf("  %d counties loaded (CONUS only)", nrow(counties_sf)))

# Validate CRS (fail-fast: wrong CRS produces silently wrong fractions)
stopifnot("County CRS must match TARGET_CRS" =
  sf::st_crs(counties_sf) == sf::st_crs(TARGET_CRS))

# ---- Per-date aggregation function -----------------------------------------
aggregate_one_date <- function(tif_path) {
  tryCatch({
    date_str <- sub("flood_", "", tools::file_path_sans_ext(basename(tif_path)))
    date     <- as.Date(date_str, format = "%Y%m%d")

    r <- terra::rast(tif_path)

    # exact_extract returns a list of data.frames with columns: value, coverage_fraction
    # We want flood fraction weighted by pixel-polygon overlap.
    extracts <- exactextractr::exact_extract(
      x        = r,
      y        = counties_sf,
      fun      = NULL,   # return raw pixel lists (needed for custom flood codes)
      progress = FALSE
    )

    # Summarize per county
    out <- purrr::map_dfr(seq_along(extracts), function(i) {
      px <- extracts[[i]]
      dplyr::tibble(
        GEOID          = counties_sf$GEOID[[i]],
        date           = date,
        flood_pixels   = sum(px$value == FLOOD_CODE & !is.na(px$value), na.rm = TRUE),
        valid_pixels   = sum(px$value %in% VALID_CODES & !is.na(px$value), na.rm = TRUE),
        flood_fraction = if (valid_pixels > 0L) flood_pixels / valid_pixels else NA_real_
      )
    })

    rm(r, extracts)
    gc(verbose = FALSE)
    out
  }, error = function(e) {
    message(sprintf("  ERROR on %s: %s", basename(tif_path), conditionMessage(e)))
    NULL
  })
}

# ---- Main loop -------------------------------------------------------------
future::plan(future::multisession, workers = N_WORKERS)
on.exit(future::plan(future::sequential), add = TRUE)

message("")
message(sprintf("=== County aggregation (N_WORKERS = %d) ===", N_WORKERS))

for (yr in YEARS) {
  out_path <- file.path(OUT_DIR, glue("county_flood_{yr}.rds"))
  if (file.exists(out_path)) {
    message(sprintf("[%d] Output exists — skipping", yr))
    next
  }

  tif_files <- list.files(file.path(PROC_DIR, yr), pattern = "\\.tif$",
                           full.names = TRUE)
  if (length(tif_files) == 0L) {
    message(sprintf("[%d] No GeoTIFFs found — skipping (run 02 first)", yr))
    next
  }

  message(sprintf("[%d] Aggregating %d dates ...", yr, length(tif_files)))
  t_start <- Sys.time()

  results <- furrr::future_map(
    tif_files, aggregate_one_date,
    .options = furrr::furrr_options(seed = TRUE)
  )

  results_df <- dplyr::bind_rows(Filter(Negate(is.null), results)) |>
    dplyr::arrange(GEOID, date)

  saveRDS(results_df, out_path, compress = "xz")

  elapsed <- as.numeric(Sys.time() - t_start, units = "secs")
  message(sprintf("[%d] Done in %.0fs — %d county-date rows written",
                  yr, elapsed, nrow(results_df)))
}

message("")
message("County aggregation complete. Output: ", OUT_DIR)
