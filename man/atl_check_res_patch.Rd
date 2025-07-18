% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_check_res_patch.R
\name{atl_check_res_patch}
\alias{atl_check_res_patch}
\title{Check the residency patches from one tag during one tide}
\usage{
atl_check_res_patch(
  data,
  tide_data,
  tide,
  offset = 0,
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
  filename = NULL,
  png_width = 3840,
  png_height = 2160
)
}
\arguments{
\item{data}{A \code{data.table} containing tracking data of one tag. Must include
the columns: \code{tag}, \code{x}, \code{y}, \code{time},\code{datetime}, and \code{species} and
\code{patch},  as created by \code{atl_res_patch()}.}

\item{tide_data}{Data on the timing (in UTC) of low and high tides.}

\item{tide}{Tide ID to subset.}

\item{offset}{The offset in minutes between the location of the tidal gauge
and the tracking area. This value will be added to the timing of the
water data.}

\item{buffer_res_patches}{A numeric value (in meters) specifying the buffer
around the polygon of each residency patch, which should be
half of \code{lim_spat_indep} of the residency patch calculation. If not
the function can create MULTIPOLGONS for single residency patches. That will
give a warning message, but works if desired.}

\item{buffer_bm}{Map buffer size (default: 250).}

\item{buffer_overview}{Overview map buffer size (default: 10000).}

\item{point_size}{Size of plotted points (default: 1).}

\item{point_alpha}{Transparency of points (default: 0.5).}

\item{path_linewidth}{Line width of movement paths (default: 0.5).}

\item{path_alpha}{Transparency of movement paths (default: 0.2).}

\item{patch_label_size}{Font size for patch labels (default: 4).}

\item{patch_label_padding}{Padding for patch labels (default: 1).}

\item{element_text_size}{Font size for axis and legend text (default: 11).}

\item{water_fill}{Water fill (default "#D7E7FF")}

\item{water_colour}{Water coulour (default "grey80")}

\item{land_fill}{Land fill (default "#faf5ef")}

\item{land_colour}{Land colour (default "grey80")}

\item{mudflat_colour}{Mudflat colour (default "#faf5ef")}

\item{mudflat_fill}{Mudflat fill (default "#faf5ef")}

\item{mudflat_alpha}{Mudflat alpha (default 0.6)}

\item{filename}{Character (or NULL). If provided, the plot is saved as a
\code{.png} file to this path and with this name; otherwise, the function
returns the plot.}

\item{png_width}{Width of saved PNG (default: 3840).}

\item{png_height}{Height of saved PNG (default: 2160).}
}
\value{
A ggplot object or a saved PNG file.
}
\description{
Generates a \code{ggplot2} showing bird residency patches per tideID, including
movement paths, patch durations, and an inset overview map.
}
\author{
Johannes Krietsch
}
