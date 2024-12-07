% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_as_sf.R
\name{atl_as_sf}
\alias{atl_as_sf}
\title{Convert a data.frame or data.table to an simple feature (sf) object}
\usage{
atl_as_sf(
  data,
  x = "x",
  y = "y",
  projection = sf::st_crs(32631),
  additional_cols = NULL
)
}
\arguments{
\item{data}{A \code{data.table} or an object convertible to a \code{data.table}.
The input data containing the coordinates and optional attributes.}

\item{x}{A character string representing the name of the column containing
x-coordinates. Defaults to "x".}

\item{y}{A character string representing the name of the column containing
y-coordinates. Defaults to "y".}

\item{projection}{An object of class \code{crs} representing the coordinate
reference system (CRS) to assign to the resulting sf object. Defaults to
EPSG:32631 (WGS 84 / UTM zone 31N).}

\item{additional_cols}{A character vector specifying additional column names
to include in the resulting sf object. Defaults to \code{NULL} (no additional
columns included).}
}
\value{
An \code{sf} object containing the specified coordinates as geometry and
any included attributes.
}
\description{
This function converts a data.frame or data.table to a simple feature (sf)
object, allowing flexible specification of the x and y coordinate columns.
Additional attributes can also be retained in the resulting sf object.
}
\examples{
library(data.table)

# Example usage when column names are "x" and "y"
data <- data.table(x = c(1, 2, NA, 4), 
                   y = c(5, 6, 7, 8), 
                   value = c(9, 10, 11, 12), 
                   category = c("A", "B", "C", "D"))

# Add the "value" and "category" columns to the sf object
d_sf <- atl_as_sf(data, additional_cols = c("value", "category"))
print(d_sf)

# Example usage when column names are "lon" and "lat"
data2 <- data.table(lon = c(10, 20, 30, NA), lat = c(40, 50, 60, 70))
d_sf2 <- atl_as_sf(data2, "lon", "lat")
print(d_sf2)
}
\author{
Johannes Krietsch
}
