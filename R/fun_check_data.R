#' Check data has required columns
#'
#' An internal function that checks that the data.table has the required
#' columns.
#'
#' Derived from `atlastools::atl_check_data()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik R. Gupte
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data The tracking data to check for required columns. Must be in the
#' form of a `data.frame` or `data.table`, which can be handled by the function
#' colnames.
#' @param names_expected The names expected as a character vector.
#' By default, checks for the column names \code{x, y, time}.
#' @examples
#' # basic (and only) use
#' \dontrun{
#' atl_check_data(
#'   data = data,
#'   names_expected = c("x", "y", "time")
#' )
#' }
#'
#' @return None. Breaks if the data does not have required columns.
#' @noRd
atl_check_data <- function(data,
                           names_expected = c("x", "y", "time")) {
  # get the column names
  data_names <- colnames(data)

  invisible(
    vapply(names_expected, function(nr) {
      assertthat::assert_that(
        nr %in% data_names,
        msg = glue::glue("atl_check_data: {nr} is required but
                         missing from data!")
      )
    }, FUN.VALUE = TRUE)
  )
}
