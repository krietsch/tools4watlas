#' Create a basemap with customised bounding box using package stored data
#'
#' This function creates a basemap using spatial data layers, allowing for
#' custom bounding boxes, aspect ratios, and scale bar adjustments.
#'
#' @author Johannes Krietsch
#' @param data A `data.table` or an object convertible to `data.table`
#' containing spatial points or a `sf` bounding box.
#' Defaults to a single point around Griend if `NULL`.
#' @param x A character string specifying the column with x-coordinates.
#'   Defaults to `"x"`.
#' @param y A character string specifying the column with y-coordinates.
#'   Defaults to `"y"`.
#' @param buffer A numeric value (in meters) specifying the buffer distance for
#' the bounding box. Default is `1000`.
#' @param asp A character string specifying the desired aspect ratio in the
#' format `"width:height"`. Default is `"16:9"`, if `NULL` returns simple
#' bounding box without modifying aspect ratio.
#' @param option Either "osm" for OpenStreetMap polygons or "bathymetry" for
#' bathymetry data. Note that for the later it is necessary to provide the
#' bathymetry data in UTM31.
#' @param land_data An `sf` object for land polygons. Defaults to `land`.
#' @param mudflats_data An `sf` object for mudflat polygons. Defaults to
#'   `mudflats`.
#' @param lakes_data An `sf` object for lake polygons. Defaults to `lakes`.
#' @param raster_data An `SpatRaster` (tif opened with `terra::rast()` of
#' bathymetry data.
#' @param shade If TRUE a shade will be added to the bathymetry data. (This
#' can take a while for large maps)
#' @param scalebar TRUE or FALSE for adding a scalebar to the plot.
#' @param sc_location A character string specifying the location of the scale
#'   bar. Default is `"br"` (bottom right).
#' @param sc_cex Numeric value for the scale bar text size. Default is `0.7`.
#' @param sc_height A unit object specifying the height of the scale bar.
#' Default is `unit(0.25, "cm")`.
#' @param sc_pad_x A unit object specifying horizontal padding for the scale
#' bar. Default is `unit(0.25, "cm")`.
#' @param sc_pad_y A unit object specifying vertical padding for the scale bar.
#'   Default is `unit(0.5, "cm")`.
#' @param projection The coordinate reference system (CRS) for the spatial data.
#'   Defaults to EPSG:32631 (WGS 84 / UTM zone 31N). Output is always UTM 31N
#' @param water_fill Water fill (default "#D7E7FF")
#' @param water_colour Water colour (default "grey80")
#' @param land_fill Land fill (default "#faf5ef")
#' @param land_colour Land colour (default "grey80")
#' @param mudflat_colour Mudflat colour (default "#faf5ef")
#' @param mudflat_fill Mudflat fill (default "#faf5ef")
#' @param mudflat_alpha Mudflat alpha (default 0.6)
#'
#' @return A `ggplot2` object representing the base map with the specified
#'   settings.
#' @import ggplot2
#' @import ggspatial
#' @export
#'
#' @examples
#' # Example with default settings (map around Griend)
#' bm <- atl_create_bm(buffer = 5000)
#' print(bm)
atl_create_bm <- function(data = NULL,
                          x = "x",
                          y = "y",
                          buffer = 100,
                          asp = "16:9",
                          option = "osm",
                          land_data = tools4watlas::land,
                          mudflats_data = tools4watlas::mudflats,
                          lakes_data = tools4watlas::lakes,
                          raster_data,
                          shade = FALSE,
                          scalebar = TRUE,
                          sc_location = "br",
                          sc_cex = 1,
                          sc_height = 0.3,
                          sc_pad_x = 0.4,
                          sc_pad_y = 0.6,
                          projection = sf::st_crs(32631),
                          water_fill = "#D7E7FF",
                          water_colour = "grey80",
                          land_fill = "#faf5ef",
                          land_colour = "grey80",
                          mudflat_colour = "#faf5ef",
                          mudflat_fill = "#faf5ef",
                          mudflat_alpha = 0.6) {
  # global variables
  hs_45_225 <- NULL

  # check if valid option
  if (!option %in% c("osm", "bathymetry")) {
    stop("Error: The option must be either 'osm' or 'bathymetry'.")
  }

  # if bounding box make it a table
  if (inherits(data, "bbox") &&
        all(c("xmin", "ymin", "xmax", "ymax") %in% names(data))) {
    data <- data.table::data.table(
      x = c(data["xmin"], data["xmax"], data["xmax"], data["xmin"]),
      y = c(data["ymin"], data["ymin"], data["ymax"], data["ymax"])
    )
  }

  # make buffere around Griend when no data provided
  if (is.null(data) || nrow(data) == 0) {
    # If no data make map around Griend
    data <- data.table::data.table(tag = 1, x = 650272.5, y = 5902705)
  }

  # Convert to data.table if not already
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }

  # check if required columns are present
  names_req <- c(x, y)
  atl_check_data(data, names_req)

  # Create bounding box
  if (projection == sf::st_crs(32631)) {
    bbox <- atl_bbox(data, x = x, y = y, asp = asp, buffer = buffer)
  } else {
    # Create sf and change projection if data were not UTM31
    d_sf <- atl_as_sf(data, tag = NULL, x = x, y = y, projection = projection)
    d_sf <- sf::st_transform(d_sf, crs = sf::st_crs(32631))
    bbox <- atl_bbox(d_sf, x = x, y = y, asp = asp, buffer = buffer)
  }

  if (option == "bathymetry") {
    # crop bathymetry data
    raster_data_c <- terra::crop(raster_data, bbox)
    # discrete steps in color scale to highlight mudflats
    x <- c(
      -50,
      seq(-6, -30, -4),
      seq(-2, -6, -1),
      seq(0, -2, -0.05),
      seq(0, 2, 0.05),
      seq(2, 6, 1),
      45
    ) |> unique()
    x <- sort(x)
    # classify in categories
    raster_data_class <- terra::classify(
      raster_data_c, x, include.lowest = TRUE, brackets = TRUE
    )
    # custom made scale
    cc <- scales::pal_div_gradient(
      "#567e9f", "#e4ccb6", "#fdf2f3", "Lab"
    )(seq(0, 1, length.out = length(x)))
    # variable name
    var_name <- names(raster_data)[1]
  }

  if (option == "bathymetry" && shade == TRUE) {
    alt <- terra::disagg(raster_data_c, 10, method = "bilinear")
    slope <- terra::terrain(alt, "slope", unit = "radians")
    aspect <- terra::terrain(alt, "aspect", unit = "radians")
    h <- terra::shade(
      slope, aspect,
      angle = c(45, 45, 45, 80),
      direction = c(225, 270, 315, 135)
    )
    h <- Reduce(mean, h)
    # extract values to be able to get the median value
    hv <- terra::values(h)
  }

  # create base map
  bm <- ggplot()
  # define layers conditionally
  if (option == "osm") {
    layers <- list(
      geom_sf(
        data = mudflats_data, fill = mudflat_fill, alpha = mudflat_alpha,
        colour = mudflat_colour
      ),
      geom_sf(data = land_data, fill = land_fill, colour = land_colour),
      geom_sf(data = lakes_data, fill = water_fill, colour = water_colour)
    )
  } else {
    layers <- list(
      tidyterra::geom_spatraster(
        data = raster_data_class, aes(fill = !!sym(var_name)),
        show.legend = FALSE
      ),
      geom_sf(data = land_data, fill = "transparent", colour = "grey60"),
      scale_fill_manual(values = cc, na.value = "#fdf2f3")
    )
  }
  # add layers
  bm <- bm + layers

  # add shading if TRUE
  if (option == "bathymetry" && shade == TRUE) {
    bm <- bm +
      ggnewscale::new_scale_fill() +
      tidyterra::geom_spatraster(
        data = h,
        aes(fill = hs_45_225),
        show.legend = FALSE
      ) +
      geom_sf(data = land_data, fill = "transparent", colour = "grey60") +
      scale_fill_gradient2(
        low = "dodgerblue4", mid = "transparent", high = "lightblue",
        midpoint = stats::median(hv, na.rm = TRUE), na.value = "#fdf2f3"
      )
  }

  # add scalbar if TRUE
  if (scalebar == TRUE) {
    bm <- bm +
      ggspatial::annotation_scale(
        aes(location = "br"),
        text_cex = sc_cex,
        height = unit(sc_height, "cm"),
        pad_x = unit(sc_pad_x, "cm"),
        pad_y = unit(sc_pad_y, "cm")
      )
  }

  # add plot modifications
  bm <- bm +
    # Crop to bounding box
    coord_sf(
      xlim = c(bbox["xmin"], bbox["xmax"]),
      ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
    ) +
    # Clean up layout
    theme(
      panel.grid.major = element_line(colour = "transparent"),
      panel.grid.minor = element_line(colour = "transparent"),
      panel.background = element_rect(fill = water_fill),
      plot.background = element_rect(fill = "transparent", colour = NA),
      panel.border = element_rect(fill = NA, colour = "grey20"),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title = element_blank(),
      plot.margin = unit(c(0, 0, -0.2, -0.2), "lines")
    )

  bm
}
