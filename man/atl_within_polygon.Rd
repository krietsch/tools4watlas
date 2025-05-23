% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_within_polygon.r
\name{atl_within_polygon}
\alias{atl_within_polygon}
\title{Detect position intersections with a polygon}
\usage{
atl_within_polygon(data, x = "x", y = "y", polygon)
}
\arguments{
\item{data}{A dataframe or similar containg at least X and Y coordinates.}

\item{x}{The name of the X coordinate, assumed by default to be "x".}

\item{y}{The Y coordinate as above, default "y".}

\item{polygon}{An \code{sfc_*POLYGON} object which must have a defined CRS.
The polygon CRS is assumed to be appropriate for the positions as well, and
is assigned to the coordinates when determining the intersection.}
}
\value{
Row numbers of positions which are inside the polygon.
}
\description{
Detects which positions intersect a \code{sfc_*POLYGON}. Tested
only for single polygon objects.
}
