#' Interpolate tracking data
#'
#' This function interpolates gaps in the tracking data within a set time
#' interval (`interp_interval`) and within defined temporal and spatial
#' restrictions. Coordinates in gaps are filled with a simple linear
#' interpolation using `zoo::na.approx()`. One is required to specify the
#' maximum time gap (`max_gap`) between positions that will be interpolated
#' and can additionally specify a maximum distance between positions
#' (`max_dist`) to restrict interpolation to more local movements.
#' If `patches_only = TRUE`, interpolation is further restricted to only gaps
#' within residence patches.
#'
#' Best to use with already thinned data (e.g. with `atl_thin_data()`) to avoid
#' unnecessary interpolation of very fine-scale data and to speed up processing.
#'
#' @author Johannes Krietsch
#' @param data A `data.frame` or `data.table` containing tracking data.
#' @param tag Character. Name of the column containing tag or individual IDs.
#'   Defaults to `"tag"`.
#' @param x Character. Name of the column containing x coordinates.
#'   Defaults to `"x"`.
#' @param y Character. Name of the column containing y coordinates.
#'   Defaults to `"y"`.
#' @param time Character. Name of the column containing UNIX timestamps
#'   (numeric, in seconds). Defaults to `"time"`.
#' @param patch Character. Name of the column containing residence patch IDs.
#'   Defaults to `"patch"`. Only used when `patches_only = TRUE`.
#' @param interp_interval Numeric. The time interval in seconds to interpolate
#'   to. Defaults to `60`.
#' @param max_gap Numeric. Maximum gap in seconds between two observed positions
#'   for which interpolation is performed. Gaps larger than this value will not
#'   be interpolated. Defaults to `NULL`.
#' @param max_dist Numeric or `NULL`. Maximum distance in coordinate units
#'   between two observed positions for which interpolation is performed. If
#'   `NULL` (default), no distance filter is applied.
#' @param patches_only Logical. If `TRUE` (default), interpolation is
#'   restricted to gaps within the same patch ID. Requires the column specified
#'   in `patch` to be present in `data`.
#' @param quietly If `TRUE` returns percentage and number of positions filtered,
#' if `FALSE` functions runs quietly
#'
#' @return A `data.table` with the same columns as the input, plus `datetime`
#'   (POSIXct timestamp in UTC), `gap_next` (time in seconds to the next
#'   observed position), `interpolated` (logical, `TRUE` for interpolated
#'   rows), and optionally `dist_next` (distance to the next observed position,
#'   if `max_dist` is set). Rows are ordered by tag and time.
#'
#' @examples
#' # packages
#' library(tools4watlas)
#' library(ggplot2)
#'
#' # load example data of one red knot
#' data <- data_example[tag == "3038"]
#'
#' # calculate residence patches
#' data <- atl_res_patch(
#'   data,
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 3, min_duration = 120
#' )
#'
#' # thin dataa to 1 min intervall
#' data <- atl_thin_data(
#'   data = data,
#'   interval = 60,
#'   id_columns = c("tag", "species"),
#'   method = "aggregate"
#' )
#'
#' # interpolate data within residence patches
#' data_int <- atl_interpolate_track(
#'   data = data,
#'   tag = "tag",
#'   x = "x",
#'   y = "y",
#'   time = "time",
#'   patch = "patch",
#'   interp_interval = 60,
#'   max_gap = 3600 * 8,
#'   max_dist = NULL,
#'   patches_only = TRUE
#' )
#'
#' # check data
#' head(data_int)
#'
#' ### plot data to check results
#' # create basemap
#' bm <- atl_create_bm(data_int, buffer = 800)
#'
#' # plot points and tracks with standard ggplot colours
#' bm +
#'   geom_path(
#'     data = data_int, aes(x, y),
#'     linewidth = 0.5, alpha = 0.1, show.legend = FALSE
#'   ) +
#'   geom_point(
#'     data = data_int, aes(x, y, colour = patch),
#'     size = 1, alpha = 1, show.legend = FALSE
#'   ) +
#'   geom_point(
#'     data = data_int[interpolated == TRUE], aes(x, y), color = "black",
#'     size = 0.5, alpha = 1, show.legend = FALSE
#'   )
#'
#' @export
atl_interpolate_track <- function(data,
                                  tag = "tag",
                                  x = "x",
                                  y = "y",
                                  time = "time",
                                  patch = "patch",
                                  interp_interval = 60,
                                  max_gap = NULL,
                                  max_dist = NULL,
                                  patches_only = TRUE,
                                  quietly = FALSE) {
  # global variables
  N <- gap_next <- time_ <- tag_ <- x_ <- y_ <- . <- NULL # nolint
  interpolated <- patch_ <- datetime <- dist_next <- NULL

  # convert to data.table if not already
  if (!is.data.table(data)) {
    data <- data.table::setDT(data)
  }

  # ensure x and y are character strings
  x_col <- as.character(x)
  y_col <- as.character(y)
  tag_col <- as.character(tag)
  t_col   <- as.character(time)
  patch_col <- as.character(patch)

  # check columns exist
  if (!all(c(x_col, y_col, tag_col, t_col) %in% names(data))) {
    missing_cols <- setdiff(c(x_col, y_col, tag_col, t_col), names(data))
    stop(sprintf(
      "Column(s) not found in data: %s", paste(missing_cols, collapse = ", ")
    ))
  }
  if (patches_only == TRUE) {
    if (!patch_col %in% names(data)) {
      stop(sprintf(
        "patches_only = TRUE but column '%s' not found in data.", patch_col
      ))
    }
  }

  assertthat::assert_that(
    is.numeric(max_gap) && length(max_gap) == 1,
    msg = paste0(
      "atl_interpolate_track: max_gap must be a single ",
      "numeric value in seconds."
    )
  )

  # check: skip tags with fewer than 2 rows
  tag_counts <- data[, .N, by = tag_col, env = list(tag_col = tag_col)]
  skipped <- tag_counts[N < 2, get(tag_col)]
  if (length(skipped) > 0) {
    warning(sprintf(
      "The following tags have fewer than 2 rows and will be skipped: %s",
      paste(skipped, collapse = ", ")
    ))
    data <- data[!data[[tag_col]] %in% skipped]
  }
  if (nrow(data) == 0) {
    warning("No tags with sufficient data to interpolate.")
    return(data)
  }

  # copy to avoid col name issues
  cols_to_copy <- c(tag_col, t_col, x_col, y_col)
  new_names    <- c("tag_", "time_", "x_", "y_")

  if (patches_only == TRUE) {
    cols_to_copy <- c(cols_to_copy, patch_col)
    new_names    <- c(new_names, "patch_")
  }

  d <- data[, .SD, .SDcols = cols_to_copy]
  setnames(d, new_names)

  # calculate gaps in data
  d[, gap_next := c(0, diff(time_)), by = tag_]

  # calculate distance between points
  if (!is.null(max_dist)) {
    d[, dist_next := c(0, sqrt(diff(x_)^2 + diff(y_)^2)), by = tag_]
  }

  # build full regular time grid per tag
  grid <- d[, .(
    time_ = seq(min(time_), max(time_), by = interp_interval)
  ), by = tag_]

  # merge with real data
  d <- merge(
    grid, d,
    by = c("tag_", "time_"),
    all = TRUE
  )

  # assign real and interpolated rows
  d[, interpolated := is.na(x_)]

  # ensure ordered correctly
  setorder(d, tag_, time_)

  # fill NA values by tag_ with next non NA
  d[, gap_next := nafill(gap_next, type = "nocb"), by = tag_]

  # fill patch ID's when NA in-between (if patches_only = TRUE)
  # and remove rows without patch ID's
  if (patches_only == TRUE) {
    d[, patch_ := {
      fwd <- zoo::na.locf(patch_, na.rm = FALSE)
      bwd <- zoo::na.locf(patch_, fromLast = TRUE, na.rm = FALSE)
      ifelse(is.na(patch_) & fwd == bwd, fwd, patch_)
    }, by = tag_]

    # remove rows without patch ID's
    d <- d[!(interpolated == TRUE & is.na(patch_))]
  }

  # remove rows where gap_next is larger than max_gap
  d <- d[!(interpolated == TRUE & gap_next > max_gap)]

  # if max_dist is set, remove rows where distance is larger than max_dist
  if (!is.null(max_dist)) {
    d[, dist_next := nafill(dist_next, type = "nocb"), by = tag_]
    d <- d[!(interpolated == TRUE & dist_next > max_dist)]
  }

  # interpolate coordinates
  d[, x_ := zoo::na.approx(x_, time_, rule = 2), by = tag_]
  d[, y_ := zoo::na.approx(y_, time_, rule = 2), by = tag_]

  # add datetime in UTC
  d[, datetime := as.POSIXct(time_, origin = "1970-01-01", tz = "UTC")]

  # restore original column names
  new_names <- c(
    tag_col, t_col, x_col, y_col, patch_col,
    "gap_next", "dist_next", "interpolated", "datetime"
  )
  if (patches_only == FALSE) {
    new_names <- setdiff(new_names, patch_col)
  }
  if (is.null(max_dist)) {
    new_names <- setdiff(new_names, "dist_next")
  }
  setnames(d, new_names)
  setcolorder(
    d, c(
      names(d)[1:2], "datetime",
      setdiff(names(d)[-(1:2)], "datetime")
    )
  )
  setorderv(d, c(tag_col, t_col))

  # how much was interpolated?
  nrow_before <- nrow(data)
  nrow_after <- nrow(d)
  nrows_added <- nrow_after - nrow_before
  percentage_increase <- (nrows_added / nrow_before) * 100
  percentage_increase <- round(percentage_increase, 2)

  if (nrow(d) > 0 && quietly == FALSE) {
    message(glue::glue(
      "Note: Interpolation added {nrows_added} positions ",
      "({percentage_increase}% increase)."
    ), call. = FALSE)
  }

  # return interpolated data
  d
}
