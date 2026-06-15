# =============================================================================
# 02_process_rasters.R — Process MCDWD_L3 HDF tiles → cloud-optimized GeoTIFFs
#
# For each date:
#   1. Read the "Flood_1Day" SDS from each MODIS tile (HDF4)
#   2. Reproject from MODIS sinusoidal → EPSG:5070 (Albers Equal Area CONUS)
#   3. Mosaic all CONUS tiles into a single raster
#   4. Clip to CONUS bounding box
#   5. Write cloud-optimized GeoTIFF
#
# Inputs:  data/raw/mcdwd/YYYY/MCDWD_L3F.A<YYYY><DDD>.<tile>.*.hdf
# Outputs: data/raw/mcdwd/processed/YYYY/flood_<YYYYMMDD>.tif
#
# Memory:  Processes ONE date at a time. A full CONUS mosaic at 250m is ~1–2 GB
#          in memory. Do NOT load multiple dates simultaneously.
# Runtime: ~2–10 min/year depending on machine and GDAL version.
# Resume-safe: skips dates where .tif already exists.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
  library(lubridate)
  library(dplyr)
  library(purrr)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
SDS_NAME   <- "Flood_1Day"   # or "Flood_3Day" for the 3-day composite
TARGET_CRS <- "EPSG:5070"    # NAD83 / Conus Albers — consistent across all scripts

# CONUS bounding box in EPSG:5070 (approximate, in metres)
CONUS_BBOX <- ext(-2356113, 2258155, 269823, 3172570)

RAW_DIR   <- here("data", "raw", "mcdwd")
PROC_DIR  <- here("data", "raw", "mcdwd", "processed")
dir.create(PROC_DIR, showWarnings = FALSE, recursive = TRUE)

# Years to process — adjust as needed
YEARS <- 2000:year(Sys.Date())

# ---- CONUS MCDWD tile list (must match 01_download.R) ----------------------
TILES_CONUS <- c(
  "h08v04", "h08v05",
  "h09v04", "h09v05",
  "h10v04", "h10v05",
  "h11v04", "h11v05",
  "h12v04", "h12v05",
  "h13v04"
)

# ---- Helpers ----------------------------------------------------------------
# Convert a YYYY + DOY to a calendar date
doy_to_date <- function(yr, doy) as.Date(doy - 1L, origin = paste0(yr, "-01-01"))

# Find HDF files for a given date across all tiles
find_hdfs <- function(yr, date) {
  doy    <- yday(date)
  pattern <- glue("MCDWD_L3F.A{yr}{sprintf('%03d', doy)}.*.hdf")
  files  <- Sys.glob(file.path(RAW_DIR, yr, pattern))
  # Filter to CONUS tiles only
  files[sapply(files, function(f) any(sapply(TILES_CONUS, grepl, f)))]
}

# Process a single date: read, reproject, mosaic, clip, write COG
process_date <- function(date) {
  yr       <- year(date)
  date_str <- format(date, "%Y%m%d")
  out_dir  <- file.path(PROC_DIR, yr)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_path <- file.path(out_dir, glue("flood_{date_str}.tif"))

  if (file.exists(out_path)) return(invisible("SKIP"))

  hdfs <- find_hdfs(yr, date)
  if (length(hdfs) == 0L) {
    message(sprintf("  [%s] No HDF files found — skipping", date_str))
    return(invisible("MISSING"))
  }

  # Read each tile's flood SDS and reproject
  tiles_proj <- lapply(hdfs, function(hdf) {
    tryCatch({
      r <- terra::rast(hdf, subds = SDS_NAME)
      # MODIS sinusoidal → target CRS
      terra::project(r, TARGET_CRS, method = "near")  # nearest for categorical flood codes
    }, error = function(e) {
      message(sprintf("  WARNING: failed to read %s — %s", basename(hdf), conditionMessage(e)))
      NULL
    })
  })
  tiles_proj <- Filter(Negate(is.null), tiles_proj)

  if (length(tiles_proj) == 0L) {
    message(sprintf("  [%s] All tiles failed — skipping", date_str))
    return(invisible("ERROR"))
  }

  # Mosaic tiles (use "max" so any flooded pixel wins over no-data)
  mosaic_r <- if (length(tiles_proj) == 1L) {
    tiles_proj[[1L]]
  } else {
    do.call(terra::mosaic, c(tiles_proj, list(fun = "max")))
  }

  # Clip to CONUS extent
  mosaic_r <- terra::crop(mosaic_r, CONUS_BBOX)

  # Write cloud-optimized GeoTIFF (COG)
  terra::writeRaster(
    mosaic_r, out_path,
    filetype   = "COG",
    datatype   = "INT1U",   # uint8 — flood codes are 0–255
    overwrite  = TRUE,
    gdal       = c("COMPRESS=DEFLATE", "PREDICTOR=2", "OVERVIEW_RESAMPLING=NEAREST")
  )

  # Free memory explicitly (critical for year-level loops)
  rm(tiles_proj, mosaic_r)
  gc(verbose = FALSE)

  invisible("OK")
}

# ---- Main loop -------------------------------------------------------------
message("=== Processing MCDWD_L3 rasters ===")
message(sprintf("SDS: %s | CRS: %s", SDS_NAME, TARGET_CRS))
message(sprintf("Years: %d – %d", min(YEARS), max(YEARS)))
message("")

for (yr in YEARS) {
  # Find all dates with at least one HDF in this year
  all_hdfs <- list.files(file.path(RAW_DIR, yr), pattern = "\\.hdf$", full.names = FALSE)
  if (length(all_hdfs) == 0L) {
    message(sprintf("[%d] No HDF files found — skipping", yr))
    next
  }

  # Extract unique DOYs from filenames
  doys   <- unique(as.integer(sub(".*\\.A[0-9]{4}([0-9]{3})\\..*", "\\1", all_hdfs)))
  dates  <- as.Date(doys - 1L, origin = paste0(yr, "-01-01"))
  n      <- length(dates)

  message(sprintf("[%d] %d dates to process ...", yr, n))
  t_start <- Sys.time()

  for (i in seq_along(dates)) {
    status <- process_date(dates[[i]])
    if (i %% 30L == 0L || i == n) {
      pct <- round(100 * i / n)
      message(sprintf("  [%d] %d%% (%d/%d)", yr, pct, i, n))
    }
  }

  elapsed <- as.numeric(Sys.time() - t_start, units = "secs")
  n_tifs  <- length(list.files(file.path(PROC_DIR, yr), pattern = "\\.tif$"))
  message(sprintf("[%d] Done in %.0fs — %d GeoTIFFs written", yr, elapsed, n_tifs))
}

message("")
message("Processing complete. Output: ", PROC_DIR)
