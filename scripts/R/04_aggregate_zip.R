# =============================================================================
# 04_aggregate_zip.R — Aggregate MCDWD flood rasters to ZIP code (ZCTA) level.
#
# Mirrors 03_aggregate_county.R but uses ZIP Code Tabulation Areas (ZCTAs).
# ZCTAs are the Census approximation of USPS ZIP codes; they are larger than
# counties in some regions and smaller in metro areas (~33,000 total).
#
# ZCTAs do NOT update annually; we use the 2020 ZCTA boundaries throughout.
# For analyses requiring temporal ZCTA–county crosswalks (e.g., FEMA data),
# use the HUD USPS ZIP–county crosswalk in a downstream script.
#
# Inputs:  data/raw/mcdwd/processed/YYYY/flood_YYYYMMDD.tif
# Outputs: data/processed/zip/zip_flood_YYYY.rds
#
# Runtime: ~15–30 min/year (ZCTAs are numerous; parallelization essential).
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
  library(furrr)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

# ---- Configuration ---------------------------------------------------------
TARGET_CRS  <- "EPSG:5070"
FLOOD_CODE  <- 3L
VALID_CODES <- c(0L, 3L, 4L)

N_WORKERS   <- max(1L, parallel::detectCores() - 2L)

PROC_DIR   <- here("data", "raw", "mcdwd", "processed")
OUT_DIR    <- here("data", "processed", "zip")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

YEARS      <- 2000:year(Sys.Date())

# ---- Load ZCTA boundaries (once) -------------------------------------------
message("Loading ZCTA boundaries via tigris ...")
zcta_sf <- tigris::zctas(cb = TRUE, year = 2020, progress_bar = FALSE) |>
  sf::st_transform(TARGET_CRS) |>
  dplyr::select(GEOID20)

# Drop ZCTAs entirely outside CONUS bounding box (AK, HI, territories)
conus_bbox <- sf::st_bbox(c(xmin = -2356113, xmax = 2258155,
                             ymin =  269823,  ymax = 3172570),
                           crs = sf::st_crs(TARGET_CRS))
zcta_sf <- zcta_sf[sf::st_intersects(zcta_sf, sf::st_as_sfc(conus_bbox),
                                      sparse = FALSE)[, 1L], ]

message(sprintf("  %d ZCTAs loaded (CONUS footprint)", nrow(zcta_sf)))
stopifnot("ZCTA CRS must match TARGET_CRS" =
  sf::st_crs(zcta_sf) == sf::st_crs(TARGET_CRS))

# ---- Per-date aggregation --------------------------------------------------
aggregate_one_date <- function(tif_path) {
  tryCatch({
    date_str <- sub("flood_", "", tools::file_path_sans_ext(basename(tif_path)))
    date     <- as.Date(date_str, format = "%Y%m%d")

    r <- terra::rast(tif_path)

    extracts <- exactextractr::exact_extract(
      x        = r,
      y        = zcta_sf,
      fun      = NULL,
      progress = FALSE
    )

    out <- purrr::map_dfr(seq_along(extracts), function(i) {
      px <- extracts[[i]]
      dplyr::tibble(
        ZCTA5CE20     = zcta_sf$GEOID20[[i]],
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
message(sprintf("=== ZIP aggregation (N_WORKERS = %d) ===", N_WORKERS))

for (yr in YEARS) {
  out_path <- file.path(OUT_DIR, glue("zip_flood_{yr}.rds"))
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

  message(sprintf("[%d] Aggregating %d dates across %d ZCTAs ...",
                  yr, length(tif_files), nrow(zcta_sf)))
  t_start <- Sys.time()

  results <- furrr::future_map(
    tif_files, aggregate_one_date,
    .options = furrr::furrr_options(seed = TRUE)
  )

  results_df <- dplyr::bind_rows(Filter(Negate(is.null), results)) |>
    dplyr::arrange(ZCTA5CE20, date)

  saveRDS(results_df, out_path, compress = "xz")

  elapsed <- as.numeric(Sys.time() - t_start, units = "secs")
  message(sprintf("[%d] Done in %.0fs — %d ZCTA-date rows written",
                  yr, elapsed, nrow(results_df)))
}

message("")
message("ZIP aggregation complete. Output: ", OUT_DIR)
