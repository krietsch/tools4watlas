# Add sun and moon data

This article shows how to add sun and moon data using the `suncalc`
package. We show how to add sunrise and sunset times to split the data
between day and night, and how to add the moon phase to assign days
around full and new moon. This can be useful for example to investigate
whether birds behave differently during day and night or during
different moon phases, which are closely linked to the strength of the
tides.

**Before you start:** this article assumes you have completed the basic
WATLAS data processing, i.e. you have [loaded and checked your
data](https://allertbijleveld.github.io/tools4watlas/articles/load_and_check_data.html),
[filtered
it](https://allertbijleveld.github.io/tools4watlas/articles/filter_data.html),
and [smoothed and thinned
it](https://allertbijleveld.github.io/tools4watlas/articles/smooth_and_thin_data.html).

## Load packages and data

``` r

# packages
library(tools4watlas)
library(suncalc)

# load example data
data <- data_example
```

## Add sunrise and sunset data

We first need to add the coordinates in WGS 84 (EPSG:4326) to be able to
calculate sunrise and sunset times. Then, we use the
[`getSunlightTimes()`](https://rdrr.io/pkg/suncalc/man/getSunlightTimes.html)
function to calculate sunrise and sunset times for each position.
Finally, we assign day and night based on whether the timestamp of a
position falls between sunrise and sunset. The function also offers many
more options, see
[`getSunlightTimes()`](https://rdrr.io/pkg/suncalc/man/getSunlightTimes.html)
documentation for more details.

``` r

# add transformed coordinates in EPSG:4326 (WGS 84)
data <- atl_transform_dt(data, to = sf::st_crs(4326))

# add sunrise/sunset times
data[, c("sunrise", "sunset") := getSunlightTimes(
  data = data.table(date = as.Date(datetime), lat = y_4326, lon = x_4326),
  keep = c("sunrise", "sunset"),
  tz   = "UTC"
)[, c("sunrise", "sunset")]]

# assign day and night
data[, day_night := fifelse(
  datetime >= sunrise & datetime < sunset, "day", "night"
)]

# show head of the table
head(data[, .(tag, datetime, sunrise, sunset, day_night)]) |>
  knitr::kable(digits = 2)
```

| tag  | datetime            | sunrise             | sunset              | day_night |
|:-----|:--------------------|:--------------------|:--------------------|:----------|
| 3027 | 2023-09-23 03:13:25 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |
| 3027 | 2023-09-23 03:13:28 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |
| 3027 | 2023-09-23 03:19:49 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |
| 3027 | 2023-09-23 03:19:52 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |
| 3027 | 2023-09-23 03:19:55 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |
| 3027 | 2023-09-23 03:19:58 | 2023-09-23 05:26:50 | 2023-09-23 17:38:51 | night     |

## Add moon phase data

We use the
[`getMoonIllumination()`](https://rdrr.io/pkg/suncalc/man/getMoonIllumination.html)
function to calculate the moon phase for each timestamp. The moon phase
is a value between 0 and 1, where 0 = new moon, 0.25 = first quarter,
0.5 = full moon, and 0.75 = last quarter. We then calculate the time to
the next full moon and new moon in days, which can be useful to assign
days around full and new moon.

``` r

# add moon phase per datetime
# 0 = new, 0.25 = first quarter, 0.5 = full, 0.75 = last quarter
data[, c("moon_phase") := getMoonIllumination(
  date = datetime,
  keep = c("phase")
)[, c("phase")]]

# add time to full moon (phase = 0.5) and new moon (phase = 0)
# Moon cycle = 29.53 days, negative = before full or new moon
data[, time2fullmoon := (moon_phase - 0.5) * 29.53]
data[, time2newmoon := fifelse(
  moon_phase <= 0.5,
  moon_phase * 29.53,
  (moon_phase - 1) * 29.53
)]

# assign 3 days around full and new moon
data[, near_lunar_extreme := abs(time2fullmoon) <= 3 | abs(time2newmoon) <= 3]

# show head of the table
head(data[, .(
  tag, datetime, moon_phase, time2fullmoon, time2newmoon, near_lunar_extreme
)]) |>
  knitr::kable(digits = 2)
```

| tag | datetime | moon_phase | time2fullmoon | time2newmoon | near_lunar_extreme |
|:---|:---|---:|---:|---:|:---|
| 3027 | 2023-09-23 03:13:25 | 0.27 | -6.88 | 7.88 | FALSE |
| 3027 | 2023-09-23 03:13:28 | 0.27 | -6.88 | 7.88 | FALSE |
| 3027 | 2023-09-23 03:19:49 | 0.27 | -6.88 | 7.89 | FALSE |
| 3027 | 2023-09-23 03:19:52 | 0.27 | -6.88 | 7.89 | FALSE |
| 3027 | 2023-09-23 03:19:55 | 0.27 | -6.88 | 7.89 | FALSE |
| 3027 | 2023-09-23 03:19:58 | 0.27 | -6.88 | 7.89 | FALSE |
