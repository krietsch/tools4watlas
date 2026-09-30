#' Filter data by position covariates
#'
#' The atlastools function `atl_filter_covariates` allows convenient
#' filtering of a dataset by any number of logical filters.
#' This function can be used to easily filter timestamps in a range, as well as
#' combine simple spatial and temporal filters.
#' It accepts a character vector of `R` expressions that each return a
#' logical vector (i.e. `TRUE` or `FALSE`).
#' Each filtering condition is interpreted in the context of the dataset
#' supplied, and used to filter for rows that satisfy each of the filter
#' conditions.
#' Users must make sure that the filtering variables exist in their dataset in
#' order to avoid errors.
#'
#' Derived from `atlastools::atl_filter_covariates()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik R. Gupte and Johannes Krietsch
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data A `data.table` or similar containing the variables to be
#' filtered.
#' @param filters A character vector of filter expressions. An example might be
#' \code{"speed < 20"}. The filtering variables must be in the `data.table`.
#' The function will not explicitly check whether the filtering variables are
#' present; this makes it flexible, allowing expressions such as
#' \code{"between(speed, 2, 20)"}, but also something to use at your own risk.
#' A missing filter variables \emph{will} result in an empty data frame.
#' @param quietly If `TRUE` returns percentage and number of positions filtered,
#' if `FALSE` functions runs quietly
#'
#' @return A dataframe filtered using the filters specified.
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # filter data at night
#' # extract hour of the day
#' data[, hour := as.integer(format(datetime, "%H"))]
#'
#' night_data <- atl_filter_covariates(
#'   data = data,
#'   filters = c("!inrange(hour, 6, 18)")
#' )
#'
#' # filter on the variance of the estimated x- and y-coordinates
#' var_max <- 5000 # in meters squared
#'
#' data_filtered <- atl_filter_covariates(
#'   data = data,
#'   filters = c(
#'     sprintf("varx < %s", var_max),
#'     sprintf("vary < %s", var_max)
#'   )
#' )
#'
#' # filter by speed
#' speed_max <- 35 # m/s (126 km/h)
#'
#' data <- atl_filter_covariates(
#'   data = data,
#'   filters = c(
#'     sprintf("speed_in < %s | is.na(speed_in)", speed_max),
#'     sprintf("speed_out < %s | is.na(speed_out)", speed_max)
#'   )
#' )
#' @export
atl_filter_covariates <- function(data,
                                  filters = c(),
                                  quietly = FALSE) {
  # convert to data.table
  if (!is.data.table(data)) {
    data.table::setDT(data)
  }

  # nrows of data
  nrow_before <- nrow(data)

  # apply filters as a single evaluated parsed expression
  # first wrap them in brackets
  filters <- vapply(
    X = filters,
    FUN = function(this_filter) {
      sprintf("(%s)", this_filter)
    },
    FUN.VALUE = "character"
  )
  filters <- stringr::str_c(filters, collapse = " & ")
  filters <- parse(text = filters)
  # evaluate the parsed filters
  data <- data[eval(filters), ]

  # check for class and whether there are rows
  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "filter_covariates: cleaned data is not a dataframe object!"
  )

  # print warning if all rows are removed
  if (nrow(data) == 0) {
    warning("filter_covariates: cleaned data has no rows remaining!",
      call. = FALSE
    )
  }

  # how much was filtered?
  nrow_after <- nrow(data)
  nrows_filtered <- nrow_before - nrow_after
  percentage_decrease <- (nrows_filtered / nrow_before) * 100
  percentage_decrease <- round(percentage_decrease, 2)

  if (nrow(data) > 0 && quietly == FALSE) {
    message(glue::glue(
      "Note: {percentage_decrease}% of the dataset was filtered out, ",
      "corresponding to {nrows_filtered} positions."
    ))
  }

  data
}
