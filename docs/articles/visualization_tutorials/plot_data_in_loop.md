# Plot data in loop

This article shows how to make and save plots in a loop using a
single-core as well as with parallel computing using the package
[`foreach`](https://allertbijleveld.github.io/tools4watlas/articles/visualization_tutorials/)
and
[`doFuture`](https://allertbijleveld.github.io/tools4watlas/articles/visualization_tutorials/).
This is convenient for checking the quality of many tags by flicking
though them.

## Load packages

``` r

# packages
library(tools4watlas)
library(ggplot2)
library(foreach)
library(doFuture)
```

## Loop by tag ID

Example of a simple loop by tag ID and using
[`atl_check_tag()`](https://allertbijleveld.github.io/tools4watlas/reference/atl_check_tag.md).

``` r

# load example data
data <- data_example

# file path
path <- "./outputs/maps_by_tag/tag_"

# unique ID (here by tag)
id <- unique(data$tag)

# loop to make plots for all
foreach(i = id) %do% {

  # subset data
  data_subset <- data[tag == i]

  # plot and save data
  atl_check_tag(
    data_subset,
    option = "datetime",
    highlight_first = TRUE, highlight_last = TRUE,
    filename = paste0(path, data_subset[1]$species, "_tag_", i)
  )

}
```

Example to make any type of `ggplot` and save the data with `ragg`.

``` r

# load example data
data <- data_example

# file path
path <- "./outputs/maps_by_tag/tag_"

# unique ID (here by tag)
id <- unique(data$tag)

# loop to make plots for all
foreach(i = id) %do% {

  # subset data
  data_subset <- data[tag == i]

  # plot data
  p <- ggplot()

  # save
  agg_png(
    filename = paste0(path, i, ".png"),
    width = 3840, height = 2160, units = "px", res = 300
  )
  print(p)
  dev.off()

}
```

## Parallel loop by tag ID

For computing efficiency, we can use parallel computing. We use the same
structure, but only replacing `%do%` with `%dofuture%`, which is the key
advantage of using `foreach.` The only additional step is setting up
parallel processing with
[`registerDoFuture()`](https://doFuture.futureverse.org/reference/registerDoFuture.html)
and `plan(multisession)`.

``` r

# load example data
data <- data_example

# file path
path <- "./outputs/maps_by_tag/"

# unique ID (here by tag)
id <- unique(data$tag)

# register cores and backend for parallel processing
registerDoFuture()
plan(multisession)

# loop to make plots for all
foreach(i = id) %dofuture% {

  # subset data
  data_subset <- data[tag == i]

  # plot and save data
  atl_check_tag(
    data_subset,
    option = "datetime",
    highlight_first = TRUE, highlight_last = TRUE,
    filename = paste0(path, data_subset[1]$species, "_tag_", i)
  )

}

# close parallel workers
plan(sequential)
```

## Plot and save data in parallel loop by tag ID and tide ID

``` r

# load example data
data <- data_example

# file path
path <- "./outputs/maps_by_tag_and_tide/"

# unique ID combinations
idc <- unique(data[, c("species", "tag", "tideID")])

# register cores and backend for parallel processing
registerDoFuture()
plan(multisession)

# loop to make plots for all
foreach(i = seq_len(nrow(idc))) %dofuture% {

  # subset data
  data_subset <- data[tag == idc$tag[i] & tideID == idc$tideID[i]]

  # plot and save data
  atl_check_tag(
    data_subset,
    option = "datetime",
    highlight_first = TRUE, highlight_last = TRUE,
    filename = paste0(
      path, idc$species[i], "_tag_", idc$tag[i], "_tide_", idc$tideID[i]
    )
  )

}

# close parallel workers
plan(sequential)
```
