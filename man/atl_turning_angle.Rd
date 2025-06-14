% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_turning_angle.R
\name{atl_turning_angle}
\alias{atl_turning_angle}
\title{Get the turning angle between points}
\usage{
atl_turning_angle(data, tag = "tag", x = "x", y = "y", time = "time")
}
\arguments{
\item{data}{A dataframe or similar which must have the columns
specified by \code{x}, \code{y}, and \code{time}.}

\item{tag}{The tag ID.}

\item{x}{The x coordinate.}

\item{y}{The y coordinate.}

\item{time}{The timestamp in seconds since the UNIX epoch.}
}
\value{
A a data.table with added turning angles in degrees.
Negative degrees indicate 'left' turns. There are two fewer
angles than the number of rows in the dataframe.
}
\description{
Gets the relative heading between two track segments (three localizations)
using the law of cosines.
The turning angle is returned in degrees.
Adds the column \code{angle} to a data.table with tracking data.
Note that with smoothed data NaN values may occur (when subsequent
localizations are at the same place).
}
\examples{
\dontrun{
data <- atl_turning_angle(
  data,
  tag = "tag", x = "x", y = "y", time = "time"
)
}
}
\author{
Pratik R. Gupte & Allert Bijleveld & Johannes Krietsch
}
