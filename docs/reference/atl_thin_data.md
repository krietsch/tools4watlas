# Thin tracking data by resampling or aggregation

Uniformly reduce data volumes with either aggregation or resampling
(specified by the `method` argument) over an interval specified in
seconds using the `interval` argument. Both options make two important
assumptions: (1) that timestamps are named 'time' and 'datetime', and
(2) all columns except the identity columns can be averaged in `R`.
While the 'subsample' option returns a thinned dataset with all columns
from the input data, the 'aggregate' option drops the column `covxy`,
since this cannot be propagated to the averaged position. Both options
handle the column 'time' differently: while 'subsample' returns the
actual timestamp (in UNIX time) of each sample, 'aggregate' returns the
mean timestamp (also in UNIX time). The 'aggregate' option only
recognises errors named `varx` and `vary`. If all of these columns are
not present together the function assumes there is no measure of error,
and drops those columns. If there is actually no measure of error, the
function simply returns the averaged position and covariates in each
time interval. Grouping variables' names (such as animal identity) may
be passed as a character vector to the `id_columns` argument. If `patch`
is among the columns and the data are aggregated, only if the first and
last point of the aggregation interval are from the same patch, this
position will be assigned to the patch. With thinning the patch ID stays
as it is for this position.

## Usage

``` r
atl_thin_data(
  data,
  interval = 60,
  id_columns = NULL,
  method = c("subsample", "aggregate")
)
```

## Arguments

- data:

  Tracking data to aggregate. Must have columns `x` and `y`, and a
  numeric column named `time`, as well as `datetime`.

- interval:

  The interval in seconds over which to aggregate.

- id_columns:

  Column names for grouping columns.

- method:

  Should the data be thinned by subsampling or aggregation. If
  resampling (`method = "subsample"`), the first position of each group
  is taken. If aggregation (`method = "aggregate"`), the group
  positions' mean is taken.

## Value

A data.table with aggregated or subsampled data.

## Details

Derived from `atlastools::atl_thin_data()` in the atlastools package
(Gupte et al., 2022), licensed under GPL-3.

## References

Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
287-307.
[doi:10.1111/1365-2656.13610](https://doi.org/10.1111/1365-2656.13610)

## Author

Pratik Gupte & Allert Bijleveld & Johannes Krietsch

## Examples

``` r
library(data.table)

data <- data.table(
  tag = as.character(rep(1:2, each = 10)),
  time = rep(seq(1696218721, 1696218721 + 92, by = 10), 2),
  x = rnorm(20, 10, 1),
  y = rnorm(20, 15, 1)
)

data[, datetime := as.POSIXct(time, origin = "1970-01-01", tz = "UTC")]
#>        tag       time         x        y            datetime
#>     <char>      <num>     <num>    <num>              <POSc>
#>  1:      1 1696218721  9.441985 15.96086 2023-10-02 03:52:01
#>  2:      1 1696218731 11.052539 15.76872 2023-10-02 03:52:11
#>  3:      1 1696218741 10.677684 16.03593 2023-10-02 03:52:21
#>  4:      1 1696218751 10.038500 14.52611 2023-10-02 03:52:31
#>  5:      1 1696218761  9.643619 13.72467 2023-10-02 03:52:41
#>  6:      1 1696218771 10.782844 14.69438 2023-10-02 03:52:51
#>  7:      1 1696218781 10.804412 17.21177 2023-10-02 03:53:01
#>  8:      1 1696218791  8.099939 13.95833 2023-10-02 03:53:11
#>  9:      1 1696218801 10.935784 13.85348 2023-10-02 03:53:21
#> 10:      1 1696218811  9.690948 13.32467 2023-10-02 03:53:31
#> 11:      2 1696218721 10.263067 16.52594 2023-10-02 03:52:01
#> 12:      2 1696218731  8.209408 15.55419 2023-10-02 03:52:11
#> 13:      2 1696218741  9.211741 16.99311 2023-10-02 03:52:21
#> 14:      2 1696218751  8.866978 14.84588 2023-10-02 03:52:31
#> 15:      2 1696218761 10.363653 17.56441 2023-10-02 03:52:41
#> 16:      2 1696218771  9.714112 16.06200 2023-10-02 03:52:51
#> 17:      2 1696218781 10.517669 16.14269 2023-10-02 03:53:01
#> 18:      2 1696218791  9.897091 16.12384 2023-10-02 03:53:11
#> 19:      2 1696218801  9.025930 14.60300 2023-10-02 03:53:21
#> 20:      2 1696218811 11.270672 14.17674 2023-10-02 03:53:31
#>        tag       time         x        y            datetime
#>     <char>      <num>     <num>    <num>              <POSc>

# Thin the data by aggregation with a 60-second interval
thinned_aggregated <- atl_thin_data(
  data = data,
  interval = 60,
  id_columns = "tag",
  method = "aggregate"
)

# Thin the data by subsampling with a 60-second interval
thinned_subsampled <- atl_thin_data(
  data = data,
  interval = 60,
  id_columns = "tag",
  method = "subsample"
)

# View results
print(thinned_aggregated)
#>       tag       time         x        y            datetime n_aggregated
#>    <char>      <num>     <num>    <num>              <POSc>        <int>
#> 1:      1 1696218720 10.272862 15.11845 2023-10-02 03:52:00            6
#> 2:      1 1696218780  9.882771 14.58706 2023-10-02 03:53:00            4
#> 3:      2 1696218720  9.438160 16.25759 2023-10-02 03:52:00            6
#> 4:      2 1696218780 10.177841 15.26157 2023-10-02 03:53:00            4
print(thinned_subsampled)
#>       tag       time         x        y            datetime n_subsampled
#>    <char>      <num>     <num>    <num>              <POSc>        <int>
#> 1:      1 1696218721  9.441985 15.96086 2023-10-02 03:52:01            6
#> 2:      1 1696218781 10.804412 17.21177 2023-10-02 03:53:01            4
#> 3:      2 1696218721 10.263067 16.52594 2023-10-02 03:52:01            6
#> 4:      2 1696218781 10.517669 16.14269 2023-10-02 03:53:01            4
```
