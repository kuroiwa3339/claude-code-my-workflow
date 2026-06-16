# One-time script: download all MCDWD_L3 tiles for 2012 (CONUS, 11 tiles).
# Calls into 01_download.R's functions with year-specific date range.
# Output log: quality_reports/session_logs/download_2012.log

suppressPackageStartupMessages({
  library(here)
  library(lubridate)
  library(glue)
})

# ---- Config (mirrors 01_download.R) ----------------------------------------
TILES_CONUS <- c(
  "h08v04", "h08v05",
  "h09v04", "h09v05",
  "h10v04", "h10v05",
  "h11v04", "h11v05",
  "h12v04", "h12v05",
  "h13v04"
)
LAADS_BASE <- "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3"
COOKIE_JAR <- "/tmp/earthdata_cookies.txt"
RAW_DIR    <- here("data", "raw", "mcdwd")

# ---- Credentials -----------------------------------------------------------
readRenviron("~/.Renviron")
user <- Sys.getenv("EARTHDATA_USER")
pass <- Sys.getenv("EARTHDATA_PASS")
if (nchar(user) == 0L) stop("EARTHDATA_USER not set in ~/.Renviron")

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

# ---- Helpers (same as 01_download.R) ---------------------------------------
list_laads_files <- function(yr, doy) {
  url <- glue("{LAADS_BASE}/{yr}/{sprintf('%03d', doy)}/")
  out <- system2("curl",
    args = c("-s", "-n", "-c", COOKIE_JAR, "-b", COOKIE_JAR, "-L", shQuote(url)),
    stdout = TRUE, stderr = FALSE
  )
  html  <- paste(out, collapse = "\n")
  pat   <- glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.[^\"'<>]+\\.hdf")
  unique(regmatches(html, gregexpr(pat, html))[[1L]])
}

download_one <- function(yr, doy, tile) {
  dest_dir <- file.path(RAW_DIR, yr)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  existing <- list.files(dest_dir,
    pattern = glue("MCDWD_L3\\.A{yr}{sprintf('%03d', doy)}\\.{tile}\\."),
    full.names = FALSE
  )
  if (length(existing) > 0L) return(invisible("SKIP"))

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

  system2("curl",
    args = c("-n", "-c", COOKIE_JAR, "-b", COOKIE_JAR,
             "-L", "--silent", "--show-error",
             "-o", shQuote(dest), shQuote(url)),
    stdout = FALSE, stderr = TRUE
  )

  if (file.exists(dest)) {
    magic   <- readBin(dest, "raw", n = 4L)
    is_hdf4 <- identical(magic, as.raw(c(0x0e, 0x03, 0x13, 0x01)))
    if (!is_hdf4) {
      file.remove(dest)
      message(sprintf("  [ERROR] %s — not a valid HDF4 file", fname))
      return(invisible("ERROR"))
    }
  }
  invisible("OK")
}

# ---- 2012 download loop ----------------------------------------------------
yr        <- 2012L
all_dates <- seq(as.Date("2012-01-01"), as.Date("2012-12-31"), by = "day")
n_dates   <- length(all_dates)   # 366 (leap year)
n_total   <- n_dates * length(TILES_CONUS)

message(sprintf("=== MCDWD_L3 2012 download ==="))
message(sprintf("Tiles: %d | Dates: %d | Files: ~%d", length(TILES_CONUS), n_dates, n_total))
message(sprintf("Output: %s/2012/", RAW_DIR))
message(sprintf("Started: %s", Sys.time()))
message("")

t0 <- Sys.time()

for (i in seq_along(all_dates)) {
  d   <- all_dates[[i]]
  doy <- yday(d)
  for (tile in TILES_CONUS) {
    download_one(yr, doy, tile)
  }
  if (i %% 30L == 0L || i == n_dates) {
    elapsed  <- round(as.numeric(Sys.time() - t0, units = "secs"))
    n_disk   <- length(list.files(file.path(RAW_DIR, yr), pattern = "\\.hdf$"))
    rate     <- n_disk / max(elapsed, 1)
    eta_secs <- round((n_total - n_disk) / max(rate, 0.001))
    message(sprintf("[2012] %d/%d dates | %d/%d files | %.0fs elapsed | ETA ~%.0fm",
                    i, n_dates, n_disk, n_total, elapsed, eta_secs / 60))
  }
}

n_final <- length(list.files(file.path(RAW_DIR, yr), pattern = "\\.hdf$"))
elapsed  <- round(as.numeric(Sys.time() - t0, units = "mins"), 1)
message("")
message(sprintf("=== Done: %d/%d files in %.1f min ===", n_final, n_total, elapsed))
