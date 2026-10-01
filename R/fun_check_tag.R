#' Check the data from one tag on a map
#'
#' This function processes tracking data for a specific tag and generates a
#' visualization using `ggplot2`. It allows customization of colours, point
#' sizes, and track styles, and supports various display options such as
#' datetime, nbs (number of base stations / receivers), standard deviation,
#' speed_in and gap. The function can either return the plot or save it as an
#' png file.
#'
#' @author Johannes Krietsch
#' @param data A `data.table` containing tracking data. Must include the
#'   columns: `"tag"`, `"x"`, `"y"`, `"time"`, and `"datetime"`.
#' @param buffer Numeric. The buffer size in meters around the data points in
#' the plot (default: 1000).
#' @param asp The aspect ratio of the plot (default: `"16:9"`).
#' @param option Determines the colour mapping variable. Options are:
#'   - `"datetime"`: Datetime along the track
#'   - `"nbs"`: Number of receiver (base) stations that contributed to the
#'   localization
#'   - `"var"`: Error as maximal variance of varx and vary
#'   - `"speed_in"`: Speed in m/s
#'   - `"gap"`: Gaps coloured by time and as point size
#' @param scale_option Character. The colour scheme option from `viridis`
#'   (default: `"A"`). See
#'    https://search.r-project.org/CRAN/refmans/viridisLite/html/viridis.html
#'    for all options (A-H).
#' @param scale_direction Numeric. Direction of the colour scale
#'   (-1 reverses, default: -1).
#' @param scale_trans Transformation of the scale. Default is "identity",
#' (no transformation), could be e.g. "log", "log10" or "sqrt".
#' See scale_*_trans() for all options.
#' @param scale_max If set, determines the max value of the scale for options:
#' nbs (numeric), var (numeric), speed_in (numeric m/s), gap
#' (numeric in seconds). Everything above the max value will get the max colour.
#' @param first_n Numeric (or NULL). If provided, only the first `n` locations
#'   are shown.
#' @param last_n Numeric (or NULL). If provided, only the last `n` locations
#'   are shown.
#' @param highlight_first Logical. If `TRUE`, highlights the first point in the
#'   track (default: `FALSE`).
#' @param highlight_last Logical. If `TRUE`, highlights the last point in the
#'   track (default: `FALSE`).
#' @param highlight_outliers Logical. If `TRUE`, highlights all points that are
#'   flagged as outliers (needs preassigned column with outlier TRUE or FALSE)
#'   track (default: `FALSE`).
#' @param point_size The size of the data points (default: 0.5).
#' @param point_alpha Numeric. Transparency of the data points (default: 1).
#' @param path_linewidth Numeric. The width of the connecting track lines
#'   (default: 0.5).
#' @param path_alpha Transparency of the track lines (default: 0.1).
#' @param element_text_size Adjust size of the text.
#' @param water_fill Water fill (default "#D7E7FF")
#' @param water_colour Water colour (default "grey80")
#' @param land_fill Land fill (default "#faf5ef")
#' @param land_colour Land colour (default "grey80")
#' @param mudflat_colour Mudflat colour (default "#faf5ef")
#' @param mudflat_fill Mudflat fill (default "#faf5ef")
#' @param mudflat_alpha Mudflat alpha (default 0.6)
#' @param filename Character (or NULL). If provided, the plot is saved as a
#'   `.png` file to this path and with this name; otherwise, the function
#'   returns the plot.
#' @param png_width Width of saved PNG (default: 3840).
#' @param png_height Height of saved PNG (default: 2160).
#'
#' @return A `ggplot2` object with the specified option and adjustments. If
#'   `filename` is provided, the plot is saved as a `.png` file instead of
#'   being returned.
#' @import ggplot2
#' @import ggspatial
#' @import scales
#' @importFrom viridis scale_colour_viridis
#' @importFrom ggtext element_markdown
#' @importFrom ragg agg_png
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # path to csv with filtered data
#' data_path <- system.file(
#'   "extdata", "watlas_data_filtered.csv",
#'   package = "tools4watlas"
#' )
#'
#' # load data
#' data <- fread(data_path, yaml = TRUE)
#'
#' # subset bar-tailed godwit
#' data <- data[species == "bar-tailed godwit"]
#'
#' # plot different options
#' atl_check_tag(
#'   data,
#'   option = "datetime",
#'   highlight_first = TRUE, highlight_last = TRUE
#' )
#' atl_check_tag(data, option = "nbs")
#' atl_check_tag(data, option = "var")
#' atl_check_tag(data, option = "speed_in")
#' atl_check_tag(data, option = "gap")
#'
#' # add outliers, for example for speed:
#' data[, outlier := speed_in > 35]
#' atl_check_tag(data, option = "speed_in", highlight_outliers = TRUE)
#' @export
atl_check_tag <- function(data,
                          buffer = 1000,
                          asp = "16:9",
                          option = "datetime",
                          scale_option = "A",
                          scale_direction = -1,
                          scale_trans = "identity",
                          scale_max = NULL,
                          first_n = NULL,
                          last_n = NULL,
                          highlight_first = FALSE,
                          highlight_last = FALSE,
                          highlight_outliers = FALSE,
                          point_size = 0.5,
                          point_alpha = 1,
                          path_linewidth = 0.5,
                          path_alpha = 0.1,
                          element_text_size = 11,
                          water_fill = "#D7E7FF",
                          water_colour = "grey80",
                          land_fill = "#faf5ef",
                          land_colour = "grey80",
                          mudflat_colour = "#faf5ef",
                          mudflat_fill = "#faf5ef",
                          mudflat_alpha = 0.6,
                          filename = NULL,
                          png_width = 3840,
                          png_height = 2160) {
  # global variables
  tag <- time <- first_n_pos <- last_n_pos <- is_first <- is_last <- gap <- NULL
  datetime <- gap_in <- var <- varx <- vary <- x <- y <- nbs <- speed_in <- NULL
  outlier <- NULL

  # check valid option
  valid_options <- c("datetime", "nbs", "var", "speed_in", "gap")
  if (!(option %in% valid_options)) {
    stop(paste(
      "Invalid option. Choose one of:",
      paste(valid_options, collapse = ", ")
    ))
  }

  # check data structure
  required_columns <- c("tag", "x", "y", "time", "datetime")
  option_columns <- list(
    datetime = NULL,
    nbs = "nbs",
    var = c("varx", "vary"),
    speed_in = "speed_in",
    gap = "time"
  )
  atl_check_data(data, names_expected = c(
    required_columns, option_columns[[option]]
  ))

  # if if (highlight_outliers == TRUE) {
  if (highlight_outliers) {
    atl_check_data(data, names_expected = c("outlier"))
  }

  # convert to DT if not
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }

  # subset first if more than one tag
  ds <- data[tag == data[1]$tag]

  # Subset first n positions
  if (!is.null(first_n)) {
    ds[, first_n_pos := seq_len(.N) <= first_n]
    ds <- ds[first_n_pos == TRUE]
  }

  # subset last n positions
  if (!is.null(last_n)) {
    ds[, last_n_pos := seq_len(.N) > (.N - last_n)]
    ds <- ds[last_n_pos == TRUE]
  }

  # identify first and last point
  ds[, is_first := seq_len(.N) == 1]
  ds[, is_last := seq_len(.N) > (.N - 1)]

  # collect relevant data for plot
  tag_id <- ds[1]$tag
  tag_species <- ds[1]$species
  tag_ring <- ds[1]$rings
  tag_crc <- ds[1]$crc
  tag_name <- ds[1]$bird_name
  year <- min(ds$datetime, na.rm = TRUE) |> year()
  first_data <- min(ds$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  last_data <- max(ds$datetime, na.rm = TRUE) |> format("%d %b %H:%M")
  days_data <- round(
    as.numeric(difftime(
      max(ds$datetime, na.rm = TRUE),
      min(ds$datetime, na.rm = TRUE),
      units = "days"
    )), 2
  )
  n <- nrow(ds)

  # longest gap
  ds[, gap := c(NA, diff(time))]
  ds[, gap_in := shift(gap, type = "lead")]
  min_gap <- min(ds$gap, na.rm = TRUE)
  ds[is.na(gap_in), gap_in := min_gap]
  max_gap <- max(ds$gap, na.rm = TRUE)
  max_gap_format <- atl_format_time(max_gap)

  # sd
  if (option == "var") {
    ds[, var := pmax(varx, vary, na.rm = TRUE)]
  }

  # create basemap
  bm <- atl_create_bm(
    ds,
    water_fill = water_fill,
    water_colour = water_colour,
    land_fill = land_fill,
    land_colour = land_colour,
    mudflat_colour = mudflat_colour,
    mudflat_fill = mudflat_fill,
    mudflat_alpha = mudflat_alpha,
    asp = asp,
    buffer = buffer
  )

  # add title
  p <- bm +
    ggtitle(
      label = paste(
        "<b>Tag:</b>", tag_id,
        "<span style='white-space:pre;'>    </span>",
        # add species if not NULL
        if (!is.null(tag_species)) {
          paste(
            "<b>Species:</b>", tag_species,
            "<span style='white-space:pre;'>    </span>"
          )
        } else {
          ""
        },
        # add ring if not NULL
        if (!is.null(tag_ring)) {
          paste(
            "<b>Ring:</b>", tag_ring,
            "<span style='white-space:pre;'>    </span>"
          )
        } else {
          ""
        },
        # add crc if not NULL
        if (!is.null(tag_crc)) {
          paste(
            "<b>Crc:</b>", tag_crc,
            "<span style='white-space:pre;'>    </span>"
          )
        } else {
          ""
        },
        # add name if not NULL
        if (!is.null(tag_name)) paste("<b>Name:</b>", tag_name) else ""
      ),
      subtitle = paste(
        "<b>Days data:</b>", days_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>Year:</b>", year,
        "<span style='white-space:pre;'>    </span>",
        "<b>First:</b>", first_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>Last:</b> ", last_data,
        "<span style='white-space:pre;'>    </span>",
        "<b>N localizations:</b> ", n,
        "<span style='white-space:pre;'>    </span>",
        "<b>Longest gap:</b> ", max_gap_format
      )
    )

  # add points and tracks with different options
  # add tracks by datetime
  if (option == "datetime") {
    # check for right date format
    if (days_data < 1) {
      datetime_format <- date_format("%H:%M")
    } else {
      datetime_format <- date_format("%d %b")
    }

    p <- p +
      geom_path(
        data = ds, aes(x, y, colour = datetime),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds, aes(x, y, colour = datetime),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_viridis_c(
        option = scale_option, direction = scale_direction,
        trans = "time", labels = datetime_format,
        name = "Datetime"
      )
  }

  # add tracks by nbs
  if (option == "nbs") {
    if (is.null(scale_max)) {
      scale_max <- max(ds$nbs, na.rm = TRUE)
    } else {
      ds[nbs > scale_max, nbs := scale_max]
    }

    p <- p +
      geom_path(
        data = ds, aes(x, y, colour = nbs),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds, aes(x, y, colour = nbs),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_viridis(
        option = scale_option, direction = scale_direction,
        name = "NBS", trans = scale_trans, limits = c(3, scale_max)
      )
  }

  # add tracks by var
  if (option == "var") {
    if (is.null(scale_max)) {
      scale_max <- max(ds$var, na.rm = TRUE)
    } else {
      ds[var > scale_max, var := scale_max]
    }

    p <- p +
      geom_path(
        data = ds, aes(x, y, colour = var),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds, aes(x, y, colour = var),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_viridis(
        option = scale_option, direction = scale_direction,
        name = "Variance", trans = scale_trans, limits = c(0.01, scale_max)
      )
  }

  # add tracks by speed_in
  if (option == "speed_in") {
    if (is.null(scale_max)) {
      scale_max <- max(ds$speed_in, na.rm = TRUE)
    } else {
      ds[speed_in > scale_max, speed_in := scale_max]
    }

    p <- p +
      geom_path(
        data = ds, aes(x, y, colour = speed_in),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds, aes(x, y, colour = speed_in),
        size = point_size, alpha = point_alpha, show.legend = TRUE
      ) +
      scale_colour_viridis(
        option = scale_option, direction = scale_direction,
        name = "Speed (m/s)", trans = scale_trans, limits = c(0.0001, scale_max)
      )
  }

  # add tracks by gap
  if (option == "gap") {
    if (is.null(scale_max)) {
      scale_max <- max(ds$gap_in, na.rm = TRUE)
    } else {
      ds[gap_in > scale_max, gap_in := scale_max]
    }

    p <- p +
      geom_path(
        data = ds, aes(x, y, colour = gap_in),
        linewidth = path_linewidth, alpha = path_alpha, show.legend = TRUE
      ) +
      geom_point(
        data = ds[gap > 3600],
        aes(x, y, colour = gap_in, size = gap_in),
        alpha = point_alpha, show.legend = FALSE
      ) +
      geom_point(
        data = ds[gap < 3600],
        aes(x, y, colour = gap_in, size = gap_in),
        alpha = point_alpha, show.legend = FALSE
      ) +
      scale_size_continuous(
        range = c(0.5, 15), guide = "none",
        limits = c(NA, scale_max)
      ) +
      scale_colour_viridis(
        option = scale_option, direction = scale_direction,
        name = "Gap", trans = scale_trans,
        breaks = c(10, 60, 600, 3600, 86400),
        labels = c("10 sec", "1 min", "10 min", "1 hr", "1 day"),
        limits = c(NA, scale_max)
      )
  }

  # highlight first point if TRUE
  if (highlight_first) {
    p <- p +
      geom_point(
        data = ds[is_first],
        aes(x, y), color = "darkgreen",
        pch = 5, size = 10, stroke = 2,
        show.legend = FALSE
      )
  }

  # highlight last point if TRUE
  if (highlight_last) {
    p <- p +
      geom_point(
        data = ds[is_last],
        aes(x, y), color = "firebrick",
        pch = 4, size = 10, stroke = 2,
        show.legend = FALSE
      )
  }

  # highlight outlier point if TRUE
  if (highlight_outliers) {
    p <- p +
      geom_point(
        data = ds[outlier],
        aes(x, y), color = "dodgerblue",
        pch = 8, size = 10, stroke = 2,
        show.legend = FALSE
      )
  }

  # add theme
  p <- p +
    theme(
      text = element_text(size = element_text_size),
      legend.key.height = unit(1.5, "cm"),
      legend.position = "right",
      plot.background = element_rect(fill = "white"),
      plot.margin = unit(c(0.5, 0, 0, 0), "lines"),
      plot.subtitle = element_markdown(hjust = 0.5),
      plot.title = element_markdown(hjust = 0.5)
    )

  # return or save
  if (is.null(filename)) {
    p
  } else {
    ggplot2::ggsave(
      filename = paste0(filename, ".png"),
      plot = p,
      device = ragg::agg_png,
      width = png_width, height = png_height, units = "px", dpi = 300
    )
    invisible(p)
  }
}
