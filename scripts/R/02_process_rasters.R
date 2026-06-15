# =============================================================================
# 02_process_rasters.R — Convert MCDWD_L3 HDF4 tiles → cloud-optimized GeoTIFFs
#
# For each date:
#   1. For each CONUS tile: extract Flood_1Day_250m SDS via conda GDAL
#      (system GDAL lacks HDF4 support; conda GDAL at ~/miniforge3/bin/ has it)
#   2. Reproject MODIS sinusoidal → EPSG:5070 (Albers Equal Area CONUS)
#      using terra::project(..., method = "near") — categorical values
#   3. Mosaic all tiles into one CONUS raster
#   4. Clip to CONUS bounding box
#   5. Write cloud-optimized GeoTIFF (DEFLATE compressed)
#
# HDF4 SDS path: HDF4_EOS:EOS_GRID:"<file>":Grid_Water_Composite:Flood_1Day_250m
# GDAL command:  ~/miniforge3/bin/gdal_translate <SDS> <out.tif>
#
# Inputs:  data/raw/mcdwd/YYYY/MCDWD_L3.A<YYYY><DDD>.<tile>.061.*.hdf
# Outputs: data/raw/mcdwd/processed/YYYY/flood_<YYYYMMDD>.tif
#
# Memory:  ONE date in memory at a time (~1–2 GB for full CONUS mosaic).
# Runtime: ~5–15 min/year (parallelizable across years if disk I/O allows).
# Resume-safe: skips dates where output .tif already exists.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(lubridate)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
# SDS layer name within the HDF4 EOS grid
SDS_LAYER  <- "Flood_1Day_250m"        # also available: Flood_2Day_250m, Flood_3Day_250m
GRID_NAME  <- "Grid_Water_Composite"
TARGET_CRS <- "EPSG:5070"              # NAD83 / Conus Albers

# CONUS bounding box in EPSG:5070 (metres)
CONUS_BBOX <- ext(-2356113, 2258155, 269823, 3172570)

# conda GDAL binary (required for HDF4 support — system GDAL lacks it)
GDAL_TRANSLATE <- path.expand("~/miniforge3/bin/gdal_translate")
if (!file.exists(GDAL_TRANSLATE)) {
  stop(
    "conda GDAL not found at ~/miniforge3/bin/gdal_translate\n",
    "Install with: conda install -c conda-forge libgdal-hdf4"
  )
}

RAW_DIR  <- here("data", "raw", "mcdwd")
PROC_DIR <- here("data", "raw", "mcdwd", "processed")
dir.create(PROC_DIR, showWarnings = FALSE, recursive = TRUE)

TILES_CONUS <- c(
  "h08v04", "h08v05",
  "h09v04", "h09v05",
  "h10v04", "h10v05",
  "h11v04", "h11v05",
  "h12v04", "h12v05",
  "h13v04"
)

YEARS <- 2000:2025   # adjust to match downloaded data

# ---- Helper: find HDF file for a tile + DOY --------------------------------
find_hdf <- function(yr, doy, tile) {
  pat   <- glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.{tile}\\.")
  files <- list.files(file.path(RAW_DIR, yr), pattern = pat, full.names = TRUE)
  if (length(files) == 0L) return(NULL)
  files[[1L]]
}

# ---- Helper: HDF4 → reprojected GeoTIFF for one tile ----------------------
hdf_to_tif <- function(hdf_path) {
  tmp <- tempfile(fileext = ".tif")
  sds <- glue('HDF4_EOS:EOS_GRID:"{hdf_path}":{GRID_NAME}:{SDS_LAYER}')

  ret <- system2(GDAL_TRANSLATE,
    args   = c("-q", "-of", "GTiff",
               shQuote(sds), shQuote(tmp)),
    stdout = FALSE, stderr = TRUE
  )

  if (!file.exists(tmp) || file.size(tmp) == 0L) {
    message(sprintf("  gdal_translate failed for %s", basename(hdf_path)))
    return(NULL)
  }

  r <- terra::rast(tmp)
  r_proj <- terra::project(r, TARGET_CRS, method = "near")
  file.remove(tmp)
  r_proj
}

# ---- Helper: process one date ----------------------------------------------
process_date <- function(date) {
  yr       <- year(date)
  doy      <- yday(date)
  date_str <- format(date, "%Y%m%d")
  out_dir  <- file.path(PROC_DIR, yr)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_path <- file.path(out_dir, glue("flood_{date_str}.tif"))

  if (file.exists(out_path)) return(invisible("SKIP"))

  # Convert each available tile to a reprojected raster
  tiles_r <- list()
  for (tile in TILES_CONUS) {
    hdf <- find_hdf(yr, doy, tile)
    if (is.null(hdf)) next
    r <- hdf_to_tif(hdf)
    if (!is.null(r)) tiles_r[[tile]] <- r
  }

  if (length(tiles_r) == 0L) {
    message(sprintf("  [%s] No tiles available — skipping", date_str))
    return(invisible("MISSING"))
  }

  # Mosaic tiles (max = flooded pixel wins over no-data)
  mosaic_r <- if (length(tiles_r) == 1L) {
    tiles_r[[1L]]
  } else {
    do.call(terra::mosaic, c(tiles_r, list(fun = "max")))
  }

  # Clip to CONUS
  mosaic_r <- terra::crop(mosaic_r, CONUS_BBOX)

  # Write COG
  terra::writeRaster(
    mosaic_r, out_path,
    filetype  = "COG",
    datatype  = "INT1U",
    overwrite = TRUE,
    gdal      = c("COMPRESS=DEFLATE", "PREDICTOR=2", "OVERVIEW_RESAMPLING=NEAREST")
  )

  rm(tiles_r, mosaic_r)
  gc(verbose = FALSE)
  invisible("OK")
}

# ---- Main loop -------------------------------------------------------------
message("=== Processing MCDWD_L3 HDF4 → COG GeoTIFF ===")
message(sprintf("SDS: %s | CRS: %s | Years: %d–%d",
                SDS_LAYER, TARGET_CRS, min(YEARS), max(YEARS)))
message(sprintf("conda GDAL: %s", GDAL_TRANSLATE))
message("")

for (yr in YEARS) {
  hdfs <- list.files(file.path(RAW_DIR, yr), pattern = "\\.hdf$")
  if (length(hdfs) == 0L) {
    message(sprintf("[%d] No HDF files — skipping (run 01_download.R first)", yr))
    next
  }

  # Unique dates from filenames: MCDWD_L3.A<YYYY><DDD>.<tile>....hdf
  doys  <- unique(as.integer(sub("MCDWD_L3\\.A[0-9]{4}([0-9]{3})\\..+", "\\1", hdfs)))
  dates <- as.Date(doys - 1L, origin = paste0(yr, "-01-01"))
  n     <- length(dates)

  message(sprintf("[%d] %d dates to process ...", yr, n))
  t_start <- Sys.time()

  for (i in seq_along(dates)) {
    process_date(dates[[i]])
    if (i %% 30L == 0L || i == n) {
      elapsed <- round(as.numeric(Sys.time() - t_start, units = "secs"))
      message(sprintf("  [%d] %d/%d dates | %.0fs elapsed", yr, i, n, elapsed))
    }
  }

  n_tifs  <- length(list.files(file.path(PROC_DIR, yr), pattern = "\\.tif$"))
  elapsed <- round(as.numeric(Sys.time() - t_start, units = "secs"))
  message(sprintf("[%d] Done in %.0fs — %d GeoTIFFs written", yr, elapsed, n_tifs))
}

message("")
message("Processing complete. Output: ", PROC_DIR)
