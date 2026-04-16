# Create a bounding box with specified aspect ratio and buffer

This function generates a bounding box for a given geometry with a
specified aspect ratio. Additionally, it allows applying a buffer to
expand or contract the bounding box.

## Usage

``` r
atl_bbox(data, x = "x", y = "y", asp = "16:9", buffer = 0)
```

## Arguments

- data:

  An `sf` or `sfc` object for which the bounding box is calculated or a
  data.table with x- and y- coordinates.

- x:

  A character string representing the name of the column containing
  x-coordinates. Defaults to "x".

- y:

  A character string representing the name of the column containing
  y-coordinates. Defaults to "y".

- asp:

  A character string specifying the desired aspect ratio in the format
  `"width:height"`. Default is `"16:9"`, if `NULL` returns simple
  bounding box without modifying aspect ratio.

- buffer:

  A numeric value (in meters) specifying the buffer distance to be
  applied to the bounding box. Positive values expand the bounding box,
  while negative values shrink it. Default is `0`.

## Value

A bounding box (`bbox`), represented as a named vector with `xmin`,
`ymin`, `xmax`, and `ymax` values.

## Author

Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)
library(ggplot2)
library(sf)
#> Warning: package 'sf' was built under R version 4.5.3
#> Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

# load example data
data <- data_example

# bounding box based on data
bbox <- atl_bbox(data, buffer = 1000)

# bounding box based on specified coordinates in EPSG:4326
bbox <- data.table(x = c(5.107, 5.330), y = c(53.303, 53.230)) |>
  st_as_sf(coords = c("x", "y"), crs = 4326) |>
  st_transform(crs = 32631) |>
  atl_bbox(buffer = 1000)

# bounding box based on polygon
bbox <- atl_bbox(grienderwaard, buffer = 1000)

# create basemap with bounding box
bm <- atl_create_bm(bbox)

# plot bm with bounding box when bm coordinates are overridden by geom_sf
bm +
  geom_sf(data = grienderwaard, fill = "transparent", color = "firebrick") +
  # set extend again (overwritten by geom_sf)
  coord_sf(
    xlim = c(bbox["xmin"], bbox["xmax"]),
    ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
  )
#> Coordinate system already present.
#> ℹ Adding new coordinate system, which will replace the existing one.
```
