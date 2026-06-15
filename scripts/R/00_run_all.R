# =============================================================================
# 00_run_all.R — Flood panel pipeline orchestrator.
#
# Run this script to execute the full MCDWD_L3 → county/ZIP panel pipeline.
# Individual scripts can also be sourced directly for debugging, but running
# via this orchestrator guarantees consistent seed, paths, and timing logs.
#
# Usage:
#   Rscript scripts/R/00_run_all.R
#   Rscript scripts/R/00_run_all.R --stages 03,04   # run only named stages
#
# Reproducibility contract:
#   - Fixed seed set below (applies to stochastic stages like bootstrap CIs).
#   - All paths via here::here() — no setwd().
#   - sessionInfo() written to _outputs/ for environment verification.
# =============================================================================

suppressPackageStartupMessages({
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Install 'here' first: install.packages('here')")
  }
  library(here)
})

# Seed for any stochastic steps (bootstrap CIs in descriptives, etc.)
PROJECT_SEED <- 20260615L
set.seed(PROJECT_SEED)

# Output dir for figures, tables, sessionInfo
OUT_DIR <- here("scripts", "R", "_outputs")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Parse --stages argument ------------------------------------------------
args        <- commandArgs(trailingOnly = TRUE)
stage_flag  <- grep("^--stages=", args, value = TRUE)
run_stages  <- if (length(stage_flag)) {
  strsplit(sub("^--stages=", "", stage_flag), ",")[[1]]
} else {
  NULL  # NULL = run all
}

# ---- Pipeline definition ---------------------------------------------------
pipeline <- list(
  "01" = "01_download.R",
  "02" = "02_process_rasters.R",
  "03" = "03_aggregate_county.R",
  "04" = "04_aggregate_zip.R",
  "05" = "05_build_panel.R",
  "06" = "06_descriptives.R",
  "07" = "07_validate.R"
)

to_run <- if (is.null(run_stages)) {
  pipeline
} else {
  pipeline[run_stages]
}

# Shared environment — scripts communicate through this, not global state
pipeline_env                <- new.env(parent = globalenv())
pipeline_env$PROJECT_SEED  <- PROJECT_SEED
pipeline_env$OUT_DIR        <- OUT_DIR
pipeline_env$DATA_DIR       <- here("data")

message("=== MCDWD Flood Panel Pipeline ===")
message("Seed: ", PROJECT_SEED)
message("Stages: ", paste(names(to_run), collapse = ", "))
message("")

timings <- vapply(names(to_run), function(key) {
  script <- to_run[[key]]
  path   <- here("scripts", "R", script)
  if (!file.exists(path)) {
    stop("Missing pipeline script: ", path)
  }
  message(sprintf("[%s] Starting %s ...", key, script))
  start <- Sys.time()
  source(path, local = pipeline_env)
  elapsed <- as.numeric(Sys.time() - start, units = "secs")
  message(sprintf("[%s] Done in %.1fs", key, elapsed))
  elapsed
}, numeric(1))

# ---- Session capture -------------------------------------------------------
writeLines(capture.output(sessionInfo()),
           con = file.path(OUT_DIR, "sessionInfo.txt"))

# ---- Summary ---------------------------------------------------------------
message("")
message("=== Pipeline complete ===")
message(sprintf("Total time: %.1fs (%.1f min)", sum(timings), sum(timings) / 60))
message("Check quality_reports/diagnoses/ for validation output.")

invisible(list(timings = timings))
