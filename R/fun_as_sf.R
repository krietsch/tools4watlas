#' Convert a data.frame or data.table to an simple feature (sf) object
#'
#' This function converts a data.frame or data.table to a simple feature (sf)
#' object, allowing flexible specification of the x and y coordinate columns.
#' Additional attributes can also be retained in the resulting sf object. There
#' are four options = c("points", "lines", "table", "res_patches").
#'
#' @author Johannes Krietsch
#' @param data A `data.table` or an object convertible to a `data.table`.
#'  The input data containing the coordinates and optional attributes.
#' @param tag A character string representing the  name of the column containing
#'  the tag ID.
#' @param x A character string representing the name of the column containing
#'  x-coordinates. Defaults to "x".
#' @param y A character string representing the name of the column containing
#'  y-coordinates. Defaults to "y".
#' @param projection An object of class `crs` representing the coordinate
#'  reference system (CRS) to assign to the resulting sf object. Defaults to
#'  EPSG:32631 (WGS 84 / UTM zone 31N).
#' @param additional_cols A character vector specifying additional column names
#'  to include in the resulting sf object. Defaults to `NULL` (no additional
#'  columns included).
#' @param option A character string with "points" (default) for returning sf
#'  points, "lines" to return sf lines and "table" to return a table with a sf
#' coordinates column or "res_patches" to return sf polygons with residency
#' patches. For the latter, it is best to specify the buffer around points to
#' half of \code{lim_spat_indep} of the residency patch calculation. If not
#' the function can create MULTIPOLGONS for single residency patches. That will
#' give a warning message, but works if desired.
#' @param buffer A numeric value (in meters) specifying the buffer around the
#' polygon of each residency patch. This should be set to half of
#' \code{lim_spat_indep} of the residency patch calculation. If not
#' the function can create MULTIPOLGONS for single residency patches. That will
#' give a warning message, but works if desired.
#' \code{lim_spat_indep} of the residency patch calculation.
#' @return An `sf` object containing the specified coordinates as geometry and
#'  any included attributes.
#' @import data.table
#' @examples
#' # packages
#' library(tools4watlas)
#' library(ggplot2)
#' library(mapview)
#'
#' # load example data
#' data <- data_example
#'
#' ### example "points" and "lines"
#'
#' # subset data one tag and tide
#' data_subset <- data[tag == "3063" & tideID == "2023513"]
#'
#' # make data spatial
#' d_sf <- atl_as_sf(
#'   data_subset,
#'   additional_cols = c("species", "datetime", "speed_in")
#' )
#'
#' # add track
#' d_sf_lines <- atl_as_sf(
#'   data_subset,
#'   additional_cols = c("species", "datetime", "speed_in"),
#'   option = "lines"
#' )
#'
#' # plot interactive map
#' mapview(d_sf_lines, zcol = "speed_in", legend = FALSE) +
#'   mapview(d_sf, zcol = "speed_in")
#'
#'
#' ### example "lines"
#'
#' ### example "table"
#'
#' # create sf table with spatial points
#' sf_table <- atl_as_sf(data, x = "x", y = "y", tag = "tag", option = "table")
#' sf_table
#'
#' ### example "res_patches"
#'
#' # calculate residence patches for one red knot
#' data <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 3, min_duration = 120
#' )
#'
#' # create polygons around residence patches
#' d_sf <- atl_as_sf(
#'   data,
#'   additional_cols = "patch",
#'   option = "res_patches", buffer = 75 / 2
#' )
#'
#' # summary of residence patches
#' data_summary <- atl_res_patch_summary(data)
#'
#' # create basemap
#' bm <- atl_create_bm(data, buffer = 500)
#'
#' # geom_sf overwrites coordinate system, so we need to set the limits again
#' bbox <- atl_bbox(data, buffer = 500)
#'
#' # plot polygons around residence patches
#' bm +
#'   # add patch polygons
#'   geom_sf(data = d_sf, aes(fill = as.character(patch)), alpha = 0.2) +
#'   # add track and points
#'   geom_path(
#'     data = data, aes(x, y),
#'     linewidth = 0.1, alpha = 0.5
#'   ) +
#'   geom_point(
#'     data = data[is.na(patch)], aes(x, y),
#'     size = 0.1, alpha = 0.5, color = "grey20",
#'     show.legend = FALSE
#'   ) +
#'   geom_point(
#'     data = data[!is.na(patch)], aes(x, y, color = as.character(patch)),
#'     size = 0.5, show.legend = FALSE
#'   ) +
#'   # set extend again (overwritten by geom_sf)
#'   coord_sf(
#'     xlim = c(bbox["xmin"], bbox["xmax"]),
#'     ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
#'   )
#' @export
atl_as_sf <- function(data,
                      tag = "tag",
                      x = "x",
                      y = "y",
                      projection = sf::st_crs(32631),
                      additional_cols = NULL,
                      option = "points",
                      buffer) {

  # Global variables to suppress notes in data.table
  tag_dummy <- patch <- geometry <- n <- NULL

  # Convert to data.table if not already
  if (!is.data.table(data)) {
    data <- data.table::setDT(data)
  }

  # Add so function also works without tag ID
  if (is.null(tag)) {
    tag <- "tag_dummy"
    data[, tag_dummy := "dummy"]
  }

  # Ensure x and y are character strings
  x_col <- as.character(x)
  y_col <- as.character(y)
  tag_col <- as.character(tag)
  tag_col_group <- rlang::ensym(tag)

  # Check if columns exist in the data
  if (!(x_col %in% names(data)) || !(y_col %in% names(data))) {
    stop("Specified x or y columns do not exist in the data.", call. = FALSE)
  }
  if (!(tag_col %in% names(data)) || is.null(tag)) {
    stop("Specified tag column do not exist in the data.", call. = FALSE)
  }

  # Additional check for 'res_patches' option
  if (option == "res_patches") {
    if (!"patch" %in% names(data)) {
      stop("Option 'res_patches' requires a 'patch' column in the data.",
        call. = FALSE
      )
    }
    if (missing(buffer) || is.null(buffer)) {
      stop("Option 'res_patches' requires a specified 'buffer' value.",
        call. = FALSE
      )
    }
  }

  # Include additional columns if specified
  if (!is.null(additional_cols)) {
    # Ensure all specified additional columns exist in the data
    missing_cols <- setdiff(additional_cols, names(data))
    if (length(missing_cols) > 0) {
      stop(paste(
        "The following additional columns are missing in the data:",
        paste(missing_cols, collapse = ", ")
      ), call. = FALSE)
    }
    # Select x, y, and additional columns
    cols_to_keep <- unique(c(tag_col, x_col, y_col, additional_cols))
  } else {
    # Default to only x and y columns
    cols_to_keep <- c(tag_col, x_col, y_col)
  }

  # If "res_patches" option, include 'patch'
  if (option == "res_patches" && !"patch" %in% cols_to_keep) {
    cols_to_keep <- c(cols_to_keep, "patch")
  }

  # Exclude rows where x or y are NA
  data_subset <- data[!is.na(get(x_col)) & !is.na(get(y_col)),
    cols_to_keep,
    with = FALSE
  ]

  # Convert to sf object
  d_sf <- sf::st_as_sf(
    data_subset,
    coords = c(x_col, y_col),
    crs = projection
  )

  # Switch for different return options
  return_data <- switch(option,
    points = {
      # Return sf with points
      d_sf
    },
    lines = {
      # Return sf with lines
      d_sf |>
        dplyr::group_by(!!tag_col_group) |>
        dplyr::summarise(
          do_union = FALSE,
          dplyr::across(dplyr::all_of(additional_cols), first)
        ) |>
        sf::st_cast("LINESTRING")
    },
    table = {
      # Return data.table with coordinates as column
      data.table::data.table(d_sf)
    },
    res_patches = {
      # first buffer points (faster than buffering lines)
      d_patches <- d_sf |>
        dplyr::filter(!is.na(patch)) |>
        dplyr::group_by(tag, patch) |>
        dplyr::reframe(geometry = sf::st_buffer(geometry, dist = buffer)) |>
        dplyr::group_by(tag, patch) |>
        dplyr::summarise(
          geometry = sf::st_union(geometry), .groups = "drop"
        ) |>
        sf::st_as_sf()

      # identify multipolygons
      is_multi <- sf::st_geometry_type(d_patches) == "MULTIPOLYGON"

      # redo buffer for multipolygons using line approach
      if (any(is_multi)) {
        d_patches[is_multi, ] <- d_sf |>
          dplyr::filter(!is.na(patch)) |>
          dplyr::semi_join(
            d_patches[is_multi, ] |> sf::st_drop_geometry(),
            by = c("tag", "patch")
          ) |>
          dplyr::distinct(tag, patch, geometry) |>
          dplyr::group_by(tag, patch) |>
          dplyr::summarise(
            n = dplyr::n(),
            geometry = sf::st_combine(geometry),
            .groups = "drop"
          ) |>
          dplyr::mutate(
            geometry = purrr::map2(geometry, n, \(geom, n) {
              if (n > 1) geom <- sf::st_cast(geom, "LINESTRING")
              sf::st_buffer(geom, dist = buffer)
            }) |> sf::st_sfc(crs = sf::st_crs(d_sf))
          ) |>
          dplyr::select(-n)
      }

      d_patches
    },
    stop("Invalid option", call. = FALSE)
  )

  # Delete dummy tag column again
  if (tag == "tag_dummy") {
    data[, tag_dummy := NULL]
  }

  return_data
}
