#' Apply a median smooth to coordinates
#'
#' Applies a median smooth defined by a rolling window to the x and y
#' coordinates of the data, by tag ID
#'
#' Derived from `atlastools::atl_median_smooth()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik Gupte & Allert Bijleveld & Johannes Krietsch
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data A data.frame or data.table object returned by
#' \code{atl_get_data}, which should contain the original columns
#' (particularly tag, x, y, and time).
#' @param moving_window The size of the moving window for the median smooth.
#' Must be an odd number.
#' @param tag The tag ID.
#' @param x The X coordinate.
#' @param y The Y coordinate.
#' @param time The timestamp, ideally as an integer.
#' @return A data.table class object (extends data.frame), including X,Y as
#' smoothed coordinates and the x_raw and y_raw, which are the raw coordinates.
#'
#' @examples
#' library(tools4watlas)
#' library(data.table)
#' library(ggplot2)
#'
#' # Example dataset
#' # tag 1
#' data1 <- data.table(
#'   tag = rep(1, 10),
#'   x = c(1, 2, 5, 6, 8, 10, 12, 14, 17, 21),
#'   y = c(1, 7, 8, 12, 13, 20, 16, 18, 20, 21),
#'   time = 1:10
#' )
#'
#' # tag 2
#' data2 <- data.table(
#'   tag = rep(2, 10),
#'   x = c(2, 3, 6, 7, 9, 11, 13, 15, 18, 26),
#'   y = c(2, 6, 7, 11, 12, 19, 15, 17, 19, 20),
#'   time = 1:10
#' )
#'
#' # Combine both datasets
#' data <- rbind(data1, data2)
#' setorder(data, tag, time)
#'
#' # Run the function
#' smoothed_data <- atl_median_smooth(data, moving_window = 5)
#'
#' ggplot() +
#'   geom_path(
#'     data = smoothed_data, aes(x_raw, y_raw),
#'     color = "firebrick3", linewidth = 0.5
#'   ) +
#'   geom_path(
#'     data = smoothed_data, aes(x, y),
#'     color = "black", linewidth = 0.5
#'   ) +
#'   geom_point(
#'     data = smoothed_data, aes(x_raw, y_raw),
#'     color = "firebrick3", size = 1.2
#'   ) +
#'   geom_point(
#'     data = smoothed_data, aes(x, y),
#'     color = "black", size = 1
#'   ) +
#'   theme_bw() +
#'   facet_wrap(~tag)
#' @export
#'
atl_median_smooth <- function(data,
                              tag = "tag",
                              x = "x",
                              y = "y",
                              time = "time",
                              moving_window = 5) {
  # global variables
  x_raw <- y_raw <- NULL

  # check parameter types and assumptions
  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "cleanData: not a dataframe object!"
  )

  # check the data
  names_req <- c(tag, x, y, time)
  atl_check_data(data, names_req)

  # check args positive
  assertthat::assert_that(min(c(moving_window)) > 1,
    msg = "cleanData: moving window not > 1"
  )
  assertthat::assert_that(moving_window %% 2 != 0,
    msg = "moving window must be an odd number"
  )

  # convert both to DT if not
  if (data.table::is.data.table(data) != TRUE) {
    data.table::setDT(data)
  }

  # set in ascending order of tag and time
  data.table::setorder(data, tag, time)

  # add original coordinates
  data[, x_raw := x]
  data[, y_raw := y]

  # mutate in place
  data[, c(x, y) := lapply(
    .SD,
    function(z) {
      rev(stats::runmed(
        rev(stats::runmed(z, moving_window)),
        moving_window
      ))
    }
  ),
  .SDcols = c(x, y),
  by = tag]

  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "median_smooth: cleanded data is not a dataframe object!"
  )

  if (nrow(data) > 0) {
    data
  } else {
    warning("median_smooth: no data remaining", call. = FALSE)
    NULL
  }
}
