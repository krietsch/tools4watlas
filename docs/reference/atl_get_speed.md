# Calculate instantaneous speed

Returns additional columns for incoming and outgoing speed to the
data.table. Speed in metres per time interval. The time interval is
dependent on the units of the column specified in `time`.

## Usage

``` r
atl_get_speed(
  data,
  tag = "tag",
  x = "x",
  y = "y",
  time = "time",
  type = c("in", "out")
)
```

## Arguments

- data:

  A dataframe or similar which must have the columns specified by `x`,
  `y`, and `time`.

- tag:

  The tag ID.

- x:

  The x coordinate.

- y:

  The y coordinate.

- time:

  The timestamp in seconds since the UNIX epoch.

- type:

  The type of speed (incoming or outgoing) to return. Incoming speeds
  are specified by `type = "in"`, and outgoing speeds by `type = "out"`
  or both c("in", "out").

## Value

Data.table changed in place with additional speed columns

## Details

Derived from `atlastools::atl_get_speed()` in the atlastools package
(Gupte et al., 2022), licensed under GPL-3.

## References

Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
287-307.
[doi:10.1111/1365-2656.13610](https://doi.org/10.1111/1365-2656.13610)

## Author

Pratik R. Gupte, Allert Bijleveld & Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)

# load example data
data <- data_example

# remove speed columns
data[, c("speed_in", "speed_out") := NULL]
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
#>          nbs      varx       vary      covxy    x_raw   y_raw  tideID tidaltime
#>        <int>     <num>      <num>      <num>    <num>   <num>   <int>     <num>
#>     1:     3 49.090805 460.836304 141.214539 650705.6 5902576 2023513  133.4210
#>     2:     3 58.183502 471.808105 155.888260 650691.6 5902536 2023513  133.4710
#>     3:     3 49.968266 441.456970 138.204239 650728.6 5902571 2023513  139.8205
#>     4:     3  5.342943  28.163733   8.582236 650721.0 5902556 2023513  139.8705
#>     5:     3  5.548222  35.032780  10.426281 650721.1 5902559 2023513  139.9205
#>    ---                                                                         
#> 84411:     3 19.730513  12.872843  -1.360448 650184.0 5902405 2023514  639.4034
#> 84412:     3 12.930080   4.513436   1.932977 650178.5 5902406 2023514  639.5034
#> 84413:     3 20.655415  10.068294   5.556414 650179.7 5902401 2023514  639.6034
#> 84414:     3 26.344803  17.227232   6.836256 650178.2 5902398 2023514  639.7033
#> 84415:     3 26.837191  13.242077   7.571170 650177.5 5902408 2023514  639.8033
#>        time2lowtide waterlevel bathymetry
#>               <num>      <num>      <num>
#>     1:    -246.5790       49.9   84.29087
#>     2:    -246.5290       49.9   84.29087
#>     3:    -240.1795       45.0   86.83250
#>     4:    -240.1295       45.0   86.83250
#>     5:    -240.0795       45.0   86.83250
#>    ---                                   
#> 84411:     269.4034       61.7   99.64340
#> 84412:     269.5034       62.0   99.64340
#> 84413:     269.6034       62.0   99.64340
#> 84414:     269.7033       62.0   99.64340
#> 84415:     269.8033       62.0   99.64340

# calculate speed
data <- atl_get_speed(data,
                      tag = "tag",
                      x = "x",
                      y = "y",
                      time = "time",
                      type = c("in", "out")
)

# check data
data[, .(tag, datetime, x, y, speed_in, speed_out)]
#>           tag            datetime        x       y    speed_in  speed_out
#>        <char>              <POSc>    <num>   <num>       <num>      <num>
#>     1:   3027 2023-09-23 03:13:25 650705.6 5902556          NA 0.00000000
#>     2:   3027 2023-09-23 03:13:28 650705.6 5902556 0.000000000 0.04132607
#>     3:   3027 2023-09-23 03:19:49 650721.0 5902559 0.041326067 0.01412799
#>     4:   3027 2023-09-23 03:19:52 650721.1 5902559 0.014127986 1.73816620
#>     5:   3027 2023-09-23 03:19:55 650723.1 5902564 1.738166199 0.00000000
#>    ---                                                                   
#> 84411:   3288 2023-09-23 23:59:24 650178.5 5902404 0.008866944 0.00000000
#> 84412:   3288 2023-09-23 23:59:30 650178.5 5902404 0.000000000 0.00000000
#> 84413:   3288 2023-09-23 23:59:36 650178.5 5902404 0.000000000 0.17174318
#> 84414:   3288 2023-09-23 23:59:42 650178.2 5902403 0.171743185 0.11173205
#> 84415:   3288 2023-09-23 23:59:48 650177.5 5902403 0.111732046         NA
```
