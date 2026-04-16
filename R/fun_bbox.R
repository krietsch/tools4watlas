#' Create a bounding box with specified aspect ratio and buffer
#'
#' This function generates a bounding box for a given geometry with a
#' specified aspect ratio. Additionally, it allows applying a buffer to
#' expand or contract the bounding box.
#'
#' @author Johannes Krietsch
#' @param data An `sf` or `sfc` object for which the bounding box is
#' calculated or a data.table with x- and y- coordinates.
#' @param x A character string representing the name of the column containing
#'  x-coordinates. Defaults to "x".
#' @param y A character string representing the name of the column containing
#'  y-coordinates. Defaults to "y".
#' @param asp A character string specifying the desired aspect ratio in the
#' format `"width:height"`. Default is `"16:9"`, if `NULL` returns simple
#' bounding box without modifying aspect ratio.
#' @param buffer A numeric value (in meters) specifying the buffer distance to
#' be applied to the bounding box. Positive values expand the bounding box,
#' while negative values shrink it. Default is `0`.
#'
#' @return A bounding box (`bbox`), represented as a named vector with
#' `xmin`, `ymin`, `xmax`, and `ymax` values.
#'
#' @export
#'
#' @examples
#' # packages
#' library(tools4watlas)
#' library(ggplot2)
#' library(sf)
#'
#' # load example data
#' data <- data_example
#'
#' # bounding box based on data
#' bbox <- atl_bbox(data, buffer = 1000)
#'
#' # bounding box based on specified coordinates in EPSG:4326
#' bbox <- data.table(x = c(5.107, 5.330), y = c(53.303, 53.230)) |>
#'   st_as_sf(coords = c("x", "y"), crs = 4326) |>
#'   st_transform(crs = 32631) |>
#'   atl_bbox(buffer = 1000)
#'
#' # bounding box based on polygon
#' bbox <- atl_bbox(grienderwaard, buffer = 1000)
#'
#' # create basemap with bounding box
#' bm <- atl_create_bm(bbox)
#'
#' # plot bm with bounding box when bm coordinates are overridden by geom_sf
#' bm +
#'   geom_sf(data = grienderwaard, fill = "transparent", color = "firebrick") +
#'   # set extend again (overwritten by geom_sf)
#'   coord_sf(
#'     xlim = c(bbox["xmin"], bbox["xmax"]),
#'     ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
#'   )
atl_bbox <- function(data,
                     x = "x",
                     y = "y",
                     asp = "16:9",
                     buffer = 0) {
  # Check input
  if (!is.null(asp)) {
    assertthat::assert_that(
      stringr::str_detect(asp, ":"),
      length(as.numeric(unlist(strsplit(asp, ":")))) == 2,
      msg = "Aspect ratio must be in the format 'width:height'."
    )
  }

  if (inherits(data, c("sf", "sfc"))) {
    if (nrow(sf::st_coordinates(data)) == 1) {
      assertthat::assert_that(
        buffer > 0,
        msg = "Buffer must be >0 if geometry is a single point"
      )
    }
  } else {
    if (nrow(data) == 1) {
      assertthat::assert_that(
        buffer > 0,
        msg = "Buffer must be >0 if geometry is a single point"
      )
    }
  }

  # Extract the original bounding box
  if (inherits(data, c("sf", "sfc"))) {
    bbox <- sf::st_bbox(data)
  } else {
    # check if required columns are present
    names_req <- c(x, y)
    atl_check_data(data, names_req)
    bbox <- sf::st_bbox(c(
      xmin = min(data[[x]], na.rm = TRUE),
      ymin = min(data[[y]], na.rm = TRUE),
      xmax = max(data[[x]], na.rm = TRUE),
      ymax = max(data[[y]], na.rm = TRUE)
    ))
  }

  # Apply the buffer to the bbox
  if (buffer != 0) {
    bbox <- sf::st_as_sfc(bbox) |> sf::st_buffer(dist = buffer) |> sf::st_bbox()
  }

  # If asp is NULL, return the bbox without modifying aspect ratio
  if (is.null(asp)) {
    return(bbox)
  }

  # Parse the aspect ratio
  ratio <- as.numeric(unlist(strsplit(asp, ":")))

  # Extract range
  x_range <- bbox["xmax"] - bbox["xmin"]
  y_range <- bbox["ymax"] - bbox["ymin"]

  # Compute the desired width and height based on the aspect ratio
  desired_aspect <- ratio[1] / ratio[2]
  current_aspect <- x_range / y_range

  if (current_aspect > desired_aspect) {
    # Wider than desired aspect ratio, adjust y-range
    new_y_range <- x_range / desired_aspect
    delta_y <- (new_y_range - y_range) / 2
    bbox["ymin"] <- bbox["ymin"] - delta_y
    bbox["ymax"] <- bbox["ymax"] + delta_y
  } else {
    # Taller than desired aspect ratio, adjust x-range
    new_x_range <- y_range * desired_aspect
    delta_x <- (new_x_range - x_range) / 2
    bbox["xmin"] <- bbox["xmin"] - delta_x
    bbox["xmax"] <- bbox["xmax"] + delta_x
  }

  # Return the adjusted bounding box
  bbox
}
