# Test: download one MCDWD tile for 2012 from LAADS DAAC
readRenviron("~/.Renviron")
library(httr2)
library(here)

user <- Sys.getenv("EARTHDATA_USER")
pass <- Sys.getenv("EARTHDATA_PASS")

# 2012-02-29 (leap year, DOY 060), tile h08v04 (covers SE USA / Gulf Coast)
yr   <- 2012
doy  <- 60
tile <- "h08v04"

url_dir <- sprintf(
  "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/61/MCDWD_L3F/%d/%03d/",
  yr, doy
)
cat("Checking:", url_dir, "\n")

resp <- tryCatch(
  request(url_dir) |>
    req_auth_basic(user, pass) |>
    req_timeout(30) |>
    req_perform(),
  error = function(e) e
)

if (inherits(resp, "error")) {
  stop("Connection failed: ", conditionMessage(resp))
}

cat("HTTP status:", resp_status(resp), "\n")
html   <- resp_body_string(resp)
pat    <- paste0("MCDWD_L3F\\.A", yr, sprintf("%03d", doy), "\\.", tile, "\\.[0-9]+\\.[0-9]+\\.hdf")
fnames <- regmatches(html, gregexpr(pat, html))[[1]]

if (length(fnames) == 0L) {
  # Show all available files for this DOY to debug
  all_f <- regmatches(html, gregexpr("MCDWD_L3F[^\"'<>]+\\.hdf", html))[[1]]
  cat("No file found for tile", tile, "\n")
  cat("Available tiles for DOY", doy, "(first 5):\n")
  print(head(all_f, 5))
  stop("File not found.")
}

fname    <- fnames[[1L]]
dest_dir <- here("data", "raw", "mcdwd", yr)
dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
dest     <- file.path(dest_dir, fname)
file_url <- paste0(url_dir, fname)

cat("Downloading:", fname, "\n")
cat("Destination:", dest, "\n")

request(file_url) |>
  req_auth_basic(user, pass) |>
  req_timeout(300) |>
  req_perform(path = dest)

info <- file.info(dest)
cat(sprintf("Done. File size: %.1f MB\n", info$size / 1e6))
