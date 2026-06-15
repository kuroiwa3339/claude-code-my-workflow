# =============================================================================
# 01_download.R — Download NASA MCDWD_L3 flood detection tiles.
#
# Downloads HDF/GeoTIFF files from NASA EarthData (AppEEARS API or LANCE HTTPS)
# for the specified date range and MODIS tile set covering CONUS.
#
# Prerequisites:
#   ~/.Renviron must contain:
#     EARTHDATA_USER=<your_username>
#     EARTHDATA_PASS=<your_password>
#   Get credentials at: https://urs.earthdata.nasa.gov/
#
# Inputs:  None (downloads from NASA servers)
# Outputs: data/raw/mcdwd/YYYY/MCDWD_L3_<tile>_<date>.hdf
#
# Runtime: Highly variable. Budget ~10–30 GB per year of daily data.
# Resume-safe: skips files that already exist on disk.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(httr2)
  library(lubridate)
  library(dplyr)
  library(purrr)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
# Adjust these to your study window and coverage area.

# MODIS sinusoidal tile grid tiles covering CONUS (lower 48 states).
# See tile map: https://modis-land.gsfc.nasa.gov/MODLAND_grid.html
TILES_CONUS <- c(
  "h08v04", "h08v05",
  "h09v04", "h09v05",
  "h10v04", "h10v05",
  "h11v04", "h11v05",
  "h12v04", "h12v05",
  "h13v04"
)

# Date range — MCDWD_L3 available from 2000-02-24 onward.
DATE_START <- as.Date("2000-02-24")
DATE_END   <- Sys.Date() - 1L  # yesterday (current products may lag by ~1 day)

# MCDWD_L3 product details
PRODUCT  <- "MCDWD_L3F"         # daily flood product (also: MCDWD_L3_NRT for near-real-time)
VERSION  <- "061"               # Collection 6.1

RAW_DIR <- here("data", "raw", "mcdwd")
dir.create(RAW_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Credentials -----------------------------------------------------------
user <- Sys.getenv("EARTHDATA_USER")
pass <- Sys.getenv("EARTHDATA_PASS")

if (nchar(user) == 0L || nchar(pass) == 0L) {
  stop(
    "NASA EarthData credentials not found.\n",
    "Add to ~/.Renviron:\n",
    "  EARTHDATA_USER=<username>\n",
    "  EARTHDATA_PASS=<password>\n",
    "Then restart R (or run readRenviron('~/.Renviron'))."
  )
}

# ---- Build download list ---------------------------------------------------
# LANCE HTTPS server for MCDWD_L3 files.
# Pattern: https://nrt3.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3F/<YYYY>/<DDD>/
lance_base <- "https://nrt3.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3F"

all_dates <- seq(DATE_START, DATE_END, by = "day")
years     <- unique(year(all_dates))

# Helper: build expected filename for a tile + date
mcdwd_filename <- function(tile, date) {
  yr  <- year(date)
  doy <- yday(date)
  glue("MCDWD_L3F.A{yr}{sprintf('%03d', doy)}.{tile}.{VERSION}.*.hdf")
}

# Helper: check if file already downloaded (glob match, version may vary)
already_downloaded <- function(dest_dir, tile, date) {
  pattern <- mcdwd_filename(tile, date)
  length(Sys.glob(file.path(dest_dir, pattern))) > 0L
}

# Helper: download a single tile × date (resume-safe)
download_one <- function(tile, date) {
  yr      <- year(date)
  doy     <- yday(date)
  dest_dir <- file.path(RAW_DIR, yr)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  if (already_downloaded(dest_dir, tile, date)) {
    return(invisible("SKIP"))
  }

  # List available files for this date from LANCE
  url_dir <- glue("{lance_base}/{yr}/{sprintf('%03d', doy)}/")

  tryCatch({
    resp <- request(url_dir) |>
      req_auth_basic(user, pass) |>
      req_timeout(30) |>
      req_perform()

    # Parse HTML index to find tile-specific filename
    html  <- resp_body_string(resp)
    fnames <- regmatches(html, gregexpr(
      glue("MCDWD_L3F\\.A{yr}{sprintf('%03d', doy)}\\.{tile}\\.[0-9]+\\.[0-9]+\\.hdf"),
      html
    ))[[1L]]

    if (length(fnames) == 0L) {
      message(sprintf("  No file for %s %s", tile, date))
      return(invisible("MISSING"))
    }

    fname    <- fnames[[1L]]
    file_url <- paste0(url_dir, fname)
    dest     <- file.path(dest_dir, fname)

    request(file_url) |>
      req_auth_basic(user, pass) |>
      req_timeout(300) |>
      req_perform(path = dest)

    invisible("OK")
  }, error = function(e) {
    message(sprintf("  ERROR: %s %s — %s", tile, date, conditionMessage(e)))
    invisible("ERROR")
  })
}

# ---- Download loop ---------------------------------------------------------
message(sprintf("Downloading MCDWD_L3 for %d dates × %d tiles...",
                length(all_dates), length(TILES_CONUS)))
message(sprintf("Date range: %s to %s", DATE_START, DATE_END))
message("Files go to: ", RAW_DIR)
message("")

n_total <- length(all_dates) * length(TILES_CONUS)
n_done  <- 0L

for (date in all_dates) {
  date <- as.Date(date, origin = "1970-01-01")
  yr   <- year(date)
  message(sprintf("[%s] Year %d ...", Sys.time(), yr))

  for (tile in TILES_CONUS) {
    status <- download_one(tile, date)
    n_done <- n_done + 1L
    if (status != "SKIP" && n_done %% 50L == 0L) {
      message(sprintf("  Progress: %d / %d", n_done, n_total))
    }
  }
}

message("")
n_files <- length(list.files(RAW_DIR, pattern = "\\.hdf$", recursive = TRUE))
message(sprintf("Download complete. Total HDF files on disk: %d", n_files))
