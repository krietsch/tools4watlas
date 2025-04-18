% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun_animate_data.R
\name{atl_alpha_along}
\alias{atl_alpha_along}
\title{Creates different alpha values along a vector}
\usage{
atl_alpha_along(x, head = 20, skew = -2)
}
\arguments{
\item{x}{Vector along which alpha is created}

\item{head}{Numeric parameter influencing the lenght of the head}

\item{skew}{Numeric parameter influencing the skew of alpha}
}
\value{
Numeric verctor with different alpha values
}
\description{
Copied from https://github.com/mpio-be/windR
}
\examples{
library(ggplot2)
d <- data.frame(
  x = 1:100, y = 1:100,
  a = atl_alpha_along(1:100, head = 20, skew = -2)
)
bm <- ggplot(d, aes(x, y))
bm + geom_path(linewidth = 10)
bm + geom_path(linewidth = 10, alpha = d$a, lineend = "round")
}
\author{
Mihai Valcu & Johannes Krietsch
}
