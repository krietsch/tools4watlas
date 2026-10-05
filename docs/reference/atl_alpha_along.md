# Creates different alpha values along a vector

Copied from https://github.com/ornitho-logics/windR

## Usage

``` r
atl_alpha_along(x, head = 20, skew = -2)
```

## Arguments

- x:

  Vector along which alpha is created

- head:

  Numeric parameter influencing the length of the head

- skew:

  Numeric parameter influencing the skew of alpha

## Value

Numeric vector with different alpha values

## Author

Mihai Valcu & Johannes Krietsch

## Examples

``` r
library(ggplot2)
d <- data.frame(
  x = 1:100, y = 1:100,
  a = atl_alpha_along(1:100, head = 20, skew = -2)
)
bm <- ggplot(d, aes(x, y))
bm + geom_path(linewidth = 10)

bm + geom_path(linewidth = 10, alpha = d$a, lineend = "round")
```
