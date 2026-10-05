# Add raster data to tracking data

This function extracts raster data (for example bathymetry data) at
specified coordinates and adds it as a column to the input data.table.

## Usage

``` r
atl_add_raster_data(
  data = NULL,
  x = "x",
  y = "y",
  projection = sf::st_crs(32631),
  raster_data,
  var_name = NULL,
  new_name = NULL,
  change_unit = 1
)
```

## Arguments

- data:

  A `data.table` containing the data to which raster values will be
  added. If not a `data.table`, it will be coerced to one.

- x:

  Character string specifying the column name for x-coordinates.
  Defaults to `"x"`.

- y:

  Character string specifying the column name for y-coordinates.
  Defaults to `"y"`.

- projection:

  A coordinate reference system (CRS) for the spatial data in the input.
  Defaults to EPSG:32631.

- raster_data:

  A `SpatRaster` object from which values will be extracted.

- var_name:

  Character string specifying the raster variable to extract. Defaults
  to the first layer if `NULL`.

- new_name:

  Character string specifying the name of the new column in the output.
  If `NULL`, uses `var_name`.

- change_unit:

  Numeric value by which to multiply extracted raster values \#' before
  adding them to the data. Defaults to `1`.

## Value

A `data.table` with the extracted raster data added as a new column.

## Examples

``` r
library(terra)
#> terra 1.9.50
#> 
#> Attaching package: 'terra'
#> The following object is masked from 'package:data.table':
#> 
#>     shift

# example data: subset one tag
data_subset <- data_example[tag == "3027"]

# made-up bathymetry raster (cm) covering the data, 20 m resolution,
# with a west-east gradient from -200 to 200
bat <- rast(
  xmin = floor(min(data_subset$x)) - 100,
  xmax = ceiling(max(data_subset$x)) + 100,
  ymin = floor(min(data_subset$y)) - 100,
  ymax = ceiling(max(data_subset$y)) + 100,
  resolution = 20, crs = "EPSG:32631"
)
xs <- xFromCell(bat, seq_len(ncell(bat)))
values(bat) <- (xs - min(xs)) / (max(xs) - min(xs)) * 400 - 200
names(bat) <- "bathymetry"

# add raster values to the data (first raster layer by default)
data_subset <- atl_add_raster_data(data_subset, raster_data = bat)
head(data_subset[, .(tag, x, y, bathymetry)])
#>       tag        x       y bathymetry
#>    <char>    <num>   <num>      <num>
#> 1:   3027 650705.6 5902556   160.1732
#> 2:   3027 650705.6 5902556   160.1732
#> 3:   3027 650721.0 5902559   161.9048
#> 4:   3027 650721.1 5902559   161.9048
#> 5:   3027 650723.1 5902564   161.9048
#> 6:   3027 650723.1 5902564   161.9048

# choose the layer, name the new column and convert units (cm to m)
data_subset <- atl_add_raster_data(
  data_subset,
  raster_data = bat, var_name = "bathymetry",
  new_name = "bathymetry_m", change_unit = 0.01
)
head(data_subset[, .(tag, x, y, bathymetry, bathymetry_m)])
#>       tag        x       y bathymetry bathymetry_m
#>    <char>    <num>   <num>      <num>        <num>
#> 1:   3027 650705.6 5902556   160.1732     1.601732
#> 2:   3027 650705.6 5902556   160.1732     1.601732
#> 3:   3027 650721.0 5902559   161.9048     1.619048
#> 4:   3027 650721.1 5902559   161.9048     1.619048
#> 5:   3027 650723.1 5902564   161.9048     1.619048
#> 6:   3027 650723.1 5902564   161.9048     1.619048
```
