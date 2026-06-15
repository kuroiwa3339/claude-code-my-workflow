# =============================================================================
# 01_download.R — Download NASA MCDWD_L3 flood detection tiles from LAADS DAAC.
#
# Archive data (2000–present) is at:
#   https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3/
#
# Prerequisites:
#   ~/.Renviron must contain:
#     EARTHDATA_USER=<your_username>
#     EARTHDATA_PASS=<your_password>
#   Get credentials at: https://urs.earthdata.nasa.gov/
#
#   ~/.netrc is set up automatically by this script on first run.
#
# Inputs:  None (downloads from NASA servers)
# Outputs: data/raw/mcdwd/YYYY/MCDWD_L3.A<YYYY><DDD>.<tile>.061.*.hdf
#
# File naming: MCDWD_L3.A<YYYY><DDD>.<tile>.061.<processing_timestamp>.hdf
# Runtime:     Budget ~8–10 MB per tile per day, ~10–30 GB per year (11 tiles).
# Resume-safe: skips files that already exist on disk.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(lubridate)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
TILES_CONUS <- c(
  "h08v04", "h08v05",
  "h09v04", "h09v05",
  "h10v04", "h10v05",
  "h11v04", "h11v05",
  "h12v04", "h12v05",
  "h13v04"
)

DATE_START <- as.Date("2000-02-24")   # first available MCDWD_L3 date
DATE_END   <- as.Date("2025-12-31")   # adjust as needed

LAADS_BASE <- "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3"
COOKIE_JAR <- "/tmp/earthdata_cookies.txt"
RAW_DIR    <- here("data", "raw", "mcdwd")
dir.create(RAW_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Credentials via ~/.netrc -----------------------------------------------
# LAADS DAAC requires OAuth via URS — basic auth headers don't work.
# ~/.netrc + curl cookie jar is the supported approach.
readRenviron("~/.Renviron")
user <- Sys.getenv("EARTHDATA_USER")
pass <- Sys.getenv("EARTHDATA_PASS")

if (nchar(user) == 0L || nchar(pass) == 0L) {
  stop(
    "NASA EarthData credentials not found in ~/.Renviron.\n",
    "Add:\n  EARTHDATA_USER=<username>\n  EARTHDATA_PASS=<password>\n",
    "Then run: readRenviron('~/.Renviron')"
  )
}

# Write ~/.netrc (idempotent — overwrites each run to stay current)
netrc_path <- path.expand("~/.netrc")
writeLines(c(
  "machine urs.earthdata.nasa.gov",
  glue("    login {user}"),
  glue("    password {pass}"),
  "machine ladsweb.modaps.eosdis.nasa.gov",
  glue("    login {user}"),
  glue("    password {pass}")
), netrc_path)
Sys.chmod(netrc_path, mode = "0600")
message("~/.netrc configured.")

# ---- Helpers ----------------------------------------------------------------
# List all files on LAADS DAAC for a given year + DOY
list_laads_files <- function(yr, doy) {
  url <- glue("{LAADS_BASE}/{yr}/{sprintf('%03d', doy)}/")
  out <- system2("curl",
    args = c("-s", "-n",
             "-c", COOKIE_JAR, "-b", COOKIE_JAR,
             "-L", shQuote(url)),
    stdout = TRUE, stderr = FALSE
  )
  html  <- paste(out, collapse = "\n")
  pat   <- glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.[^\"'<>]+\\.hdf")
  fnames <- unique(regmatches(html, gregexpr(pat, html))[[1L]])
  fnames
}

# Download one file (resume-safe)
download_one <- function(yr, doy, tile) {
  dest_dir <- file.path(RAW_DIR, yr)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  # Check if any file for this tile+date already exists
  existing <- list.files(dest_dir,
    pattern = glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.{tile}\\."),
    full.names = FALSE
  )
  if (length(existing) > 0L) return(invisible("SKIP"))

  # Get exact filename from server index (processing timestamp varies)
  all_files <- list_laads_files(yr, doy)
  tile_pat  <- glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.{tile}\\.")
  fname     <- all_files[grepl(tile_pat, all_files)]

  if (length(fname) == 0L) {
    message(sprintf("  [MISSING] %d DOY%03d %s", yr, doy, tile))
    return(invisible("MISSING"))
  }
  fname <- fname[[1L]]
  dest  <- file.path(dest_dir, fname)
  url   <- glue("{LAADS_BASE}/{yr}/{sprintf('%03d', doy)}/{fname}")

  result <- system2("curl",
    args = c("-n",
             "-c", COOKIE_JAR, "-b", COOKIE_JAR,
             "-L", "--silent", "--show-error",
             "-o", shQuote(dest),
             shQuote(url)),
    stdout = FALSE, stderr = TRUE
  )

  # Verify we got a real HDF4 file (not an HTML error page)
  if (file.exists(dest)) {
    magic <- readBin(dest, "raw", n = 4L)
    is_hdf4 <- identical(magic, as.raw(c(0x0e, 0x03, 0x13, 0x01)))
    if (!is_hdf4) {
      file.remove(dest)
      message(sprintf("  [ERROR] %s — not a valid HDF4 file (auth issue?)", fname))
      return(invisible("ERROR"))
    }
  }

  invisible("OK")
}

# ---- Main loop --------------------------------------------------------------
all_dates <- seq(DATE_START, DATE_END, by = "day")
years     <- sort(unique(year(all_dates)))
n_total   <- length(all_dates) * length(TILES_CONUS)

message(sprintf("=== MCDWD_L3 download: %s to %s ===", DATE_START, DATE_END))
message(sprintf("Tiles: %d | Dates: %d | Total files: ~%d",
                length(TILES_CONUS), length(all_dates), n_total))
message("Output: ", RAW_DIR)
message("")

n_done <- 0L
for (yr in years) {
  yr_dates <- all_dates[year(all_dates) == yr]
  t_yr     <- Sys.time()
  message(sprintf("[%d] %d dates ...", yr, length(yr_dates)))

  for (d in yr_dates) {
    d   <- as.Date(d, origin = "1970-01-01")
    doy <- yday(d)
    for (tile in TILES_CONUS) {
      download_one(yr, doy, tile)
      n_done <- n_done + 1L
    }
    if (yday(d) %% 30L == 0L) {
      message(sprintf("  [%d] DOY %03d — %d/%d files processed",
                      yr, doy, n_done, n_total))
    }
  }

  n_yr <- length(list.files(file.path(RAW_DIR, yr), pattern = "\\.hdf$"))
  elapsed <- round(as.numeric(Sys.time() - t_yr, units = "mins"), 1)
  message(sprintf("[%d] Done in %.1f min — %d HDF files on disk", yr, elapsed, n_yr))
}

message("")
n_total_disk <- length(list.files(RAW_DIR, pattern = "\\.hdf$", recursive = TRUE))
message(sprintf("Download complete. Total HDF files on disk: %d", n_total_disk))
