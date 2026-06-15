# =============================================================================
# 06_descriptives.R — Summary statistics, maps, and descriptive figures.
#
# Produces publication-ready figures and summary tables from the county and
# ZIP panel datasets. Figures go to scripts/R/_outputs/.
#
# Inputs:  data/final/county_flood_panel.rds
#          data/final/zip_flood_panel.rds
# Outputs: scripts/R/_outputs/
#   - fig_flood_days_per_year.pdf     (time series)
#   - fig_county_total_flood_days.pdf (choropleth map)
#   - tab_summary_stats.csv           (summary table)
#   - tab_top10_flood_counties.csv    (most-flooded counties)
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(ggplot2)
  library(sf)
  library(tigris)
  library(scales)
  library(readr)
  library(glue)
})

if (exists("PROJECT_SEED", inherits = FALSE)) set.seed(PROJECT_SEED)

OUT_DIR  <- here("scripts", "R", "_outputs")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Project palette -------------------------------------------------------
PAL <- list(
  primary   = "#1b4f72",   # dark blue
  secondary = "#2980b9",   # medium blue
  accent    = "#e67e22",   # orange (flood events)
  light     = "#d6eaf8",   # pale blue
  text      = "#2c3e50"    # near-black
)

theme_flood <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title    = element_text(face = "bold", color = PAL$text),
      plot.subtitle = element_text(color = PAL$text, size = base_size * 0.85),
      axis.text     = element_text(color = PAL$text),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom"
    )
}

# ---- Load data -------------------------------------------------------------
message("Loading county flood panel ...")
county_path <- here("data", "final", "county_flood_panel.rds")
if (!file.exists(county_path)) {
  stop("county_flood_panel.rds not found. Run 05_build_panel.R first.")
}
panel <- readRDS(county_path)
message(sprintf("  %s rows | %d counties | %d dates",
                format(nrow(panel), big.mark = ","),
                n_distinct(panel$fips5),
                n_distinct(panel$date)))

# ---- Figure 1: Total flooded area over time --------------------------------
message("Generating fig_flood_days_per_year ...")

annual_conus <- panel |>
  filter(!is.na(flood_fraction), low_coverage == 0L) |>
  group_by(year, date) |>
  summarise(
    n_flooded_counties = sum(any_flood, na.rm = TRUE),
    .groups = "drop"
  ) |>
  group_by(year) |>
  summarise(
    mean_flooded_counties = mean(n_flooded_counties, na.rm = TRUE),
    max_flooded_counties  = max(n_flooded_counties, na.rm = TRUE),
    .groups = "drop"
  )

fig1 <- ggplot(annual_conus, aes(x = year, y = mean_flooded_counties)) +
  geom_line(color = PAL$secondary, linewidth = 1) +
  geom_point(color = PAL$primary, size = 2) +
  geom_col(aes(y = max_flooded_counties), fill = PAL$light, alpha = 0.4) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title    = "US County Flood Events Over Time",
    subtitle = "Mean daily flooded counties (line) and annual peak (bars), 2000–present",
    x        = NULL,
    y        = "Number of counties with any flood"
  ) +
  theme_flood()

ggsave(file.path(OUT_DIR, "fig_flood_days_per_year.pdf"),
       fig1, width = 10, height = 5, bg = "transparent")
message("  Saved fig_flood_days_per_year.pdf")

# ---- Figure 2: Choropleth map of total flood days --------------------------
message("Generating fig_county_total_flood_days ...")

county_totals <- panel |>
  filter(!is.na(flood_fraction), low_coverage == 0L) |>
  group_by(fips5) |>
  summarise(total_flood_days = sum(any_flood, na.rm = TRUE), .groups = "drop")

# Get county geometries
counties_sf <- tigris::counties(cb = TRUE, resolution = "20m", year = 2020,
                                 progress_bar = FALSE) |>
  sf::st_transform("EPSG:5070") |>
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) |>
  left_join(county_totals, by = c("GEOID" = "fips5"))

fig2 <- ggplot(counties_sf) +
  geom_sf(aes(fill = total_flood_days), color = NA) +
  scale_fill_gradient(
    low    = PAL$light,
    high   = PAL$primary,
    na.value = "grey85",
    name   = "Total flood days",
    labels = scales::comma
  ) +
  labs(
    title    = "Total MODIS-Detected Flood Days by County",
    subtitle = "2000–present | MCDWD_L3 (250m), any_flood threshold ≥ 1% of area"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", color = PAL$text),
    plot.subtitle = element_text(color = PAL$text),
    legend.position = "right"
  )

ggsave(file.path(OUT_DIR, "fig_county_total_flood_days.pdf"),
       fig2, width = 12, height = 7, bg = "transparent")
message("  Saved fig_county_total_flood_days.pdf")

# ---- Table: Summary statistics ---------------------------------------------
message("Generating tab_summary_stats ...")

summary_stats <- panel |>
  filter(!is.na(flood_fraction)) |>
  summarise(
    n_county_days         = n(),
    n_counties            = n_distinct(fips5),
    n_dates               = n_distinct(date),
    date_min              = min(date),
    date_max              = max(date),
    pct_any_flood         = 100 * mean(any_flood, na.rm = TRUE),
    pct_moderate_flood    = 100 * mean(moderate_flood, na.rm = TRUE),
    pct_severe_flood      = 100 * mean(severe_flood, na.rm = TRUE),
    mean_flood_fraction   = mean(flood_fraction, na.rm = TRUE),
    median_flood_fraction = median(flood_fraction, na.rm = TRUE),
    pct_low_coverage      = 100 * mean(low_coverage == 1L, na.rm = TRUE)
  )

readr::write_csv(summary_stats, file.path(OUT_DIR, "tab_summary_stats.csv"))
message("  Saved tab_summary_stats.csv")

# ---- Table: Top 10 most-flooded counties -----------------------------------
top10 <- county_totals |>
  arrange(desc(total_flood_days)) |>
  slice_head(n = 10L)

readr::write_csv(top10, file.path(OUT_DIR, "tab_top10_flood_counties.csv"))
message("  Saved tab_top10_flood_counties.csv")

message("")
message("Descriptives complete. Output: ", OUT_DIR)
