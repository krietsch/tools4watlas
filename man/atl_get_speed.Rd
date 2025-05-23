% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_get_speed.R
\name{atl_get_speed}
\alias{atl_get_speed}
\title{Calculate instantaneous speed}
\usage{
atl_get_speed(
  data,
  tag = "tag",
  x = "x",
  y = "y",
  time = "time",
  type = c("in", "out")
)
}
\arguments{
\item{data}{A dataframe or similar which must have the columns
specified by \code{x}, \code{y}, and \code{time}.}

\item{tag}{The tag ID.}

\item{x}{The x coordinate.}

\item{y}{The y coordinate.}

\item{time}{The timestamp in seconds since the UNIX epoch.}

\item{type}{The type of speed (incoming or outgoing) to return.
Incoming speeds are specified by \code{type = "in"}, and outgoing speeds
by \code{type = "out"} or both c("in", "out").}
}
\value{
Data.table changed in place with additional speed columns
}
\description{
Returns additional columns for incoming and outcoming speed to the
data.table. Speed in metres per time interval. The time interval is dependent
on the units of the column specified in \code{TIME}.
}
\examples{
library(tools4watlas)
library(data.table)

# Create example data with two tags
set.seed(123)
data <- data.table(
  tag = rep(c("1000", "2000"), each = 5),
  x = c(1, 3, 6, 10, 15, 2, 4, 7, 11, 16),
  y = c(2, 5, 9, 14, 20, 3, 6, 10, 15, 21)
)

# Add a Unix timestamp column (randomized within a date range)
start_time <- as.numeric(as.POSIXct("2024-01-01 00:00:00", tz = "UTC"))
data[, time := start_time + sample(0:10000, .N, replace = TRUE)]


data <- atl_get_speed(data,
  tag = "tag",
  x = "x",
  y = "y",
  time = "time",
  type = c("in", "out")
)
}
\author{
Pratik R. Gupte & Allert Bijleveld & Johannes Krietsch
}
