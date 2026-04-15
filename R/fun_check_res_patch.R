#' Check the residence patches from one tag during one tide
#'
#' Generates a `ggplot2` showing bird residence patches per tideID, including
#' movement paths, patch durations, and an inset overview map.
#'
#' @author Johannes Krietsch
#' @param data A `data.table` containing tracking data of one tag. Must include
#' the columns: `tag`, `x`, `y`, `time`,`datetime`, and `species` and
#'   `patch`,  as created by `atl_res_patch()`.
#' @param tide_data Data on the timing (in UTC) of low and high tides.
#' @param tide_data_highres Data on the timing (in UTC) of the waterlevel in
#' small intervals (e.g. every 10 min) as provided from Rijkwaterstaat.
#' @param tide Tide ID to subset.
#' @param offset The offset in minutes between the location of the tidal gauge
#' and the tracking area. This value will be added to the timing of the
#' water data.
#' @param waterlevel_min Numeric in cmNAP. Minimum water level to fix the axis,
#' if NA (default) it uses the minimum of the provided water level data.
#' water level to the duration range (default: NA, which uses the minimum of
#' the provided water level data).
#' @param waterlevel_max Numeric in cmNAP. Maximum water level to fix the axis,
#' if NA (default) it uses the minimum of the provided water level data.
#' @param waterlevel_line Numeric in cmNAP. The water level to add as a dotted
#' line to the plot (default: 60 cmNAP).
#' @param buffer_res_patches A numeric value (in meters) specifying the buffer
#' around the polygon of each residence patch. If set to half of
#' \code{lim_spat_indep} of the residence patch calculation it reflects the
#' distance used to determine spatial independence of patches.
#' @param buffer_bm Map buffer size (default: 250).
#' @param buffer_overview Overview map buffer size (default: 10000).
#' @param point_size Size of plotted points (default: 1).
#' @param point_alpha Transparency of points (default: 0.5).
#' @param path_linewidth Line width of movement paths (default: 0.5).
#' @param path_alpha Transparency of movement paths (default: 0.2).
#' @param patch_label_size Font size for patch labels (default: 4).
#' @param patch_label_padding Padding for patch labels (default: 1).
#' @param element_text_size Font size for axis and legend text (default: 11).
#' @param water_fill Water fill (default "#D7E7FF")
#' @param water_colour Water coulour (default "grey80")
#' @param land_fill Land fill (default "#faf5ef")
#' @param land_colour Land colour (default "grey80")
#' @param mudflat_colour Mudflat colour (default "#faf5ef")
#' @param mudflat_fill Mudflat fill (default "#faf5ef")
#' @param mudflat_alpha Mudflat alpha (default 0.6)
#' @param roosts Logical. Whether to add the roost polygon around Griend or not
#' (default: FALSE).
#' @param filename Character (or NULL). If provided, the plot is saved as a
#'   `.png` file to this path and with this name; otherwise, the function
#'   returns the plot.
#' @param png_width Width of saved PNG (default: 3840).
#' @param png_height Height of saved PNG (default: 2160).
#'
#' @return A ggplot object or a saved PNG file.
#' @import patchwork
#' @importFrom ggtext element_markdown
#' @importFrom ragg agg_png
#' @importFrom grDevices dev.off
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # load example tide pattern and waterlevel data
#' tidal_pattern_fp <- system.file(
#'   "extdata", "example-tidalPattern-west_terschelling-UTC.csv",
#'   package = "tools4watlas"
#' )
#' measured_water_height_fp <- system.file(
#'   "extdata", "example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv",
#'   package = "tools4watlas"
#' )
#' tidal_pattern <- fread(tidal_pattern_fp, yaml = TRUE)
#' measured_water_height <- fread(measured_water_height_fp)
#'
#' # calculate residence patches for one red knot
#' data <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 3, min_duration = 120
#' )
#'
#' # plot example
#' atl_check_res_patch(
#'   data[tag == "3038"],
#'   tide_data = tidal_pattern, tide_data_highres = measured_water_height,
#'   tide = "2023513", offset = 30,
#'   buffer_res_patches = 75 / 2
#' )
#' @export
atl_check_res_patch <- function(data,
                                tide_data,
                                tide_data_highres,
                                tide,
                                offset = 0,
                                waterlevel_min = -150,
                                waterlevel_max = 150,
                                waterlevel_line = 60,
                                buffer_res_patches,
                                buffer_bm = 250,
                                buffer_overview = 10000,
                                point_size = 1,
                                point_alpha = 0.5,
                                path_linewidth = 0.5,
                                path_alpha = 0.2,
                                patch_label_size = 4,
                                patch_label_padding = 1,
                                element_text_size = 11,
                                water_fill = "#D7E7FF",
                                water_colour = "grey80",
                                land_fill = "#faf5ef",
                                land_colour = "grey80",
                                mudflat_colour = "#faf5ef",
                                mudflat_fill = "#faf5ef",
                                mudflat_alpha = 0.6,
                                roosts = FALSE,
                                filename = NULL,
                                png_width = 3840,
                                png_height = 2160) {
  # global variables
  patch <- duration <- . <- time_median <- time <- NULL
  x <- y <- datetime <- x_median <- y_median <- tideID <- NULL # nolint
  i.duration <- tag <- dateTime <- inv_rescale_wl <- NULL # nolint
  duration_scaled <- waterlevel <- time_num <- NULL

  # check data structure
  atl_check_data(data, names_expected = c(
    "tag", "x", "y", "time", "datetime", "patch"
  ))
  atl_check_data(tide_data, names_expected = c(
    "tideID", "low_time", "high_start_level", "low_level", "high_end_level"
  ))
  atl_check_data(tide_data_highres, names_expected = c(
    "date", "time", "waterlevel", "dateTime"
  ))
  if (missing(buffer_res_patches) || is.null(buffer_res_patches)) {
    stop(paste0(
      "Function requiers to specify 'buffer_res_patches' value",
      " (see description)."
    ))
  }

  # convert to DT if not
  if (data.table::is.data.table(data) != TRUE) {
    data.table::setDT(data)
  }
  if (data.table::is.data.table(tide_data) != TRUE) {
    data.table::setDT(tide_data)
  }
  if (data.table::is.data.table(tide_data_highres) != TRUE) {
    data.table::setDT(tide_data_highres)
  }

  # subset first if more than one tag
  ds <- data[tag == data[1]$tag]

  # assign tag and tideID new to avoid confusion
  tag_id <- ds[1]$tag
  tideID_id <- tide #nolint

  # create patch summary
  dp <- atl_res_patch_summary(ds)

  # subset all data linked to this tide
  ds <- ds[tideID == tideID_id]
  dp <- dp[patch %in% unique(ds$patch)]

  # check if data for this period and tide
  if (nrow(ds) == 0) {
    stop(paste0(
      "No data for this tag and tide."
    ))
  }

  # subset tide pattern data
  dtp <- tide_data[tideID == tideID_id]

  # subset waterlevel data
  dtf <- tide_data_highres[
    dateTime >= dtp$high_start_time & dateTime <= dtp$high_end_time
  ]

  # patch as factor
  ds[, patch := as.factor(patch)]
  dp[, patch := as.factor(patch)]

  # join duration to ds
  ds[dp, on = .(tag, patch), `:=`(duration = i.duration)]

  # duration in mins
  ds[, duration := duration / 60]
  dp[, duration := duration / 60]

  # transform into sf object
  dp_sf <- atl_as_sf(ds, option = "res_patches", buffer = buffer_res_patches)

  # add duration
  dp_sf <- dp_sf |>
    dplyr::left_join(dp[, .(tag, patch, duration)], by = c("tag", "patch"))

  # set time without patch to 0
  ds[is.na(duration), duration := 0]

  # median time as POSIXct
  dp[, time_median := as.POSIXct(
    time_median,
    origin = "1970-01-01", tz = "UTC"
  )]

  # rescale waterlevel data
  wl_min <- ifelse(!is.na(waterlevel_min), waterlevel_min, min(dtf$waterlevel))
  wl_max <- ifelse(!is.na(waterlevel_max), waterlevel_max, max(dtf$waterlevel))
  dur_min <- min(ds$duration)
  dur_max <- max(ds$duration)

  # function to rescale waterlevel to duration range
  rescale_wl <- function(wl) {
    (wl - wl_min) / (wl_max - wl_min) * (dur_max - dur_min) + dur_min
  }

  # inverse: duration range to waterlevel (for sec_axis labels)
  inv_rescale_wl <- function(x) {
    (x - dur_min) / (dur_max - dur_min) * (wl_max - wl_min) + wl_min
  }

  # add rescaled waterlevel and numeric time to tide data
  dtf[, duration_scaled := rescale_wl(waterlevel)]
  dtf[, time_num := as.numeric(dateTime) + offset * 60]

  # collect relevant data for plot
  tag_species <- ds[1]$species
  year <- min(ds$datetime, na.rm = TRUE) |> year()
  first_data <- min(ds$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  last_data <- max(ds$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  n <- nrow(ds)
  n_patches <- length(unique(dp$patch))
  time_in_patches <- atl_format_time(sum(dp$duration) * 60)

  # create basemap and bounding box
  bm <- atl_create_bm(
    ds,
    water_fill = water_fill,
    water_colour = water_colour,
    land_fill = land_fill,
    land_colour = land_colour,
    mudflat_colour = mudflat_colour,
    mudflat_fill = mudflat_fill,
    mudflat_alpha = mudflat_alpha,
    asp = "4:3",
    buffer = buffer_bm
  )
  bbox <- atl_bbox(ds, buffer = buffer_bm, asp = "4:3")

  # if roosts = TRUE add roost polygon
  if (roosts == TRUE) {
    bm <- suppressMessages(
      bm +
        geom_sf(data = tools4watlas::roosts_griend, fill = NA, color = "black")
    )
  }

  # plot on map
  p1 <- suppressMessages(
    bm +
      # add patch polygons
      geom_sf(data = dp_sf, aes(fill = duration), alpha = 0.6) +
      viridis::scale_fill_viridis(
        option = "A", direction = -1, begin = 0.1,
        name = "Duration in\npatch (min)"
      ) +
      # add track and points
      geom_path(
        data = ds, aes(x, y),
        linewidth = path_linewidth, alpha = path_alpha
      ) +
      geom_point(
        data = ds[is.na(patch)], aes(x, y), size = point_size, color = "grey20",
        alpha = point_alpha, show.legend = FALSE
      ) +
      geom_point(
        data = ds[!is.na(patch)], aes(x, y, color = patch),
        size = point_size, show.legend = FALSE
      ) +
      # add labels for patches
      ggrepel::geom_text_repel(
        data = dp, aes(x_median, y_median, label = patch, colour = patch),
        size = patch_label_size, box.padding = patch_label_padding,
        fontface = "bold", show.legend = FALSE
      ) +
      # set extend again (overwritten by geom_sf)
      coord_sf(
        xlim = c(bbox["xmin"], bbox["xmax"]),
        ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
      ) +
      # adjust legend position
      theme(
        legend.position = "inside",
        legend.position.inside = c(.08, .18),
        legend.background = element_rect(fill = "transparent"),
        legend.title = element_text(face = "bold"),
        legend.text = element_text(size = element_text_size)
      )
  )

  # add overview map
  bbox_sf <- bbox |> sf::st_as_sfc() |> sf::st_set_crs(32631)
  bbox2 <- atl_bbox(ds, buffer = buffer_overview, asp = "1:1")

  bm2 <- atl_create_bm(ds, buffer = buffer_overview, asp = "1:1") +
    suppressMessages(
      # add small area
      geom_sf(data = bbox_sf, color = "firebrick3", fill = NA, lwd = 1) +
        # set extend again (overwritten by geom_sf)
        coord_sf(
          xlim = c(bbox2["xmin"], bbox2["xmax"]),
          ylim = c(bbox2["ymin"], bbox2["ymax"]), expand = FALSE
        )
    )

  # add to map
  p1 <- p1 +
    patchwork::inset_element(bm2, left = 0.8, bottom = 0.8, right = 1, top = 1)

  # add plot by time and duration
  p2 <- suppressMessages(
    ggplot() +
      # add low tide line
      geom_hline(
        yintercept = as.numeric(dtp$low_time) + offset * 60,
        color = "dodgerblue3", linetype = "dashed"
      ) +
      # add high tide lines
      geom_hline(
        yintercept = as.numeric(dtp$high_start_time) + offset * 60,
        color = "dodgerblue3"
      ) +
      geom_hline(
        yintercept = as.numeric(dtp$high_end_time) + offset * 60,
        color = "dodgerblue3"
      ) +
      # add 60 cm lines (before and after low tide)
      geom_hline(
        yintercept = as.numeric(
          dtf[dateTime <= dtp$low_time][which.min(
            abs(waterlevel - waterlevel_line)
          ), dateTime]
        ) + offset * 60,
        color = "steelblue", linetype = "dotted"
      ) +
      geom_hline(
        yintercept = as.numeric(
          dtf[dateTime >= dtp$low_time][which.min(
            abs(waterlevel - waterlevel_line)
          ), dateTime]
        ) + offset * 60,
        color = "steelblue", linetype = "dotted"
      ) +
      # add line and points
      geom_path(
        data = ds, aes(duration, time), color = "grey",
        show.legend = FALSE
      ) +
      geom_point(
        data = ds, aes(duration, time, color = as.character(patch)),
        size = point_size, alpha = 0.5, show.legend = FALSE
      ) +
      # add labels for patches
      geom_text(
        data = dp,
        aes(
          duration + 5, as.numeric(time_median), label = patch, colour = patch
        ),
        size = 4, fontface = "bold", show.legend = FALSE
      ) +
      # flip y axis
      scale_y_reverse(
        breaks = seq(
          from = floor(min(as.numeric(dtp$high_start_time)) / 3600) * 3600,
          to = ceiling(max(as.numeric(dtp$high_end_time)) / 3600) * 3600,
          by = 3600 * 1
        ),
        labels = function(x) {
          format(as.POSIXct(x, origin = "1970-01-01"), "%H", tz = "UTC")
        }
      ) +
      # add tide line using rescaled x
      geom_path(
        data = dtf,
        aes(x = duration_scaled, y = time_num),
        color = "steelblue", linewidth = 0.8, alpha = 0.7
      ) +
      # add second x axis and theme
      scale_x_continuous(
        name = "Duration in patch (min)",
        sec.axis = sec_axis(
          transform = ~ inv_rescale_wl(.),
          name = "Water level (cmNAP)"
        )
      ) +
      labs(y = "Hour (UTC)") +
      theme_bw() +
      theme(
        axis.text.x = element_text(size = element_text_size),
        axis.text.y = element_text(size = element_text_size),
        axis.title.x.top = element_text(color = "steelblue"),
        axis.text.x.top  = element_text(color = "steelblue")
      )
  )

  # combine plots
  p <- p1 + p2 + patchwork::plot_layout(widths = c(3, 1.15)) +
    patchwork::plot_annotation(
      title = paste(
        "<b>Tag:</b>", tag_id,
        "<span style='white-space:pre;'>    </span>",
        "<b>Species:</b>", tag_species,
        "<span style='white-space:pre;'>    </span>",
        "<b>TideID:</b>", tideID_id
      ),
      subtitle = paste(
        "<b>Year:</b>", year,
        "<span style='white-space:pre;'>    </span>",
        "<b>First:</b>", first_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>Last:</b>", last_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>N pos:</b>", n,
        "<span style='white-space:pre;'>    </span>",
        "<b>N patches:</b>", n_patches,
        "<span style='white-space:pre;'>    </span>",
        "<b>T in patches:</b>", time_in_patches,
        "<span style='white-space:pre;'>    </span>",
        "<b>Waterlevel (HLH):</b>", dtp$high_start_level, " / ",
        dtp$low_level, " / ", dtp$high_end_level
      ),
      theme = theme(
        plot.subtitle = element_markdown(hjust = 0.5),
        plot.title = element_markdown(hjust = 0.5)
      )
    )

  # return or save
  if (is.null(filename)) {
    # return if no filename provided
    p
  } else {
    # save the plot if filename provided
    agg_png(
      filename = paste0(filename, ".png"),
      width = png_width, height = png_height, units = "px", res = 300
    )
    print(p)
    dev.off()
  }
}
