# Create a basemap with customised bounding box using map tiles

This function creates a basemap using spatial data layers, allowing for
custom bounding boxes, aspect ratios, and scale bar adjustments.

## Usage

``` r
atl_create_bm_tiles(
  data = NULL,
  x = "x",
  y = "y",
  buffer = 100,
  asp = "16:9",
  option = "Esri.WorldImagery",
  zoom = 15,
  scalebar = TRUE,
  sc_location = "br",
  sc_cex = 1,
  sc_height = 0.3,
  sc_pad_x = 0.4,
  sc_pad_y = 0.6,
  projection = sf::st_crs(32631)
)
```

## Arguments

- data:

  A `data.table` or an object convertible to `data.table` containing
  spatial points or a `sf` bounding box. Defaults to a single point
  around Griend if `NULL`.

- x:

  A character string specifying the column with x-coordinates. Defaults
  to `"x"`.

- y:

  A character string specifying the column with y-coordinates. Defaults
  to `"y"`.

- buffer:

  A numeric value (in meters) specifying the buffer distance for the
  bounding box. Default is `1000`.

- asp:

  A character string specifying the desired aspect ratio in the format
  `"width:height"`. Default is `"16:9"`, if `NULL` returns simple
  bounding box without modifying aspect ratio.

- option:

  A character string specifying the map tile provider. Options include
  `"Esri.WorldImagery"`, `""OpenStreetMap"`, `"Esri"`, `"CARTO"`, and
  `"Thunderforest"`. See supported by the `maptiles` package, see:

- zoom:

  Numeric value specifying the zoom level for the map tiles. Zoom levels
  are described in the OpenStreetMap wiki:
  https://wiki.openstreetmap.org/wiki/Zoom_levels.

- scalebar:

  TRUE or FALSE for adding a scalebar to the plot.

- sc_location:

  A character string specifying the location of the scale bar. Default
  is `"br"` (bottom right).

- sc_cex:

  Numeric value for the scale bar text size. Default is `0.7`.

- sc_height:

  A unit object specifying the height of the scale bar. Default is
  `unit(0.25, "cm")`.

- sc_pad_x:

  A unit object specifying horizontal padding for the scale bar. Default
  is `unit(0.25, "cm")`.

- sc_pad_y:

  A unit object specifying vertical padding for the scale bar. Default
  is `unit(0.5, "cm")`.

- projection:

  The coordinate reference system (CRS) for the spatial data. Defaults
  to EPSG:32631 (WGS 84 / UTM zone 31N). Output is always EPSG:4326.
  Bounding box calculation is much faster when using EPSG:3263, so use
  it like this whenever possible and then only plot the movement tracks
  in EPSG:4326 on the map.

## Value

A `ggplot2` object representing the base map with the specified
settings.

## Author

Johannes Krietsch

## Examples

``` r
# packages
library(ggplot2)

# example with open street map
bm <- atl_create_bm_tiles(
  buffer = 15000, option = "OpenStreetMap", zoom = 12
)
print(bm)


# example with satellite map
bm <- atl_create_bm_tiles(
  buffer = 15000, option = "Esri.WorldImagery", zoom = 12
)
print(bm)


# example with bbox from data and movement data
data <- data_example

# add transformed coordinates in projection of the base map (EPSG:4326)
data <- atl_transform_dt(data)

# plot points and tracks using transformed coordinates.
bm +
  geom_path(
    data = data, aes(x_4326, y_4326, colour = tag),
    linewidth = 0.5, alpha = 0.1, show.legend = FALSE
  ) +
  geom_point(
    data = data, aes(x_4326, y_4326, colour = tag),
    size = 0.5, alpha = 1, show.legend = FALSE
  ) +
  scale_color_discrete(name = paste("N = ", length(unique(data$tag)))) +
  theme(legend.position = "top")

```
