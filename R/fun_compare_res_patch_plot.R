#' Plot residence patches to compare two versions of parameters for one tag
#'
#' Generates a side-by-side `ggplot2` showing residence patches from two
#' versions of processed tracking data (`data_v1` and `data_v2`) for a single
#' tag, including movement paths, patch durations, and annotated summaries.
#' Useful for reviewing changes in patch detection between processing versions.
#'
#' Made to plot results of `atl_compare_res_patch_summary()`. The N pos, N
#' patches and T in patches are only based on the patches of interest. By
#' setting `time_buffer` other patches (or parts within the buffer) will be
#' shown in the plot if they are within the period.
#'
#' @author Johannes Krietsch
#' @param data_v1 A `data.table` containing tracking data from version 1. Must
#'   include the columns: `tag`, `x`, `y`, `time`, `datetime`, and `patch`, as
#'   created by `atl_res_patch()`. Optionally `species` and `tideID`.
#' @param data_v2 A `data.table` containing tracking data from version 2. Must
#'   include the same columns as `data_v1`.
#' @param tag Tag ID to subset and plot.
#' @param change Character describing the type of change between versions (e.g.
#'   `"gained"`, `"lost"`, `"split"`, `"merge"`). Used for plot only..
#' @param patch_v1 A comma-separated character string of patch IDs from version
#'   1 to highlight (e.g. `"1,2,3"`). Use `NA` if no patches exist in v1.
#' @param patch_v2 A comma-separated character string of patch IDs from version
#'   2 to highlight (e.g. `"1,2,3"`). Use `NA` if no patches exist in v2.
#' @param time_buffer Numeric. Seconds to extend the time window around the
#'   focal patches (default: 600).
#' @param speed_threshold Speed threshold in m/s for colour scale of movement
#'   speed (default: 3 m/s).
#' @param point_size Size of plotted points (default: 1).
#' @param point_alpha Transparency of points (default: 0.9).
#' @param path_linewidth Line width of movement paths (default: 0.5).
#' @param path_alpha Transparency of movement paths (default: 0.9).
#' @param patch_label_size Font size for patch labels (default: 4).
#' @param patch_label_padding Padding for patch labels (default: 1).
#' @param patch_alpha Alpha for patch polygons (default: 0.7).
#' @param element_text_size Font size for axis and legend text (default: 11).
#' @param buffer_res_patches A numeric value (in meters) specifying the buffer
#'   around the polygon of each residence patch (default: 20).
#' @param buffer_bm Map buffer size in meters (default: 250).
#' @param water_fill Water fill colour (default: `"white"`).
#' @param water_colour Water border colour (default: `"grey80"`).
#' @param land_fill Land fill colour (default: `"#faf5ef"`).
#' @param land_colour Land border colour (default: `"grey80"`).
#' @param mudflat_colour Mudflat border colour (default: `"#faf5ef"`).
#' @param mudflat_fill Mudflat fill colour (default: `"#faf5ef"`).
#' @param mudflat_alpha Mudflat transparency (default: 0.6).
#' @param seed Integer seed used to shuffle the patch colours, so that the
#'   colour order is reproducible. Default is 1.
#' @param filename Character (or `NULL`). If provided, the plot is saved as a
#'   `.png` file to this path and filename; otherwise the plot is returned.
#' @param png_width Width of saved PNG in pixels (default: 3840).
#' @param png_height Height of saved PNG in pixels (default: 2160).
#'
#' @return A `ggplot` object or a saved PNG file.
#' @import ggplot2 patchwork
#' @importFrom ggtext element_markdown
#' @importFrom ragg agg_png
#' @importFrom grDevices dev.off
#'
#' @examples
#' # packages
#' library(tools4watlas)
#' library(foreach)
#'
#' # load example data
#' data <- data_example
#'
#' # run atl_res_patch with two different parameter sets
#' data_v1 <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 2, min_duration = 60
#' )
#' data_v2 <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 5, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 2, min_duration = 60
#' )
#'
#' # change summary
#' change_summary <- atl_compare_res_patch_summary(data_v1, data_v2)
#'
#' # plot specific change
#' i <- 1
#'
#' atl_compare_res_patch_plot(
#'   data_v1 = data_v1,
#'   data_v2 = data_v2,
#'   tag = change_summary$tag[i],
#'   change = change_summary$change[i],
#'   patch_v1 = change_summary$patch_v1[i],
#'   patch_v2 = change_summary$patch_v2[i]
#' )
#'
#' # plot all changes in loop (requires the foreach package)
#' # for many changes, it makes sense to set a filename to save the plots
#' if (requireNamespace("foreach", quietly = TRUE)) {
#'   library(foreach)
#'   foreach(i = seq_len(nrow(change_summary))) %do% {
#'     atl_compare_res_patch_plot(
#'       data_v1 = data_v1,
#'       data_v2 = data_v2,
#'       tag = change_summary$tag[i],
#'       change = change_summary$change[i],
#'       patch_v1 = change_summary$patch_v1[i],
#'       patch_v2 = change_summary$patch_v2[i]
#'     )
#'   }
#' }
#'
#' @export
atl_compare_res_patch_plot <- function(data_v1,
                                       data_v2,
                                       tag,
                                       change,
                                       patch_v1,
                                       patch_v2,
                                       time_buffer = 600,
                                       speed_threshold = 3,
                                       point_size = 1,
                                       point_alpha = 0.9,
                                       path_linewidth = 0.5,
                                       path_alpha = 0.9,
                                       patch_label_size = 4,
                                       patch_label_padding = 1,
                                       patch_alpha = 0.7,
                                       element_text_size = 11,
                                       buffer_res_patches = 20,
                                       buffer_bm = 250,
                                       water_fill = "white",
                                       water_colour = "grey80",
                                       land_fill = "#faf5ef",
                                       land_colour = "grey80",
                                       mudflat_colour = "#faf5ef",
                                       mudflat_fill = "#faf5ef",
                                       mudflat_alpha = 0.6,
                                       seed = 1,
                                       filename = NULL,
                                       png_width = 3840,
                                       png_height = 2160) {
  # global variables
  patch <- duration <- species <- tideID <- i.duration <- NULL # nolint
  x <- y <- datetime <- x_median <- y_median <- speed_in <- . <- NULL

  # check data structure
  atl_check_data(data_v1, names_expected = c(
    "tag", "x", "y", "time", "datetime", "patch"
  ))
  atl_check_data(data_v2, names_expected = c(
    "tag", "x", "y", "time", "datetime", "patch"
  ))

  # assign tag and tideID new to avoid confusion
  tag_id <- tag

  # parse patch IDs from both versions
  v1_ids <- as.integer(trimws(strsplit(patch_v1, ",")[[1]]))
  v2_ids <- as.integer(trimws(strsplit(patch_v2, ",")[[1]]))

  # check period of interest
  if (all(is.na(v1_ids)) && !all(is.na(v2_ids))) {
    # only v2 has patches (gained)
    from <- data_v2[tag == tag_id & patch %in% v2_ids, min(datetime)]
    to <- data_v2[tag == tag_id & patch %in% v2_ids, max(datetime)]
  } else if (!all(is.na(v1_ids)) && all(is.na(v2_ids))) {
    # only v1 has patches (lost)
    from <- data_v1[tag == tag_id & patch %in% v1_ids, min(datetime)]
    to <- data_v1[tag == tag_id & patch %in% v1_ids, max(datetime)]
  } else {
    # both have patches (split, merge)
    from <- min(
      data_v1[tag == tag_id & patch %in% v1_ids, min(datetime)],
      data_v2[tag == tag_id & patch %in% v2_ids, min(datetime)]
    )
    to <- max(
      data_v1[tag == tag_id & patch %in% v1_ids, max(datetime)],
      data_v2[tag == tag_id & patch %in% v2_ids, max(datetime)]
    )
  }

  # add time buffer
  from <- from - time_buffer
  to <- to + time_buffer

  # subset data
  ds1 <- data_v1[tag == tag_id & datetime >= from & datetime <= to]
  ds2 <- data_v2[tag == tag_id & datetime >= from & datetime <= to]

  # check if data for this period
  if (nrow(ds1) == 0) {
    stop(paste0(
      "No data_v1 for this tag."
    ))
  }
  if (nrow(ds2) == 0) {
    stop(paste0(
      "No data_v2 for this tag."
    ))
  }

  # speed in
  ds1 <- atl_get_speed(ds1, type = c("in"))
  ds2 <- atl_get_speed(ds2, type = c("in"))

  # create patch summary
  dp1 <- atl_res_patch_summary(ds1)
  dp2 <- atl_res_patch_summary(ds2)

  # duration in mins
  dp1[, duration := duration / 60]
  dp2[, duration := duration / 60]

  # join duration to ds
  ds1[dp1, on = .(tag, patch), `:=`(duration = i.duration)]
  ds2[dp2, on = .(tag, patch), `:=`(duration = i.duration)]

  # transform into sf object
  dp_sf1 <- atl_as_sf(ds1, option = "res_patches", buffer = buffer_res_patches)
  dp_sf2 <- atl_as_sf(ds2, option = "res_patches", buffer = buffer_res_patches)

  # add duration
  dp_sf1 <- dp_sf1 |>
    dplyr::left_join(dp1[, .(tag, patch, duration)], by = c("tag", "patch"))
  dp_sf2 <- dp_sf2 |>
    dplyr::left_join(dp2[, .(tag, patch, duration)], by = c("tag", "patch"))

  # collect relevant data for plot
  tag_species <- if ("species" %in% names(ds1)) ds1[1, species] else NA
  year <- min(ds1$datetime, na.rm = TRUE) |> year()
  first_data <- min(ds1$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  last_data <- max(ds1$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  n1 <- if (all(is.na(v1_ids))) 0 else nrow(ds1[patch %in% v1_ids])
  n2 <- if (all(is.na(v2_ids))) 0 else nrow(ds2[patch %in% v2_ids])
  n_patches1 <- length(unique(dp1[patch %in% v1_ids]$patch))
  n_patches2 <- length(unique(dp2[patch %in% v2_ids]$patch))
  time_in_patches1 <- atl_format_time(sum(dp1[patch %in% v1_ids]$duration) * 60)
  time_in_patches2 <- atl_format_time(sum(dp2[patch %in% v2_ids]$duration) * 60)
  tide_id <- if ("tideID" %in% names(ds1)) ds1[1, tideID] else NA

  # generate shuffled colour palette
  patch_colours <- withr::with_seed(seed, {
    list(
      v1 = if (n_patches1 > 0) sample(scales::hue_pal()(n_patches1)),
      v2 = if (n_patches2 > 0) sample(scales::hue_pal()(n_patches2))
    )
  })

  if (n_patches1 > 0) {
    patch_colours1 <- patch_colours$v1
    names(patch_colours1) <- v1_ids
  }
  if (n_patches2 > 0) {
    patch_colours2 <- patch_colours$v2
    names(patch_colours2) <- v2_ids
  }

  # create basemap and bounding box
  bm <- atl_create_bm(
    ds1,
    water_fill = water_fill,
    water_colour = water_colour,
    land_fill = land_fill,
    land_colour = land_colour,
    mudflat_colour = mudflat_colour,
    mudflat_fill = mudflat_fill,
    mudflat_alpha = mudflat_alpha,
    asp = "1:1",
    buffer = buffer_bm
  )
  bbox <- atl_bbox(ds1, buffer = buffer_bm, asp = "1:1")

  # shared duration range across both versions
  dur_min <- min(
    if (n_patches1 > 0) dp1$duration else Inf,
    if (n_patches2 > 0) dp2$duration else Inf
  )
  dur_max <- max(
    if (n_patches1 > 0) dp1$duration else -Inf,
    if (n_patches2 > 0) dp2$duration else -Inf
  )

  # shared speed range across both versions
  speed_max <- max(
    max(ds1$speed_in, na.rm = TRUE),
    max(ds2$speed_in, na.rm = TRUE)
  )

  # conditional patch layers for v1
  patch_layers1 <- if (n_patches1 > 0) {
    list(
      geom_sf(
        data = dp_sf1, aes(fill = duration, color = patch),
        alpha = patch_alpha, linewidth = 1
      ),
      viridis::scale_fill_viridis(
        option = "A", direction = -1, begin = 0.1,
        name = "Duration in\npatch (min)",
        limits = c(dur_min, dur_max)
      ),
      scale_color_manual(values = patch_colours1, guide = "none"),
      ggnewscale::new_scale_colour(),
      ggrepel::geom_text_repel(
        data = dp1, aes(x_median, y_median, label = patch, colour = patch),
        size = patch_label_size, box.padding = patch_label_padding,
        fontface = "bold", show.legend = FALSE
      ),
      scale_colour_manual(values = patch_colours1, guide = "none")
    )
  } else {
    list()
  }

  # plot v1 map
  p1 <- suppressMessages(
    bm +
      patch_layers1 +
      # add track and points
      ggnewscale::new_scale_colour() +
      geom_path(
        data = ds1, aes(x, y, group = tag, colour = speed_in),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds1[speed_in <= speed_threshold],
        aes(x, y, group = tag, colour = speed_in),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds1[speed_in > speed_threshold],
        aes(x, y, group = tag, colour = speed_in),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_gradientn(
        colours = c("black", "grey", "#00CFFF", "dodgerblue4"),
        values = scales::rescale(c(
          0,
          speed_threshold - 1e-9,
          speed_threshold,
          speed_max
        )),
        limits = c(0, speed_max),
        name = "Speed (m/s)"
      ) +
      coord_sf(
        xlim = c(bbox["xmin"], bbox["xmax"]),
        ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
      ) +
      theme(
        legend.position = "inside",
        legend.position.inside = c(0.08, 0.3),
        legend.background = element_rect(fill = "transparent"),
        legend.title = element_text(face = "bold"),
        legend.text = element_text(size = element_text_size)
      )
  )

  # conditional patch layers for v2
  patch_layers2 <- if (n_patches2 > 0) {
    list(
      geom_sf(
        data = dp_sf2, aes(fill = duration, color = patch),
        alpha = patch_alpha, linewidth = 1
      ),
      viridis::scale_fill_viridis(
        option = "A", direction = -1, begin = 0.1,
        name = "Duration in\npatch (min)",
        limits = c(dur_min, dur_max)
      ),
      scale_color_manual(values = patch_colours2, guide = "none"),
      ggnewscale::new_scale_colour(),
      ggrepel::geom_text_repel(
        data = dp2, aes(x_median, y_median, label = patch, colour = patch),
        size = patch_label_size, box.padding = patch_label_padding,
        fontface = "bold", show.legend = FALSE
      ),
      scale_colour_manual(values = patch_colours2, guide = "none")
    )
  } else {
    list()
  }

  # plot v2 map
  p2 <- suppressMessages(
    bm +
      patch_layers2 +
      # add track and points
      ggnewscale::new_scale_colour() +
      geom_path(
        data = ds2, aes(x, y, group = tag, colour = speed_in),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds2[speed_in <= speed_threshold],
        aes(x, y, group = tag, colour = speed_in),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds2[speed_in > speed_threshold],
        aes(x, y, group = tag, colour = speed_in),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_gradientn(
        colours = c("black", "grey", "#00CFFF", "dodgerblue4"),
        values = scales::rescale(c(
          0,
          speed_threshold - 1e-9,
          speed_threshold,
          speed_max
        )),
        limits = c(0, speed_max),
        name = "Speed (m/s)"
      ) +
      coord_sf(
        xlim = c(bbox["xmin"], bbox["xmax"]),
        ylim = c(bbox["ymin"], bbox["ymax"]), expand = FALSE
      ) +
      theme(
        legend.position = "inside",
        legend.position.inside = c(0.08, 0.3),
        legend.background = element_rect(fill = "transparent"),
        legend.title = element_text(face = "bold"),
        legend.text = element_text(size = element_text_size)
      )
  )

  p <- p1 + p2 + patchwork::plot_layout(guides = "collect") +
    patchwork::plot_annotation(
      title = paste(
        "<b>Tag:</b>", tag_id,
        "<span style='white-space:pre;'>    </span>",
        "<b>Species:</b>", tag_species,
        "<span style='white-space:pre;'>    </span>",
        "<b>TideID:</b>", tide_id
      ),
      subtitle = paste(
        "<b>Year:</b>", year,
        "<span style='white-space:pre;'>    </span>",
        "<b>First:</b>", first_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>Last:</b>", last_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>Patches:</b>", change,
        "<span style='white-space:pre;'>    </span>",
        "<b>N pos:</b>", n1, " | ", n2,
        "<span style='white-space:pre;'>    </span>",
        "<b>N patches:</b>", n_patches1, " | ", n_patches2,
        "<span style='white-space:pre;'>    </span>",
        "<b>T in patches:</b>", time_in_patches1, " | ", time_in_patches2
      ),
      theme = theme(
        plot.subtitle = ggtext::element_markdown(hjust = 0.5),
        plot.title = ggtext::element_markdown(hjust = 0.5)
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
