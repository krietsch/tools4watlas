#' Add raster data to tracking data
#'
#' This function extracts raster data (for example bathymetry data) at specified
#' coordinates and adds it as a column to the input data.table.
#'
#' @param data A `data.table` containing the data to which raster values will
#'   be added. If not a `data.table`, it will be coerced to one.
#' @param x Character string specifying the column name for x-coordinates.
#'   Defaults to `"x"`.
#' @param y Character string specifying the column name for y-coordinates.
#'   Defaults to `"y"`.
#' @param projection A coordinate reference system (CRS) for the spatial data
#'   in the input. Defaults to EPSG:32631.
#' @param raster_data A `SpatRaster` object from which values will be extracted.
#' @param var_name Character string specifying the raster variable to extract.
#'   Defaults to the first layer if `NULL`.
#' @param new_name Character string specifying the name of the new column in the
#'   output. If `NULL`, uses `var_name`.
#' @param change_unit Numeric value by which to multiply extracted raster values
#' #'   before adding them to the data. Defaults to `1`.
#'
#' @examples
#' library(terra)
#'
#' # example data: subset one tag
#' data_subset <- data_example[tag == "3027"]
#' 
#' # made-up bathymetry raster (cm) covering the data, 20 m resolution,
#' # with a west-east gradient from -200 to 200
#' bat <- rast(
#'   xmin = floor(min(data_subset$x)) - 100,
#'   xmax = ceiling(max(data_subset$x)) + 100,
#'   ymin = floor(min(data_subset$y)) - 100,
#'   ymax = ceiling(max(data_subset$y)) + 100,
#'   resolution = 20, crs = "EPSG:32631"
#' )
#' xs <- xFromCell(bat, seq_len(ncell(bat)))
#' values(bat) <- (xs - min(xs)) / (max(xs) - min(xs)) * 400 - 200
#' names(bat) <- "bathymetry"
#' 
#' # add raster values to the data (first raster layer by default)
#' data_subset <- atl_add_raster_data(data_subset, raster_data = bat)
#' head(data_subset[, .(tag, x, y, bathymetry)])
#' 
#' # choose the layer, name the new column and convert units (cm to m)
#' data_subset <- atl_add_raster_data(
#'   data_subset,
#'   raster_data = bat, var_name = "bathymetry",
#'   new_name = "bathymetry_m", change_unit = 0.01
#' )
#' head(data_subset[, .(tag, x, y, bathymetry, bathymetry_m)])
#'
#' @return A `data.table` with the extracted raster data added as a new column.
#' @export
atl_add_raster_data <- function(data = NULL,
                                x = "x",
                                y = "y",
                                projection = sf::st_crs(32631),
                                raster_data,
                                var_name = NULL,
                                new_name = NULL,
                                change_unit = 1) {
  # Convert to data.table if not already
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }

  # Check if columns exist in the data
  if (!(x %in% names(data)) || !(y %in% names(data))) {
    stop("Specified x or y columns do not exist in the data.", call. = FALSE)
  }

  # Check if any NA
  if (anyNA(data[[x]]) || anyNA(data[[y]])) {
    stop("Specified x or y columns contain NA, but should not.", call. = FALSE)
  }

  # Check that raster data are SpatRaster
  if (!inherits(raster_data, "SpatRaster")) {
    stop("Specified raster_data are not terra SpatRaster, but should be.",
      call. = FALSE
    )
  }

  # Convert data to sf object
  d_sf <- atl_as_sf(data, tag = NULL, x, y, projection = projection)

  # Check if raster_data have same projection as data
  data_crs <- sf::st_crs(d_sf, parameters = TRUE)
  raster_crs <- terra::crs(raster_data, describe = TRUE)
  assertthat::assert_that(
    data_crs$epsg == raster_crs$code,
    msg = paste(
      "The coordinate reference systems (CRS) do not match.",
      "sf object EPSG:", data_crs$epsg,
      "SpatRaster EPSG:", raster_crs$code,
      ". Please change raster data to EPSG:", data_crs$epsg
    )
  )

  # Extract raster data
  data_extract <- terra::extract(raster_data, d_sf) |> data.table::data.table()

  # If var_name = NULL use first name in raster
  if (is.null(var_name)) {
    var_name <- names(raster_data)[1]
  }

  # Add raster data to data.table
  if (is.null(new_name)) {
    data[, (var_name) := data_extract[, get(var_name)] * change_unit]
  } else {
    data[, (new_name) := data_extract[, get(var_name)] * change_unit]
  }

  data
}
