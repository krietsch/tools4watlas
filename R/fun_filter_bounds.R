#' Filter positions by an area
#'
#' Filters out positions lying inside or outside an area.
#' The area can be defined in two ways, either by its x- and y-coordinate
#' ranges, or by an \code{sf-POLYGON} object.
#' \code{MULTIPOLYGON} objects are supported by the internal function
#' \code{atl_within_polygon}.
#'
#' Derived from `atlastools::atl_filter_bounds()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik R. Gupte and Johannes Krietsch
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data A `data.table` or extension which contains x- and y-coordinates.
#' @param x The x coordinate column.
#' @param y The y coordinate column.
#' @param x_range The range of x coordinates.
#' @param y_range The range of y coordinates.
#' @param sf_polygon \code{sfc_POLYGON} object which must have a defined CRS.
#' The polygon CRS is assumed to be appropriate for the positions as well, and
#' is assigned to the coordinates when determining the intersection.
#' @param remove_inside Whether to remove points from within the range.
#' Setting \code{negate = TRUE} removes positions within the bounding
#' box specified by the x- and y-ranges.
#'
#'
#' @return A `data.table` of tracking locations with attractor points removed.
#' @examples
#' # packages
#' library(tools4watlas)
#' library(sf)
#' library(ggplot2)
#'
#' # load example data
#' data <- data_example
#'
#' # create basemap
#' bm <- atl_create_bm(data, buffer = 800)
#'
#' # create a bounding box to filter data
#' griend_east <- st_sfc(st_point(c(5.275, 53.2523)), crs = st_crs(4326)) |>
#'   st_transform(crs = st_crs(32631))
#'
#' # define bbox to crop data
#' bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
#' bbox_sf <- st_as_sfc(bbox_crop) # just for plotting as sf object
#'
#' # geom_sf overwrites coordinate system, so we need to set the limits again
#' bbox <- atl_bbox(data, buffer = 800)
#'
#' # plot points and tracks with standard ggplot colours
#' bm +
#'   geom_path(
#'     data = data, aes(x, y, colour = tag),
#'     linewidth = 0.5, alpha = 0.1, show.legend = TRUE
#'   ) +
#'   geom_point(
#'     data = data, aes(x, y, colour = tag),
#'     size = 0.5, alpha = 1, show.legend = TRUE
#'   ) +
#'   geom_sf(data = bbox_sf, color = "firebrick", fill = NA) +
#'   scale_color_discrete(name = paste("N = ", length(unique(data$tag)))) +
#'   theme(legend.position = "top") +
#'   # set extend again (overwritten by geom_sf)
#'   coord_sf(
#'     xlim = c(bbox["xmin"], bbox["xmax"]),
#'     ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
#'   )
#'
#' # filter data with bounding box
#' # note: when filtering with a rectangle bounding box
#' # and large datasets, using th range is faster than sf_polygon
#' data_filtered <- atl_filter_bounds(
#'   data = data,
#'   x = "x",
#'   y = "y",
#'   x_range = c(bbox_crop["xmin"], bbox_crop["xmax"]),
#'   y_range = c(bbox_crop["ymin"], bbox_crop["ymax"]),
#'   remove_inside = FALSE
#' )
#'
#' # plot cropped data
#' bm +
#'   geom_path(
#'     data = data_filtered, aes(x, y, colour = tag),
#'     linewidth = 0.5, alpha = 0.1, show.legend = TRUE
#'   ) +
#'   geom_point(
#'     data = data_filtered, aes(x, y, colour = tag),
#'     size = 0.5, alpha = 1, show.legend = TRUE
#'   ) +
#'   geom_sf(data = bbox_sf, color = "firebrick", fill = NA) +
#'   scale_color_discrete(name = paste("N = ", length(unique(data$tag)))) +
#'   theme(legend.position = "top") +
#'   # set extend again (overwritten by geom_sf)
#'   coord_sf(
#'     xlim = c(bbox["xmin"], bbox["xmax"]),
#'     ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
#'   )
#' @export
atl_filter_bounds <- function(data,
                              x = "x",
                              y = "y",
                              x_range = NA,
                              y_range = NA,
                              sf_polygon = NULL,
                              remove_inside = TRUE) {
  # Global variables to suppress notes in data.table
  ".in_polygon" <- NULL

  # check input type
  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "filter_bbox: input not a dataframe object!"
  )
  assertthat::assert_that(
    is.logical(remove_inside),
    msg = "filter_bbox: remove inside needs TRUE/FALSE"
  )

  # include asserts checking for required columns
  names_req <- c(x, y)
  atl_check_data(data, names_req)

  # check for x_range or y_range or polygon
  # why NA? because between returns true for paired NA
  assertthat::assert_that(any(
    !is.null(sf_polygon),
    !is.na(x_range), !is.na(y_range)
  ))

  # make input list of bound limits
  bounds <- list(x_range = x_range, y_range = y_range)
  # remove NA ie unsupplied limits
  bounds[vapply(bounds, anyNA, logical(1))] <- NULL

  # check input length of attractors
  invisible(lapply(bounds, function(f) {
    assertthat::assert_that(
      length(f) == 2,
      msg = "filter_bbox: incorrect bound lengths"
    )
  }))

  was_df <- FALSE
  # convert to data.table
  if (!is.data.table(data)) {
    data.table::setDT(data)
    was_df <- TRUE
  }

  # filter for spatial extent either inside or outside
  if (remove_inside) {
    # KEEPS DATA OUTSIDE THE BOUNDING BOX OR OUTSIDE THE POLYGON
    if (!is.null(sf_polygon)) {
      # polygon provided: ignore bbox, filter only by polygon
      data_ <- atl_within_polygon(
        data = data,
        x = x, y = y,
        polygon = sf_polygon,
        col_name = ".in_polygon"
      )
      data_ <- data_[(.in_polygon) == FALSE]
      data_[, .in_polygon := NULL]
    } else {
      # no polygon: filter by bbox only
      outside_bbox <- !(data.table::between(
        data[[x]], x_range[1], x_range[2],
        NAbounds = TRUE
      ) &
        data.table::between(
          data[[y]], y_range[1], y_range[2], NAbounds = TRUE
        ))
      data_ <- data[outside_bbox, ]
    }
  } else {
    # KEEPS DATA INSIDE THE BOUNDING BOX AND POLYGON
    keep <- data.table::between(data[[x]], x_range[1], x_range[2],
      NAbounds = TRUE
    ) &
      data.table::between(data[[y]], y_range[1], y_range[2],
        NAbounds = TRUE
      )

    # filter by bbox
    data_ <- data[keep, ]

    # filter to KEEP those inside polygon
    if (!is.null(sf_polygon)) {
      data_ <- atl_within_polygon(
        data = data_,
        x = x, y = y,
        polygon = sf_polygon,
        col_name = ".in_polygon"
      )
      data_ <- data_[(.in_polygon) == TRUE]
      data_[, .in_polygon := NULL]
    }
  }

  # reconvert original data to data.frame
  if (was_df) {
    data.table::setDF(data)
    assertthat::assert_that(!is.data.table(data))
  }

  assertthat::assert_that(
    inherits(data_, "data.frame"),
    msg = "filter_bbox: cleaned data is not a data.frame or data.table object!"
  )

  # print warning if all rows are removed
  if (nrow(data_) == 0) {
    warning("filter_bbox: cleaned data has no rows remaining!", call. = FALSE)
  }

  data_
}
