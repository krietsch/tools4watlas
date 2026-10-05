# Compare residence patches between two parameter sets

`atl_compare_res_patch_parm` identifies how residence patches change
when `atl_res_patch` is run with different parameters on the same
tracking data. The function compares patch assignments fix-by-fix and
classifies changes into four categories: (1) patches that are lost
(existed in v1 but not in v2), (2) patches that are gained (new in v2,
absent in v1), (3) splits (one v1 patch becomes multiple v2 patches),
and (4) merges (multiple v1 patches collapse into one v2 patch). Note
that simple renumbering of patches due to an upstream split is not
considered a true change, as the fix membership of those patches remains
identical.

## Usage

``` r
atl_compare_res_patch_summary(data_v1, data_v2, quietly = FALSE)
```

## Arguments

- data_v1:

  A data.table with residence patches assigned using the first parameter
  set. Must contain the columns `posID`, `tag`, `tideID`, `datetime`,
  `x`, `y`, and `patch`. Data must be ordered by tag and time and can
  contain multiple tags.

- data_v2:

  A data.table with residence patches assigned using the second
  parameter set. Must have the same structure and row order as
  `data_v1`, as patch columns are compared position-by-position.

- quietly:

  Logical. If `TRUE`, no summary messages are printed. Default is
  `FALSE`.

## Value

A data.table summarising all detected patch changes with columns `tag`,
`tideID`, `change` (one of `"lost"`, `"gained"`, `"split"`, or
`"merge"`), `patch_v1`, and `patch_v2`. For merges, `patch_v1` contains
a comma-separated list of the v1 patch IDs that merged. For splits,
`patch_v2` contains a comma-separated list of the resulting v2 patch
IDs. The function also prints a summary of the number of changes per
category.

## Author

Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)

# load example data
data <- data_example

# run atl_res_patch with two different parameter sets
data_v1 <- atl_res_patch(
  data[tag == "3038"],
  max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
  min_fixes = 2, min_duration = 60
)
data_v2 <- atl_res_patch(
  data[tag == "3038"],
  max_speed = 5, lim_spat_indep = 75, lim_time_indep = 180,
  min_fixes = 2, min_duration = 60
)

# change summary
atl_compare_res_patch_summary(data_v1, data_v2)
#> === Patch changes summary ===
#> Lost    (v1 patches gone in v2) : 0 
#> Gained  (new patches in v2)     : 0 
#> 
#> Splits  (one v1 -> multiple v2): 0 
#> Merges  (multiple v1 -> one v2): 1 
#> 
#>       tag  tideID change patch_v1 patch_v2
#>    <char>   <int> <char>   <char>   <char>
#> 1:   3038 2023513  merge   13, 14       13
```
