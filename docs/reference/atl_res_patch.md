# Construct residence patches from position data

A cleaned movement track of one individual at a time can be classified
into residence patches using the function `atl_res_patch`. The function
expects a specific organisation of the data: there should be at least
the following columns, `x`, `y`, and `time`, corresponding to the
coordinates, and the time as `POSIXct`. `atl_res_patch` requires only
three parameters: (1) the maximum speed threshold between localizations
(called `max_speed`), (2) the distance threshold between proto-patches
of positions (called `lim_spat_indep`), and (3) the time interval
between proto-patches (called `lim_time_indep`). As the code initially
only looks at proto-patches, at the end it checks if positions within
patches are interrupted by short flights (with a distance larger than
`lim_spat_indep` to the last position of the proto-patch before and
first position of the next proto-patch). If there are more than
`min_fixes` in this bout, then the patch will be split. If there are
less, we assume this to be single outliers and only assign no patch ID

## Usage

``` r
atl_res_patch(
  data,
  max_speed = 3,
  lim_spat_indep = 75,
  lim_time_indep = 180,
  min_fixes = 2,
  min_duration = 60
)
```

## Arguments

- data:

  A dataframe of any class that is or extends data.frame of one
  individual only. The dataframe must contain at least two spatial
  coordinates, `x` and `y`, and a temporal coordinate, `time`.

- max_speed:

  A numeric value specifying the maximum speed (m/s) between two
  coordinates that would be considered non-transitory

- lim_spat_indep:

  A numeric value of distance in metres of the spatial distance between
  two patches for them to the considered independent.

- lim_time_indep:

  A numeric value of time in minutes of the time difference between two
  patches for them to be considered independent.

- min_fixes:

  The minimum number of fixes for a group of spatially-proximate number
  of points to be considered a preliminary residence patch.

- min_duration:

  The minimum duration (in seconds) for classifying residence patches.

## Value

A data.table that has the added column `patch` as character indicating
the patch ID.

## Details

Derived from `atlastools::atl_res_patch()` in the atlastools package
(Gupte et al., 2022), licensed under GPL-3.

## References

Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
287-307.
[doi:10.1111/1365-2656.13610](https://doi.org/10.1111/1365-2656.13610)

## Author

Pratik R. Gupte, Christine E. Beardsworth, Allert I. Bijleveld &
Johannes Krietsch

## Examples

``` r
# packages
library(tools4watlas)

# load example data
data <- data_example

# calculate residence patches for one red knot
data <- atl_res_patch(
  data[tag == "3038"],
  max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
  min_fixes = 2, min_duration = 60
)

# summary of residence patches
data_summary <- atl_res_patch_summary(data)
data_summary
#>      species    tag  patch nfixes   x_mean x_median  x_start    x_end  y_mean
#>       <char> <char> <char>  <int>    <num>    <num>    <num>    <num>   <num>
#>  1: red knot   3038      1   1039 650119.8 650143.7 650120.1 649921.5 5902387
#>  2: red knot   3038      2    958 650378.5 650378.6 650369.7 650384.2 5902349
#>  3: red knot   3038      3    831 650263.3 650251.5 650254.9 650313.1 5902162
#>  4: red knot   3038      4    354 650472.8 650457.9 650403.8 650534.6 5901982
#>  5: red knot   3038      5   1034 650763.1 650765.2 650722.6 650729.8 5901920
#>  6: red knot   3038      6    426 650805.2 650798.7 650859.0 650766.6 5901891
#>  7: red knot   3038      7    163 650739.1 650739.3 650739.5 650738.8 5901747
#>  8: red knot   3038      8    610 650664.2 650676.0 650696.8 650616.4 5901843
#>  9: red knot   3038      9   1173 650971.4 650995.1 651071.8 650865.5 5901981
#> 10: red knot   3038     10   1440 650728.6 650728.2 650773.4 650713.5 5901998
#> 11: red knot   3038     11     85 650883.8 650881.6 650895.4 650871.3 5902117
#> 12: red knot   3038     12    368 651515.0 651539.5 651555.4 651428.1 5902163
#> 13: red knot   3038     13    115 651406.1 651402.6 651422.3 651401.5 5902383
#> 14: red knot   3038     14     68 651429.5 651430.3 651423.4 651436.1 5902535
#> 15: red knot   3038     15    115 651499.6 651501.2 651457.8 651499.6 5903028
#> 16: red knot   3038     16      2 651254.8 651254.8 651254.8 651254.8 5902959
#> 17: red knot   3038     17      6 650945.7 650927.1 651025.0 650917.5 5902941
#> 18: red knot   3038     18      3 650605.3 650605.3 650605.3 650605.3 5903017
#> 19: red knot   3038     19      4 650681.9 650670.3 650716.7 650670.3 5903107
#> 20: red knot   3038     20      4 651668.5 651668.5 651668.5 651668.5 5903164
#> 21: red knot   3038     21      8 651621.9 651622.0 651626.9 651618.4 5902819
#> 22: red knot   3038     22      3 651686.5 651686.5 651686.5 651686.5 5902868
#> 23: red knot   3038     23     49 650213.7 650213.6 650216.9 650206.9 5902162
#> 24: red knot   3038     24    206 650228.0 650227.4 650251.0 650211.5 5902192
#> 25: red knot   3038     25    158 650062.5 650063.6 650053.1 650055.9 5902047
#> 26: red knot   3038     26   1018 650232.6 650236.4 650180.9 650257.9 5902030
#> 27: red knot   3038     27     81 650422.0 650421.3 650416.9 650430.5 5901725
#> 28: red knot   3038     28   3038 650572.6 650547.5 650608.5 650317.2 5902113
#> 29: red knot   3038     29   1072 650155.0 650155.0 650153.7 650159.1 5902363
#>      species    tag  patch nfixes   x_mean x_median  x_start    x_end  y_mean
#>       <char> <char> <char>  <int>    <num>    <num>    <num>    <num>   <num>
#>     y_median y_start   y_end           time_mean         time_median
#>        <num>   <num>   <num>              <POSc>              <POSc>
#>  1:  5902399 5902400 5902357 2023-09-23 01:39:27 2023-09-23 01:35:57
#>  2:  5902368 5902387 5902293 2023-09-23 02:56:06 2023-09-23 02:56:39
#>  3:  5902170 5902239 5902078 2023-09-23 03:49:21 2023-09-23 03:49:30
#>  4:  5901997 5902046 5901906 2023-09-23 04:24:05 2023-09-23 04:24:01
#>  5:  5901904 5902017 5901775 2023-09-23 05:04:49 2023-09-23 05:02:37
#>  6:  5901893 5901867 5901884 2023-09-23 05:48:01 2023-09-23 05:47:55
#>  7:  5901747 5901750 5901746 2023-09-23 06:04:21 2023-09-23 06:04:23
#>  8:  5901844 5901821 5901854 2023-09-23 06:26:57 2023-09-23 06:26:54
#>  9:  5901988 5901909 5902008 2023-09-23 07:18:55 2023-09-23 07:18:44
#> 10:  5902007 5901939 5902044 2023-09-23 08:32:55 2023-09-23 08:33:09
#> 11:  5902115 5902104 5902115 2023-09-23 09:16:10 2023-09-23 09:16:10
#> 12:  5902143 5902122 5902261 2023-09-23 09:34:33 2023-09-23 09:31:17
#> 13:  5902381 5902354 5902417 2023-09-23 10:03:57 2023-09-23 10:03:58
#> 14:  5902532 5902509 5902565 2023-09-23 10:15:58 2023-09-23 10:15:53
#> 15:  5903027 5903046 5903028 2023-09-23 11:10:51 2023-09-23 11:10:19
#> 16:  5902959 5902963 5902955 2023-09-23 12:00:45 2023-09-23 12:00:45
#> 17:  5902940 5902940 5902940 2023-09-23 12:44:22 2023-09-23 12:46:32
#> 18:  5903006 5902993 5903051 2023-09-23 13:38:58 2023-09-23 13:47:06
#> 19:  5903107 5903100 5903115 2023-09-23 14:09:47 2023-09-23 14:14:40
#> 20:  5903148 5903143 5903217 2023-09-23 15:07:37 2023-09-23 15:07:02
#> 21:  5902819 5902819 5902819 2023-09-23 15:17:47 2023-09-23 15:17:52
#> 22:  5902868 5902868 5902868 2023-09-23 15:20:58 2023-09-23 15:19:53
#> 23:  5902161 5902167 5902156 2023-09-23 15:37:04 2023-09-23 15:37:08
#> 24:  5902192 5902192 5902185 2023-09-23 15:46:43 2023-09-23 15:46:46
#> 25:  5902043 5902079 5902018 2023-09-23 15:57:53 2023-09-23 15:57:40
#> 26:  5902023 5902042 5902023 2023-09-23 16:39:38 2023-09-23 16:40:51
#> 27:  5901723 5901726 5901741 2023-09-23 17:15:20 2023-09-23 17:15:17
#> 28:  5902115 5901823 5902230 2023-09-23 19:41:13 2023-09-23 19:28:13
#> 29:  5902361 5902362 5902391 2023-09-23 23:30:06 2023-09-23 23:30:15
#>     y_median y_start   y_end           time_mean         time_median
#>        <num>   <num>   <num>              <POSc>              <POSc>
#>              time_start            time_end dist_start_end dist_in_patch
#>                  <POSc>              <POSc>          <num>         <num>
#>  1: 2023-09-23 01:00:03 2023-09-23 02:24:18     203.093945   1845.172537
#>  2: 2023-09-23 02:26:39 2023-09-23 03:23:33      95.183981   1172.579761
#>  3: 2023-09-23 03:24:03 2023-09-23 04:13:51     171.139566    724.395850
#>  4: 2023-09-23 04:14:06 2023-09-23 04:34:20     191.555615    349.044443
#>  5: 2023-09-23 04:35:08 2023-09-23 05:35:53     241.910148   1280.437829
#>  6: 2023-09-23 05:36:17 2023-09-23 05:59:38      94.007329    394.634875
#>  7: 2023-09-23 05:59:56 2023-09-23 06:08:41       3.606106    116.823319
#>  8: 2023-09-23 06:08:53 2023-09-23 06:44:26      87.212108    411.854211
#>  9: 2023-09-23 06:45:11 2023-09-23 07:51:46     228.708415   1032.202468
#> 10: 2023-09-23 07:52:04 2023-09-23 09:13:13     120.308727   1137.054849
#> 11: 2023-09-23 09:13:40 2023-09-23 09:18:37      26.517958     98.768135
#> 12: 2023-09-23 09:19:22 2023-09-23 09:59:34     188.146599    949.080795
#> 13: 2023-09-23 10:00:16 2023-09-23 10:07:58      66.914171    212.722517
#> 14: 2023-09-23 10:13:40 2023-09-23 10:18:22      56.954434    140.588243
#> 15: 2023-09-23 10:26:40 2023-09-23 11:25:39      45.630289    277.568692
#> 16: 2023-09-23 11:52:03 2023-09-23 12:09:27       8.219071      8.219071
#> 17: 2023-09-23 12:32:27 2023-09-23 12:47:36     107.521794    108.150466
#> 18: 2023-09-23 13:18:54 2023-09-23 13:50:54      58.628698     58.628698
#> 19: 2023-09-23 13:54:57 2023-09-23 14:14:51      48.732652     61.246854
#> 20: 2023-09-23 15:03:29 2023-09-23 15:12:53      74.045195     74.045195
#> 21: 2023-09-23 15:17:11 2023-09-23 15:18:23       8.514269      9.081978
#> 22: 2023-09-23 15:19:50 2023-09-23 15:23:11       0.000000      0.000000
#> 23: 2023-09-23 15:35:35 2023-09-23 15:38:23      14.498573     54.885156
#> 24: 2023-09-23 15:40:29 2023-09-23 15:52:50      40.230391    190.622271
#> 25: 2023-09-23 15:53:17 2023-09-23 16:02:35      60.546290    250.967827
#> 26: 2023-09-23 16:04:11 2023-09-23 17:12:38      79.288671    945.792588
#> 27: 2023-09-23 17:13:08 2023-09-23 17:17:35      20.560332     85.590624
#> 28: 2023-09-23 17:17:59 2023-09-23 22:24:09     500.761579   3526.213616
#> 29: 2023-09-23 22:44:00 2023-09-23 23:59:54      29.822003   1197.758289
#>              time_start            time_end dist_start_end dist_in_patch
#>                  <POSc>              <POSc>          <num>         <num>
#>     dist_bw_patch time_bw_patch disp_in_patch  duration
#>             <num>         <num>         <num>     <num>
#>  1:            NA            NA    203.093945  5054.598
#>  2:     449.10828       140.989     95.183981  3413.729
#>  3:     140.38571        29.997    171.139566  2987.763
#>  4:      96.27647        14.998    191.555615  1214.904
#>  5:     218.34299        47.996    241.910148  3644.711
#>  6:     158.80644        23.998     94.007329  1400.888
#>  7:     136.99063        17.999      3.606106   524.959
#>  8:      85.36514        11.999     87.212108  2132.830
#>  9:     458.67406        44.997    228.708415  3995.684
#> 10:     114.83434        17.999    120.308727  4868.615
#> 11:     191.48906        26.998     26.517958   296.977
#> 12:     684.17736        44.997    188.146599  2411.810
#> 13:      92.91601        41.997     66.914171   461.963
#> 14:      94.28270       341.973     56.954434   281.978
#> 15:     481.80799       497.960     45.630289  3539.722
#> 16:     253.10421      1583.876      8.219071  1043.918
#> 17:     230.26572      1379.892    107.521794   908.929
#> 18:     316.52791      1877.852     58.628698  1919.850
#> 19:     121.63455       242.981     48.732652  1193.906
#> 20:     998.55687      2918.771     74.045195   563.955
#> 21:     400.94369       257.980      8.514269    71.994
#> 22:      84.09319        86.993      0.000000   200.984
#> 23:    1628.57203       743.942     14.498573   167.986
#> 24:      56.98600       125.990     40.230391   740.942
#> 25:     190.57924        26.997     60.546290   557.956
#> 26:     127.23215        95.993     79.288671  4106.673
#> 27:     336.92942        29.998     20.560332   266.979
#> 28:     195.76701        23.998    500.761579 18370.541
#> 29:     210.06924      1190.905     29.822003  4553.638
#>     dist_bw_patch time_bw_patch disp_in_patch  duration
#>             <num>         <num>         <num>     <num>
```
