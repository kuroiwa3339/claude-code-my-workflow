---
paths:
  - "Figures/**/*.R"
  - "scripts/**/*.R"
  - "explorations/**/*.R"
---

# R Code Standards

**Standard:** Senior Principal Data Engineer + PhD researcher quality

> **Scope:** These standards apply to **analysis scripts** — data work, simulations, figure generation (a top-level `set.seed()`, `library()` at the top, relative output paths). For R **package source** (`R/`, `tests/`, `DESCRIPTION`, `NAMESPACE`, `man/`), see [`r-package-conventions.md`](r-package-conventions.md), which has different rules (roxygen-generated `NAMESPACE`, no `library()` in `R/`, CRAN policy). The numerical discipline in §8 applies to both.

---

## 1. Reproducibility

- `set.seed()` called ONCE at top (YYYYMMDD format)
- All packages loaded at top via `library()` (not `require()`)
- All paths relative to repository root
- `dir.create(..., recursive = TRUE)` for output directories

## 2. Function Design

- `snake_case` naming, verb-noun pattern
- Roxygen-style documentation
- Default parameters, no magic numbers
- Named return values (lists or tibbles)

## 3. Domain Correctness

<!-- Customize for your field's known pitfalls -->
- Verify estimator implementations match slide formulas
- Check known package bugs (document below in Common Pitfalls)

## 4. Visual Identity

```r
# --- Your institutional palette ---
primary_blue  <- "#012169"
primary_gold  <- "#f2a900"
accent_gray   <- "#525252"
positive_green <- "#15803d"
negative_red  <- "#b91c1c"
```

### Custom Theme
```r
theme_custom <- function(base_size = 14) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", color = primary_blue),
      legend.position = "bottom"
    )
}
```

### Figure Dimensions for Beamer
```r
ggsave(filepath, width = 12, height = 5, bg = "transparent")
```

## 5. RDS Data Pattern

**Heavy computations saved as RDS; slide rendering loads pre-computed data.**

```r
saveRDS(result, file.path(out_dir, "descriptive_name.rds"))
```

## 6. Common Pitfalls

<!-- Add your field-specific pitfalls here -->
| Pitfall | Impact | Prevention |
|---------|--------|------------|
| Missing `bg = "transparent"` | White boxes on slides | Always include in ggsave() |
| Hardcoded paths | Breaks on other machines | Use relative paths |

## 7. Line Length & Mathematical Exceptions

**Standard:** Keep lines <= 100 characters.

**Exception: Mathematical Formulas** -- lines may exceed 100 chars **if and only if:**

1. Breaking the line would harm readability of the math (influence functions, matrix ops, finite-difference approximations, formula implementations matching paper equations)
2. An inline comment explains the mathematical operation:
   ```r
   # Sieve projection: inner product of residuals onto basis functions P_k
   alpha_k <- sum(r_i * basis[, k]) / sum(basis[, k]^2)
   ```
3. The line is in a numerically intensive section (simulation loops, estimation routines, inference calculations)

**Quality Gate Impact:**
- Long lines in non-mathematical code: minor penalty (-1 to -2 per line)
- Long lines in documented mathematical sections: no penalty

## 8. Numerical Discipline

See [`r-reviewer.md`](../agents/r-reviewer.md) Category 11 ("Numerical Discipline") for the full checklist. Headline rules:

- **No float equality.** Never use `==` on doubles. Use `all.equal()` or `abs(a - b) < tol`.
- **CDF clamping** to an OPEN interval. Exact 0 or 1 passed to `qnorm()` / `pbinom()` etc. produces `±Inf`. Project-wide epsilon:

  ```r
  eps <- 1e-12
  p <- pmin(1 - eps, pmax(eps, p))   # now safe for qnorm(p)
  ```

- **Integer literals for counts.** `nrow <- 1000L` (not `1000`), `for (i in 1L:nL)` — avoids silent promotion.
- **Pre-allocate vectors** before loops (`numeric(n)`, `vector("list", n)`), never grow with `c()`.
- **Deterministic bootstrap seeding.** Set seed before the bootstrap, and if the bootstrap is nested, set per-replicate seeds as `seed_base + b`.
- **Explicit `na.rm = TRUE/FALSE`.** Never rely on defaults for `mean()`, `sd()`, `sum()` on data with potential NAs.
- **No `T` / `F`.** They're variables, not constants — write `TRUE` / `FALSE`.

## 9. Code Quality Checklist

```
[ ] Packages at top via library()
[ ] set.seed() once at top (YYYYMMDD)
[ ] All paths relative
[ ] Functions documented (Roxygen)
[ ] Figures: transparent bg, explicit dimensions
[ ] RDS: every computed object saved
[ ] Comments explain WHY not WHAT
[ ] Numerical discipline: no float ==, CDF clamping with eps, pre-allocated vectors
```

## 10. Spatial / Raster Standards (MCDWD Flood Pipeline)

### CRS discipline

- **All vector data must be in EPSG:5070** (NAD83 / Conus Albers) before any spatial join or zonal extraction.
- Check CRS at the top of every script that reads a spatial file:
  ```r
  stopifnot(sf::st_crs(my_sf) == sf::st_crs("EPSG:5070"))
  ```
- Never assume downloaded shapefiles or tigris outputs are in 5070 — always reproject explicitly with `sf::st_transform()` or `terra::project()`.
- Document the target CRS as a constant at the top of the script: `TARGET_CRS <- "EPSG:5070"`.

### Memory management for large rasters

- Never load more than **one date's raster** into memory at a time. A full CONUS MCDWD mosaic at 250m is ~1–2 GB in RAM.
- Use `terra::rast()` lazily — values are not read until explicitly requested.
- After each loop iteration: `rm(r, extracts); gc(verbose = FALSE)`.
- Wrap year-level processing in a function so local variables go out of scope and are GC'd between years.

### exactextractr — always prefer over terra::extract()

```r
# RIGHT — sub-pixel accurate, fast, handles partial pixels correctly
exactextractr::exact_extract(raster, polygons, fun = NULL, progress = FALSE)

# WRONG — ignores partial pixels, slower on large polygon sets
terra::extract(raster, polygons)
```

`exact_extract(fun = NULL)` returns a list of data.frames with columns `value` and `coverage_fraction`. Summarize per-polygon manually to apply custom flood-code logic.

### HDF / SDS reading

**MCDWD_L3 files are HDF4 format. System GDAL (Homebrew) and terra's bundled GDAL do NOT support HDF4.** Use the conda GDAL at `~/miniforge3/bin/gdal_translate` (install: `conda install -c conda-forge libgdal-hdf4`).

- HDF4 EOS grid structure:
  - Grid name: `Grid_Water_Composite`
  - SDS layer: `Flood_1Day_250m` (daily; also `Flood_2Day_250m`, `Flood_3Day_250m`)
  - Full GDAL path: `HDF4_EOS:EOS_GRID:"<file>":Grid_Water_Composite:Flood_1Day_250m`

- Conversion pattern (HDF4 → GeoTIFF → terra):
  ```r
  GDAL_TRANSLATE <- path.expand("~/miniforge3/bin/gdal_translate")
  sds <- sprintf('HDF4_EOS:EOS_GRID:"%s":Grid_Water_Composite:Flood_1Day_250m', hdf_path)
  system2(GDAL_TRANSLATE, args = c("-q", "-of", "GTiff", shQuote(sds), shQuote(tmp_tif)))
  r <- terra::rast(tmp_tif)
  r_proj <- terra::project(r, "EPSG:5070", method = "near")
  file.remove(tmp_tif)
  ```
- **`method = "near"` is mandatory** — MCDWD values are categorical flood codes (0–4), not continuous. Bilinear interpolation produces meaningless fractional codes.
- HDF4 magic bytes for file validation: `as.raw(c(0x0e, 0x03, 0x13, 0x01))` (first 4 bytes).

### MCDWD_L3 flood codes

| Code | Meaning | Count as valid? |
|---|---|---|
| 0 | No flood | Yes |
| 1 | Missing / outside swath | No |
| 2 | Cloud-obscured | No |
| 3 | Flood detected | Yes |
| 4 | Open water (permanent) | Yes |

`flood_fraction = sum(value == 3) / sum(value %in% c(0, 3, 4))` per polygon per date.

### Progress logging for long batch jobs

```r
message(sprintf("[%d/%d] %s — %.1fs", i, n, format(date), elapsed))
```

- Log year-level start/end time: `message(Sys.time(), " — year ", yr)`
- Save intermediate `.rds` checkpoints per year so the job is resumable after interruption.
- Use `furrr::future_map()` with `furrr_options(seed = TRUE)` for parallel date loops.
