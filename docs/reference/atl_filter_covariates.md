# Filter data by position covariates

The atlastools function `atl_filter_covariates` allows convenient
filtering of a dataset by any number of logical filters. This function
can be used to easily filter timestamps in a range, as well as combine
simple spatial and temporal filters. It accepts a character vector of
`R` expressions that each return a logical vector (i.e. `TRUE` or
`FALSE`). Each filtering condition is interpreted in the context of the
dataset supplied, and used to filter for rows that satisfy each of the
filter conditions. Users must make sure that the filtering variables
exist in their dataset in order to avoid errors.

## Usage

``` r
atl_filter_covariates(data, filters = c(), quietly = FALSE)
```

## Arguments

- data:

  A `data.table` or similar containing the variables to be filtered.

- filters:

  A character vector of filter expressions. An example might be
  `"speed < 20"`. The filtering variables must be in the `data.table`.
  The function will not explicitly check whether the filtering variables
  are present; this makes it flexible, allowing expressions such as
  `"between(speed, 2, 20)"`, but also something to use at your own risk.
  A missing filter variables *will* result in an empty data frame.

- quietly:

  If `TRUE` returns percentage and number of positions filtered, if
  `FALSE` functions runs quietly

## Value

A dataframe filtered using the filters specified.

## Details

Derived from `atlastools::atl_filter_covariates()` in the atlastools
package (Gupte et al., 2022), licensed under GPL-3.

## References

Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
287-307.
[doi:10.1111/1365-2656.13610](https://doi.org/10.1111/1365-2656.13610)

## Author

Pratik R. Gupte and Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)

# load example data
data <- data_example

# filter data at night
# extract hour of the day
data[, hour := as.integer(format(datetime, "%H"))]
#> Index: <tag>
#>           species posID    tag       time            datetime        x       y
#>            <char> <int> <char>      <num>              <POSc>    <num>   <num>
#>     1:   redshank     2   3027 1695438805 2023-09-23 03:13:25 650705.6 5902556
#>     2:   redshank     3   3027 1695438808 2023-09-23 03:13:28 650705.6 5902556
#>     3:   redshank     4   3027 1695439189 2023-09-23 03:19:49 650721.0 5902559
#>     4:   redshank     5   3027 1695439192 2023-09-23 03:19:52 650721.1 5902559
#>     5:   redshank     6   3027 1695439195 2023-09-23 03:19:55 650723.1 5902564
#>    ---                                                                        
#> 84411: sanderling  8126   3288 1695513564 2023-09-23 23:59:24 650178.5 5902404
#> 84412: sanderling  8127   3288 1695513570 2023-09-23 23:59:30 650178.5 5902404
#> 84413: sanderling  8128   3288 1695513576 2023-09-23 23:59:36 650178.5 5902404
#> 84414: sanderling  8129   3288 1695513582 2023-09-23 23:59:42 650178.2 5902403
#> 84415: sanderling  8130   3288 1695513588 2023-09-23 23:59:48 650177.5 5902403
#>          nbs      varx       vary      covxy    speed_in  speed_out    x_raw
#>        <int>     <num>      <num>      <num>       <num>      <num>    <num>
#>     1:     3 49.090805 460.836304 141.214539 0.000000000 0.00000000 650705.6
#>     2:     3 58.183502 471.808105 155.888260 0.000000000 0.04132607 650691.6
#>     3:     3 49.968266 441.456970 138.204239 0.041326067 0.01412799 650728.6
#>     4:     3  5.342943  28.163733   8.582236 0.014127986 1.73816620 650721.0
#>     5:     3  5.548222  35.032780  10.426281 1.738166199 0.00000000 650721.1
#>    ---                                                                      
#> 84411:     3 19.730513  12.872843  -1.360448 0.008866944 0.00000000 650184.0
#> 84412:     3 12.930080   4.513436   1.932977 0.000000000 0.00000000 650178.5
#> 84413:     3 20.655415  10.068294   5.556414 0.000000000 0.17174318 650179.7
#> 84414:     3 26.344803  17.227232   6.836256 0.171743185 0.11173205 650178.2
#> 84415:     3 26.837191  13.242077   7.571170 0.111732046 0.11966308 650177.5
#>          y_raw  tideID tidaltime time2lowtide waterlevel bathymetry  hour
#>          <num>   <int>     <num>        <num>      <num>      <num> <int>
#>     1: 5902576 2023513  133.4210    -246.5790       49.9   84.29087     3
#>     2: 5902536 2023513  133.4710    -246.5290       49.9   84.29087     3
#>     3: 5902571 2023513  139.8205    -240.1795       45.0   86.83250     3
#>     4: 5902556 2023513  139.8705    -240.1295       45.0   86.83250     3
#>     5: 5902559 2023513  139.9205    -240.0795       45.0   86.83250     3
#>    ---                                                                   
#> 84411: 5902405 2023514  639.4034     269.4034       61.7   99.64340    23
#> 84412: 5902406 2023514  639.5034     269.5034       62.0   99.64340    23
#> 84413: 5902401 2023514  639.6034     269.6034       62.0   99.64340    23
#> 84414: 5902398 2023514  639.7033     269.7033       62.0   99.64340    23
#> 84415: 5902408 2023514  639.8033     269.8033       62.0   99.64340    23

night_data <- atl_filter_covariates(
  data = data,
  filters = c("!inrange(hour, 6, 18)")
)
#> Note: 66.3% of the dataset was filtered out, corresponding to 55969 positions.

# filter on the variance of the estimated x- and y-coordinates
var_max <- 5000 # in meters squared

data_filtered <- atl_filter_covariates(
  data = data,
  filters = c(
    sprintf("varx < %s", var_max),
    sprintf("vary < %s", var_max)
  )
)
#> Note: 0% of the dataset was filtered out, corresponding to 0 positions.

# filter by speed
speed_max <- 35 # m/s (126 km/h)

data <- atl_filter_covariates(
  data = data,
  filters = c(
    sprintf("speed_in < %s | is.na(speed_in)", speed_max),
    sprintf("speed_out < %s | is.na(speed_out)", speed_max)
  )
)
#> Note: 0% of the dataset was filtered out, corresponding to 0 positions.
```
