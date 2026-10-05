# Creates different size values along a vector

Copied from https://github.com/ornitho-logics/windR

## Usage

``` r
atl_size_along(x, head = 20, to = c(0.1, 2.5))
```

## Arguments

- x:

  Vector along which alpha is created

- head:

  Numeric parameter influencing the length of the head

- to:

  Numeric vector including the minimum and maximum size

## Value

Numeric vector with different size values

## Author

Mihai Valcu & Johannes Krietsch

## Examples

``` r
library(ggplot2)
d <- data.frame(
  x = 1:100, y = 1:100,
  s = atl_size_along(1:100, head = 70, to = c(0.1, 5))
)
bm <- ggplot(d, aes(x, y))
bm + geom_path(linewidth = 1)

bm + geom_path(linewidth = d$s, lineend = "round")
```
