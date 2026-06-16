# =============================================================================
# map_flood_20120830.R  — 2012-08-30 flood map (Hurricane Isaac day)
#
# Uses the single downloaded tile: MCDWD_L3.A2012243.h08v04
# Converts HDF4 → GeoTIFF via conda GDAL, reprojects to EPSG:5070,
# then plots with ggplot2 + US state boundaries from tigris.
#
# Run in RStudio: Rscript scripts/R/map_flood_20120830.R
# or open + Source in RStudio to see the plot pane.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
  library(tigris)
  library(ggplot2)
  library(dplyr)
})

options(tigris_use_cache = TRUE)

# ---- Paths -----------------------------------------------------------------
HDF_FILE  <- here("data", "raw", "mcdwd", "2012",
                  "MCDWD_L3.A2012243.h08v04.061.2025263092157.hdf")
GDAL_TR   <- path.expand("~/miniforge3/bin/gdal_translate")
SDS_PATH  <- sprintf(
  'HDF4_EOS:EOS_GRID:"%s":Grid_Water_Composite:Flood_1Day_250m', HDF_FILE
)
TMP_TIF   <- tempfile(fileext = ".tif")
OUT_PNG   <- here("scripts", "R", "_outputs", "flood_map_20120830.png")
dir.create(here("scripts", "R", "_outputs"), showWarnings = FALSE, recursive = TRUE)

# ---- 1. HDF4 → GeoTIFF via conda GDAL -------------------------------------
message("Converting HDF4 → GeoTIFF ...")
if (!file.exists(HDF_FILE)) stop("HDF file not found: ", HDF_FILE)
if (!file.exists(GDAL_TR))  stop("conda GDAL not found: ", GDAL_TR)

system2(GDAL_TR, args = c("-q", "-of", "GTiff", shQuote(SDS_PATH), shQuote(TMP_TIF)))
if (!file.exists(TMP_TIF)) stop("gdal_translate failed")

# ---- 2. Read, recode, reproject to EPSG:5070 -------------------------------
message("Reprojecting to EPSG:5070 ...")
r_raw  <- terra::rast(TMP_TIF)
r_5070 <- terra::project(r_raw, "EPSG:5070", method = "near")
file.remove(TMP_TIF)

# Recode to meaningful factor
# 0=no flood, 1=no data, 2=cloud, 3=flood, 4=open water
r_cat <- terra::classify(r_5070, cbind(
  c(0, 1, 2, 3, 4),
  c(0, 1, 2, 3, 4)
))

# Convert raster to data.frame for ggplot2
message("Building plot data ...")
df <- as.data.frame(r_cat, xy = TRUE, na.rm = TRUE)
names(df)[3] <- "flood_code"
df$category <- factor(df$flood_code,
  levels = c(0, 1, 2, 3, 4),
  labels = c("No flood", "No data", "Cloud", "Flood", "Open water")
)

flood_colors <- c(
  "No flood"   = "#e8f4f8",   # light blue-gray
  "No data"    = "#d0d0d0",   # gray
  "Cloud"      = "#b0c4de",   # steel blue
  "Flood"      = "#d62728",   # vivid red
  "Open water" = "#1f77b4"    # blue
)

# ---- 3. US state boundaries (CONUS only) -----------------------------------
message("Fetching state boundaries ...")
states_sf <- tigris::states(cb = TRUE, progress_bar = FALSE) |>
  filter(!STUSPS %in% c("AK", "HI", "PR", "GU", "VI", "MP", "AS")) |>
  sf::st_transform(5070)

# Tile bounding box in 5070 for context rectangle
tile_bbox <- terra::as.polygons(terra::ext(r_5070), crs = "EPSG:5070") |>
  sf::st_as_sf()

# ---- 4. Pixel counts for subtitle ------------------------------------------
n_flood <- sum(df$flood_code == 3L)
n_valid <- sum(df$flood_code %in% c(0L, 3L, 4L))
pct_flood <- round(100 * n_flood / max(n_valid, 1L), 1)

# ---- 5. Plot ----------------------------------------------------------------
message("Rendering map ...")
p <- ggplot() +
  # Raster layer: only plot non-"No data" cells with color
  geom_raster(
    data   = df |> filter(category != "No data"),
    aes(x = x, y = y, fill = category),
    alpha  = 0.85
  ) +
  # US state outlines
  geom_sf(data = states_sf, fill = NA, color = "gray40", linewidth = 0.3) +
  # Tile boundary outline
  geom_sf(data = tile_bbox, fill = NA, color = "#ff7f0e", linewidth = 0.7, linetype = "dashed") +
  scale_fill_manual(values = flood_colors, name = "MCDWD Class") +
  coord_sf(crs = 5070, datum = NA,
           # Zoom to tile extent + buffer
           xlim = c(terra::xmin(r_5070) - 2e5, terra::xmax(r_5070) + 2e5),
           ylim = c(terra::ymin(r_5070) - 2e5, terra::ymax(r_5070) + 2e5)) +
  labs(
    title    = "MODIS MCDWD_L3 Flood Detection — 2012-08-30",
    subtitle = sprintf(
      "Tile h08v04 | %s flooded pixels (%s%% of valid area) | Hurricane Isaac",
      format(n_flood, big.mark = ","), pct_flood
    ),
    caption  = "Source: NASA MCDWD_L3 v061 (250m) · EPSG:5070 (NAD83/Conus Albers)\nOrange dashed box = tile extent",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    plot.subtitle   = element_text(color = "gray30"),
    plot.caption    = element_text(color = "gray50", size = 9),
    legend.position = "right",
    panel.grid      = element_blank()
  )

# Display in RStudio plot pane
print(p)

# Save to file
ggsave(OUT_PNG, p, width = 10, height = 7, dpi = 150, bg = "white")
message("Saved: ", OUT_PNG)

# ---- 6. Tile-level summary -------------------------------------------------
cat("\n=== Pixel summary (tile h08v04, 2012-08-30) ===\n")
code_counts <- table(df$flood_code)
for (code in names(code_counts)) {
  label <- c("0"="No flood","1"="No data","2"="Cloud","3"="FLOOD","4"="Open water")[[code]]
  cat(sprintf("  Code %s (%s): %s pixels\n",
              code, label, format(as.integer(code_counts[[code]]), big.mark = ",")))
}
cat(sprintf("  -> Flood fraction (valid pixels): %.2f%%\n", pct_flood))
