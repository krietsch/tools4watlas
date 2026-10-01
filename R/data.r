#' Land polygon around the Dutch Wadden Sea
#'
#' @format sf object used for background layer in the function atl_create_bm()
#'
#' @source <https://www.openstreetmap.org>
"land"

#' Mudflats polygons within the Dutch Wadden Sea
#'
#' @format sf object used for background layer in the function atl_create_bm()
#'
#' @source <https://www.openstreetmap.org>
"mudflats"

#' Lake on Griend
#'
#' @format sf object used for background layer in the function atl_create_bm()
#'
#' @source <https://www.openstreetmap.org>
"lakes"

#' Grienderwaard
#'
#' @format sf object of the Grienderwaard
#'
#' @source Manually created based on openstreetmap data and -161 cm NAP polygon.
"grienderwaard"

#' Roosts around Griend
#'
#' @format sf object of the pre-roosts and roosts around Griend
#'
#' @source Buffered and smoothed around 60 cm NAP polygon.
"roosts_griend"


#' Data from two red knots and one redshank
#'
#' @format data.table of WATLAS data with tide data added
#'
#' @source WATLAS data example
"data_example"
