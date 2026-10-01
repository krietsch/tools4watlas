#' WATLAS species colours
#'
#' Returns a vector or table of predefined colours for WATLAS species.
#'
#' @param option A character string specifying the output format. Options are 
#'   `"vector"` (default), which returns a named colour vector, or `"table"`, 
#'   which returns a data.table with species names and colours.
#'
#' @return A named character vector (for use in ggplot2) or a data.table 
#'   with species names and corresponding colours.
#' @export
#'
#' @examples
#' library(tools4watlas)
#' atl_spec_cols("vector")
#' atl_spec_cols("table")
atl_spec_cols <- function(option = "vector") {
  # Ensure valid input
  match.arg(option, choices = c("vector", "table"))

  # Vector with colors
  species_colours <- c(
    "curlew" = "mediumpurple",
    "bar-tailed godwit" = "#E69F00",
    "oystercatcher" = "grey20",
    "redshank" = "#ffdd3c",
    "red knot" = "firebrick",
    "sanderling" = "#0072B2",
    "dunlin" = "#66A61E",
    "turnstone" = "#A6761D",
    "grey plover" = "grey70",
    "curlew sandpiper" = "#FC94AF",
    "spoonbill" = "ivory",
    "kentish plover" = "#56B4E9"
  )

  # Return selected format
  if (option == "vector") {
    return(species_colours)
  } else {
    return(data.table::data.table(
      species = names(species_colours),
      colour = species_colours
    ))
  }
}

#' WATLAS species labels
#'
#' Returns a named vector of species labels in either a multiline or single-line
#' format, which can also be the short common name.
#'
#' @param option A character string specifying the format of the species names. 
#'   Options are `"multiline"` (default), where names include line breaks
#'   (`\n`),  or `"singleline"`, where names are returned as a single line.
#'   Additionally, `"short_multiline"` and `"short_singleline"` options can be
#'   returned.
#'
#' @return A named character vector where names correspond to species 
#' identifiers and values are formatted species names.
#' @export
#'
#' @examples
#' library(tools4watlas)
#' atl_spec_labs("multiline")
#' atl_spec_labs("singleline")
#' atl_spec_labs("short_multiline")
#' atl_spec_labs("short_singleline")
atl_spec_labs <- function(option = "multiline") {
  # Ensure valid input
  match.arg(option, choices = c(
    "multiline", "singleline", "short_multiline", "short_singleline"
  ))

  # Return selected format
  if (option == "multiline") {
    return(c(
      "curlew" = "Eurasian\ncurlew",
      "bar-tailed godwit" = "Bar-tailed\ngodwit",
      "oystercatcher" = "Eurasian\noystercatcher",
      "redshank" = "Common\nredshank",
      "red knot" = "Red knot",
      "sanderling" = "Sanderling",
      "dunlin" = "Dunlin",
      "turnstone" = "Ruddy\nturnstone",
      "grey plover" = "Grey\nplover",
      "curlew sandpiper" = "Curlew\nsandpiper",
      "spoonbill" = "Eurasian\nspoonbill",
      "kentish plover" = "Kentish\nplover"
    ))
  } else if (option == "singleline") {
    return(c(
      "curlew" = "Eurasian curlew",
      "bar-tailed godwit" = "Bar-tailed godwit",
      "oystercatcher" = "Eurasian oystercatcher",
      "redshank" = "Common redshank",
      "red knot" = "Red knot",
      "sanderling" = "Sanderling",
      "dunlin" = "Dunlin",
      "turnstone" = "Ruddy turnstone",
      "grey plover" = "Grey plover",
      "curlew sandpiper" = "Curlew sandpiper",
      "spoonbill" = "Eurasian spoonbill",
      "kentish plover" = "Kentish plover"
    ))
  } else if (option == "short_multiline") {
    return(c(
      "curlew" = "Curlew",
      "bar-tailed godwit" = "Bar-tailed\ngodwit",
      "oystercatcher" = "Oystercatcher",
      "redshank" = "Redshank",
      "red knot" = "Red knot",
      "sanderling" = "Sanderling",
      "dunlin" = "Dunlin",
      "turnstone" = "Turnstone",
      "grey plover" = "Grey\nplover",
      "curlew sandpiper" = "Curlew\nsandpiper",
      "spoonbill" = "Spoonbill",
      "kentish plover" = "Grey\nplover"
    ))
  } else if (option == "short_singleline") {
    return(c(
      "curlew" = "Curlew",
      "bar-tailed godwit" = "Bar-tailed godwit",
      "oystercatcher" = "Oystercatcher",
      "redshank" = "Redshank",
      "red knot" = "Red knot",
      "sanderling" = "Sanderling",
      "dunlin" = "Dunlin",
      "turnstone" = "Turnstone",
      "grey plover" = "Grey plover",
      "curlew sandpiper" = "Curlew sandpiper",
      "spoonbill" = "Spoonbill",
      "kentish plover" = "Grey plover"
    ))
  }
}

#' Assign colours to tag ID's
#'
#' Generates distinct and visually distinct colours for a set of input tags
#' using the default hue-based palette from ggplot2
#' (via \code{scales::hue_pal()}).
#' This is useful for assigning consistent colours to categorical labels in
#' plots, for example in an animation, where not all individuals always have
#' data in each frame.
#'
#' @param tags A character or numeric vector of tags. Duplicate values are
#' ignored.
#' @param option A string indicating the output format. Either \code{"vector"}
#'   for a named character vector of hex colors, or \code{"table"} for a
#'   \code{data.table} with columns \code{tag} and \code{colour}. Default is
#'   \code{"vector"}.
#'
#' @return A named character vector of hex color codes if 
#'  \code{option = "vector"}, or a \code{data.table} with two columns
#'  (\code{tag}, \code{colour}) if
#'   \code{option = "table"}.
#'
#' @examples
#' # Default output (named vector)
#' atl_tag_cols(c("1234", "2121", "9999"))
#'
#' # Output as a data.table
#' atl_tag_cols(c("1234", "2121", "9999"), option = "table")
#'
#' @importFrom scales hue_pal
#' @export
atl_tag_cols <- function(tags, option = "vector") {
  # ensure valid input
  match.arg(option, choices = c("vector", "table"))
  
  # convert to character in case tags are numeric
  tags <- as.character(unique(tags))
  
  # generate ggplot2-like colours using hue_pal
  n_tags <- length(tags)
  colours <- scales::hue_pal()(n_tags)
  
  tag_colours <- stats::setNames(colours, tags)
  
  # return selected format
  if (option == "vector") {
    return(tag_colours)
  } else {
    return(data.table::data.table(
      tag = names(tag_colours),
      colour = tag_colours
    ))
  }
}


#' Create unique labels for tags by combining specified columns
#'
#' Generates a named character vector of unique labels for each `tag` in the
#' data. The labels are created by concatenating the values of specified columns
#' for the first occurrence of each tag, using a user-defined separator.
#'
#' @param data A \code{data.table} or \code{data.frame} containing at least a
#' \code{tag} column.
#' @param columns A character vector specifying the names of columns to combine
#' into the label. These columns must exist in \code{data}.
#' @param sep A character string used to separate concatenated column values in
#' the label. Defaults to an space \code{" "}.
#'
#' @return A named character vector where the names are unique \code{tag} values
#' from the data, and the values are concatenated labels created from the
#' specified columns.
#'
#' @details
#' The function selects the first row for each unique \code{tag} to create the
#' label. If the \code{tag} column or any of the specified columns are missing,
#' the function will stop with an informative error message.
#'
#' @examples
#' library(data.table)
#' data <- data.table(
#'   tag = c("1234", "2222", "1234"),
#'   rings = c(123234442, 334234234, 123234442),
#'   name = c("Allert", "Peter", "Karl")
#' )
#' atl_tag_labs(data, c("rings", "name"), sep = " ")
#' 
#' @export
atl_tag_labs <- function(data, columns, sep = " ") {

  # Global variables to suppress notes in data.table
  tag <- label <- NULL
  
  # check data structure
  if (!("tag" %in% names(data))) {
    stop("Error: 'tag' column is missing from the data.")
  }
  if (!all(columns %in% names(data))) {
    missing_cols <- columns[!columns %in% names(data)]
    stop(paste(
      "Error: The following columns are missing from the data:",
      paste(missing_cols, collapse = ", ")
    ))
  }
  
  # select first row per tag to avoid duplicates
  labels <- data[, .SD[1], by = tag, .SDcols = c("tag", columns)]
  
  # Replace NA with "" in the specified columns before pasting
  labels[, (columns) := lapply(.SD, function(x) {
    x[is.na(x)] <- ""
    return(x)
  }), .SDcols = columns]
  
  # paste only the specified columns together with the separator
  labels[, label := do.call(
    paste, c(.SD[, columns, with = FALSE], list(sep = sep))
  )]
  
  # return named vector with tag as names and combined label as values
  return(stats::setNames(labels$label, labels$tag))
}

#' Format time in easy readable interval
#'
#' This function converts a given time (in seconds) into a easy readable format
#' with days, hours, minutes, or seconds.
#'
#' @author Johannes Krietsch
#' @param time Time in seconds (numeric or vector of numeric values).
#'
#' @returns A character vector with the formatted time intervals.
#' @export
#'
#' @examples
#' library(tools4watlas)
#' atl_format_time(3600)
#' atl_format_time(c(120, 3600, 86400))
atl_format_time <- function(time) {
  vapply(time, function(t) {
    dplyr::case_when(
      t >= 86400 ~ paste(round(t / 86400, 1), "days"), # more than 1 day
      t >= 3600 ~ paste(round(t / 3600, 1), "hours"),  # more than 1 hour
      t >= 60 ~ paste(round(t / 60, 1), "min"),        # more than 1 minute
      TRUE ~ paste(round(t, 1), "sec")                 # less than 1 minute
    )
  }, character(1))
}

#' Make a colour transparent
#'
#' A function that will make the provided colour transparent.
#'
#' @author Allert Bijleveld & Johannes Krietsch
#' @param color The colour to make transparent.
#' @param percent The percentage of transparency to apply .
#' @param name The name argument as passed on to rgb.
#' @return The transparent colour will be returned.
#' @importFrom grDevices col2rgb rgb
#' @examples
#' # Example with 50% transparency
#' colour_with_alpha <- atl_t_col("blue", percent = 50)
#' print(colour_with_alpha)
#'
#' plot(1, 1,
#'   col = colour_with_alpha, pch = 16, cex = 20,
#'   xlab = "X", ylab = "Y", main = "Point with Transparent Colour"
#' )
#'
#' # Example with 30% transparency
#' colour_with_alpha <- atl_t_col("red", percent = 90)
#' print(colour_with_alpha)
#'
#' plot(1, 1,
#'   col = color_with_alpha, pch = 16, cex = 20,
#'   xlab = "X", ylab = "Y", main = "Point with Transparent Colour"
#' )
#' @export
atl_t_col <- function(color, percent = 50, name = NULL) {
  # Validate color input
  if (!is.character(color) || length(color) != 1) {
    stop("The 'color' parameter should be a single character string.",
      call. = FALSE
    )
  }

  # Convert the color to RGB
  rgb_val <- col2rgb(color)

  # Validate percent input
  if (!is.numeric(percent) || percent < 0 || percent > 100) {
    stop("The 'percent' parameter should be a numeric value between 0 and 100.",
      call. = FALSE
    )
  }

  # Calculate the alpha transparency
  alpha_val <- (100 - percent) * 255 / 100

  # Return the color with adjusted transparency (alpha)
  rgb(rgb_val[1, ], rgb_val[2, ], rgb_val[3, ],
    maxColorValue = 255, alpha = alpha_val,
    names = name
  )
}
