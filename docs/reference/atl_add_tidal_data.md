# Add tidal data to tracking data

Adds a unique tide identifier, water level, time from high tide and time
to low tide for tracking data (both in minutes).

## Usage

``` r
atl_add_tidal_data(
  data,
  tide_data,
  tide_data_highres,
  waterdata_resolution = "10 min",
  waterdata_interpolation = NULL,
  offset = 0
)
```

## Arguments

- data:

  A dataframe with the tracking data with the timestamp column
  'datetime' in UTC.

- tide_data:

  Data on the timing (in UTC) of low and high tides.

- tide_data_highres:

  Data on the timing (in UTC) of the water level in small intervals
  (e.g. every 10 min) as provided from Rijkswaterstaat.

- waterdata_resolution:

  The resolution of the high resolution water level data. This is used
  for matching the high resolution tidal data to the tracking data.
  Defaults to 10 minutes but can be set differently.

- waterdata_interpolation:

  Time interval to which the water level data will be interpolated
  (should be smaller than water data resolution e.g. 1 min). If NULL
  will keep the original water data resolution.

- offset:

  The offset in minutes between the location of the tidal gauge and the
  tracking area. This value will be added to the timing of the water
  data.

## Value

The input data but with three columns added: tideID (a unique number for
the tidal period between two consecutive high tides), tidaltime (time
since high tide in minutes), time2lowtide (time to low tide in minutes),
and water level with reference to NAP (cm).

## Author

Pratik Gupte & Allert Bijleveld & Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)

# load example data
data <- data_example

# delete existing tide data columns to show how they are added
data[, c("tideID", "tidaltime", "time2lowtide", "waterlevel") := NULL]
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
#>          y_raw bathymetry
#>          <num>      <num>
#>     1: 5902576   84.29087
#>     2: 5902536   84.29087
#>     3: 5902571   86.83250
#>     4: 5902556   86.83250
#>     5: 5902559   86.83250
#>    ---                   
#> 84411: 5902405   99.64340
#> 84412: 5902406   99.64340
#> 84413: 5902401   99.64340
#> 84414: 5902398   99.64340
#> 84415: 5902408   99.64340

# sub path to tide data
tidal_pattern_fp <- system.file(
  "extdata", "example-tidalPattern-west_terschelling-UTC.csv",
  package = "tools4watlas"
)
measured_water_height_fp <- system.file(
  "extdata", "example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv",
  package = "tools4watlas"
)

# load tide data
tidal_pattern <- fread(tidal_pattern_fp)
measured_water_height <- fread(measured_water_height_fp)

# add tide data to movement data
# The offset of 30 minutes is set to match Griend.
data <- atl_add_tidal_data(
  data = data,
  tide_data = tidal_pattern,
  tide_data_highres = measured_water_height,
  waterdata_resolution = "10 min",
  waterdata_interpolation = "1 min",
  offset = 30
)

# show first 5 rows (subset of columns to show additional ones)
head(data[, .(tag, datetime, tideID, tidaltime, time2lowtide, waterlevel)])
#>       tag            datetime  tideID tidaltime time2lowtide waterlevel
#>    <char>              <POSc>   <int>     <num>        <num>      <num>
#> 1:   3027 2023-09-23 03:13:25 2023513  133.4210    -246.5790       49.9
#> 2:   3027 2023-09-23 03:13:28 2023513  133.4710    -246.5290       49.9
#> 3:   3027 2023-09-23 03:19:49 2023513  139.8205    -240.1795       45.0
#> 4:   3027 2023-09-23 03:19:52 2023513  139.8705    -240.1295       45.0
#> 5:   3027 2023-09-23 03:19:55 2023513  139.9205    -240.0795       45.0
#> 6:   3027 2023-09-23 03:19:58 2023513  139.9705    -240.0295       45.0
```
