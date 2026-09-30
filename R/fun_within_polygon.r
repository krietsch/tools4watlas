#' Detect position intersections with a polygon
#'
#' @description Detects which positions intersect a polygon sf object.
#'
#' @author Johannes Krietsch
#' @param data A `data.table` or similar containing at least x and
#' y coordinates.
#' @param x The name of the x coordinate, default "x".
#' @param y The name of the y coordinate, default "y".
#' @param polygon An `sf` polygon object with a EPSG:32631 (UTM zone 31N) as
#' CRS.
#' @param col_name The name of the output column added to `data`. Defaults
#' to the name of the polygon object passed in.
#'
#' @return The original `data` with an added logical column indicating
#' whether each position intersects the polygon.
#'
#' @examples
#' # packages
#' library(tools4watlas)
#' library(sf)
#' library(ggplot2)
#'
#' # load example data
#' data <- data_example
#'
#' # assign positions within the polygon of Grienderwaard
#' data <- atl_within_polygon(
#'   data, polygon = grienderwaard, col_name = "on_grienderwaard"
#' )
#'
#' # new bounding box using Grienderwaard for plot
#' bbox <- atl_bbox(grienderwaard, buffer = 1500)
#'
#' # create a base map for background
#' bm <- atl_create_bm(bbox)
#'
#' # plot points on and out of Grienderwaard
#' bm +
#'   geom_path(
#'     data = data, aes(x, y, colour = on_grienderwaard),
#'     linewidth = 0.5, alpha = 0.1, show.legend = TRUE
#'   ) +
#'   geom_point(
#'     data = data, aes(x, y, colour = on_grienderwaard),
#'     size = 0.5, alpha = 1, show.legend = TRUE
#'   ) +
#'   scale_color_discrete() +
#'   theme(legend.position = "top") +
#'   # add Grienderwaard polygon
#'   geom_sf(data = grienderwaard, color = "firebrick", fill = NA) +
#'   # set extend again (overwritten by geom_sf)
#'   coord_sf(
#'     xlim = c(bbox["xmin"], bbox["xmax"]),
#'     ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
#'   )
#' @export
atl_within_polygon <- function(data,
                               x = "x",
                               y = "y",
                               polygon,
                               col_name = deparse(substitute(polygon))) {
  # check inputs
  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "atl_within_polygon: input not a dataframe object!"
  )
  assertthat::assert_that(
    inherits(polygon, "sf") || inherits(polygon, "sfc"),
    msg = "atl_within_polygon: polygon is not class sf or sfc"
  )
  assertthat::assert_that(
    any(stringr::str_detect(sf::st_geometry_type(polygon), "(POLYGON)")),
    msg = "atl_within_polygon: polygon geometry is not *POLYGON"
  )
  assertthat::assert_that(
    !is.na(sf::st_crs(polygon)),
    msg = "atl_within_polygon: polygon has no CRS"
  )
  assertthat::assert_that(
    sf::st_crs(polygon) == sf::st_crs(32631),
    msg = "atl_within_polygon: polygon CRS is not EPSG:32631 (UTM zone 31N)"
  )

  # pre-filter by bounding box for speed
  bbox <- sf::st_bbox(polygon)
  in_bbox <- data.table::between(data[[x]], bbox["xmin"], bbox["xmax"]) &
    data.table::between(data[[y]], bbox["ymin"], bbox["ymax"])
  rows <- which(in_bbox)

  # convert bbox-filtered subset to sf and check intersection
  data_sf <- sf::st_as_sf(
    data[rows, .SD, .SDcols = c(x, y)],
    coords = c(x, y),
    crs = sf::st_crs(polygon)
  )
  in_polygon <- apply(
    sf::st_intersects(data_sf, polygon, sparse = FALSE), 1, any
  )

  # add result column to original data
  # (FALSE by default, TRUE where intersecting)
  data[, (col_name) := FALSE]
  data[rows[in_polygon], (col_name) := TRUE]

  data
}
