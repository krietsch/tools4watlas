% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_simple_distance.R
\name{atl_simple_dist}
\alias{atl_simple_dist}
\title{Calculate distances between successive localizations}
\usage{
atl_simple_dist(data, x = "x", y = "y", lag = 1)
}
\arguments{
\item{data}{A dataframe object of or extending the class data.frame,
which must contain two coordinate columns for the X and Y coordinates.}

\item{x}{A column name in a data.frame object that contains the numeric X
coordinate.}

\item{y}{A column name in a data.frame object that contains the numeric Y
coordinate.}

\item{lag}{The lag (in number of localizations) over which to calculate
distance}
}
\value{
Returns a vector of distances between consecutive points.
}
\description{
Gets the euclidean distance between consecutive localization in a coordinate
reference system in metres, i.e., UTM systems.
}
\author{
Pratik R. Gupte & Allert Bijleveld
}
