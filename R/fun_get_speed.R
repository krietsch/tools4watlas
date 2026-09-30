#' Calculate instantaneous speed
#'
#' Returns additional columns for incoming and outcoming speed to the
#' data.table. Speed in metres per time interval. The time interval is dependent
#' on the units of the column specified in \code{time}.
#'
#' Derived from `atlastools::atl_get_speed()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik R. Gupte, Allert Bijleveld & Johannes Krietsch
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data A dataframe or similar which must have the columns
#' specified by \code{x}, \code{y}, and \code{time}.
#' @param tag The tag ID.
#' @param x The x coordinate.
#' @param y The y coordinate.
#' @param time The timestamp in seconds since the UNIX epoch.
#' @param type The type of speed (incoming or outgoing) to return.
#' Incoming speeds are specified by \code{type = "in"}, and outgoing speeds
#' by \code{type = "out"} or both c("in", "out").
#'
#' @return Data.table changed in place with additional speed columns
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # remove speed columns
#' data[, c("speed_in", "speed_out") := NULL]
#'
#' # calculate speed
#' data <- atl_get_speed(data,
#'                       tag = "tag",
#'                       x = "x",
#'                       y = "y",
#'                       time = "time",
#'                       type = c("in", "out")
#' )
#'
#' # check data
#' data[, .(tag, datetime, x, y, speed_in, speed_out)]
#' @export
atl_get_speed <- function(data,
                          tag = "tag",
                          x = "x",
                          y = "y",
                          time = "time",
                          type = c("in", "out")) {
  # global variables
  distance <- time_diff <- speed_in <- speed_out <- NULL

  # Convert to data.table if not already
  if (!is.data.table(data)) {
    data <- data.table::setDT(data)
  }

  # check names expected
  atl_check_data(data, names_expected = c(tag, x, y, time))

  # Dynamic column names
  x_col <- as.character(substitute(x))
  y_col <- as.character(substitute(y))
  time_col <- as.character(substitute(time))

  # set order in time
  data.table::setorderv(data, c(tag, time))

  # get distance
  data[, distance := atl_simple_dist(
    .SD,
    x = x_col, y = y_col, lag = 1
  ),
  by = c(tag)
  ]

  # get time
  data[, time_diff := c(NA, diff(get(time_col))), by = c(tag)]

  if ("in" %in% type) {
    data[, speed_in := distance / time_diff, by = c(tag)]
  }
  if ("out" %in% type) {
    data[, speed_out := data.table::shift(distance, type = "lead") /
           data.table::shift(time_diff, type = "lead")]
  }

  # remove unwanted columns
  data[, c("distance", "time_diff") := NULL]

  data
}
