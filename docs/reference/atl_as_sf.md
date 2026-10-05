# Convert a data.frame or data.table to an simple feature (sf) object

This function converts a data.frame or data.table to a simple feature
(sf) object, allowing flexible specification of the x and y coordinate
columns. Additional attributes can also be retained in the resulting sf
object. There are four options = c("points", "lines", "table",
"res_patches").

## Usage

``` r
atl_as_sf(
  data,
  tag = "tag",
  x = "x",
  y = "y",
  projection = sf::st_crs(32631),
  additional_cols = NULL,
  option = "points",
  buffer
)
```

## Arguments

- data:

  A `data.table` or an object convertible to a `data.table`. The input
  data containing the coordinates and optional attributes.

- tag:

  A character string representing the name of the column containing the
  tag ID.

- x:

  A character string representing the name of the column containing
  x-coordinates. Defaults to "x".

- y:

  A character string representing the name of the column containing
  y-coordinates. Defaults to "y".

- projection:

  An object of class `crs` representing the coordinate reference system
  (CRS) to assign to the resulting sf object. Defaults to EPSG:32631
  (WGS 84 / UTM zone 31N).

- additional_cols:

  A character vector specifying additional column names to include in
  the resulting sf object. Defaults to `NULL` (no additional columns
  included).

- option:

  A character string with "points" (default) for returning sf points,
  "lines" to return sf lines and "table" to return a table with a sf
  coordinates column or "res_patches" to return sf polygons with
  residency patches. For the latter, it is best to specify the buffer
  around points to half of `lim_spat_indep` of the residency patch
  calculation. If not the function can create MULTIPOLYGONS for single
  residency patches. That will give a warning message, but works if
  desired.

- buffer:

  A numeric value (in meters) specifying the buffer around the polygon
  of each residency patch. This should be set to half of
  `lim_spat_indep` of the residency patch calculation. If not the
  function can create MULTIPOLYGONS for single residency patches. That
  will give a warning message, but works if desired. `lim_spat_indep` of
  the residency patch calculation.

## Value

An `sf` object containing the specified coordinates as geometry and any
included attributes.

## Author

Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)
library(ggplot2)

# load example data
data <- data_example

# example POINTS and LINES

# subset data one tag and tide
data_subset <- data[tag == "3063" & tideID == "2023513"]

# make data spatial
d_sf <- atl_as_sf(
  data_subset,
  additional_cols = c("species", "datetime", "speed_in")
)

# add track
d_sf_lines <- atl_as_sf(
  data_subset,
  additional_cols = c("species", "datetime", "speed_in"),
  option = "lines"
)

# plot interactive map (only if mapview is installed)
if (requireNamespace("mapview", quietly = TRUE)) {
  mapview::mapview(d_sf_lines, zcol = "speed_in", legend = FALSE) +
    mapview::mapview(d_sf, zcol = "speed_in")
}

# example TABLE

# create sf table with spatial points
sf_table <- atl_as_sf(data, x = "x", y = "y", tag = "tag", option = "table")
sf_table
#>           tag                 geometry
#>        <char>              <sfc_POINT>
#>     1:   3027 POINT (650705.6 5902556)
#>     2:   3027 POINT (650705.6 5902556)
#>     3:   3027   POINT (650721 5902559)
#>     4:   3027 POINT (650721.1 5902559)
#>     5:   3027 POINT (650723.1 5902564)
#>    ---                                
#> 84411:   3288 POINT (650178.5 5902404)
#> 84412:   3288 POINT (650178.5 5902404)
#> 84413:   3288 POINT (650178.5 5902404)
#> 84414:   3288 POINT (650178.2 5902403)
#> 84415:   3288 POINT (650177.5 5902403)

# example RES_PATCHES

# calculate residence patches for one red knot
data <- atl_res_patch(
  data_subset,
  max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
  min_fixes = 3, min_duration = 120
)

# create polygons around residence patches
d_sf <- atl_as_sf(
  data,
  additional_cols = "patch",
  option = "res_patches", buffer = 75 / 2
)

# summary of residence patches
data_summary <- atl_res_patch_summary(data)

# create basemap
bm <- atl_create_bm(data, buffer = 500)

# geom_sf overwrites coordinate system, so we need to set the limits again
bbox <- atl_bbox(data, buffer = 500)

# plot polygons around residence patches
bm +
  # add patch polygons
  geom_sf(data = d_sf, aes(fill = as.character(patch)), alpha = 0.2) +
  # add track and points
  geom_path(
    data = data, aes(x, y),
    linewidth = 0.1, alpha = 0.5
  ) +
  geom_point(
    data = data[is.na(patch)], aes(x, y),
    size = 0.1, alpha = 0.5, color = "grey20",
    show.legend = FALSE
  ) +
  geom_point(
    data = data[!is.na(patch)], aes(x, y, color = as.character(patch)),
    size = 0.5, show.legend = FALSE
  ) +
  # set extend again (overwritten by geom_sf)
  coord_sf(
    xlim = c(bbox["xmin"], bbox["xmax"]),
    ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
  )
#> Coordinate system already present.
#> ℹ Adding new coordinate system, which will replace the existing one.
```
