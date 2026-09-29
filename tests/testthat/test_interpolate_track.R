
test_that("atl_interpolate_track works correctly", {
  # prepare example data
  data <- data_example[tag == "3038"]
  data <- data[, .(species, posID, tag, time, datetime, x, y, tideID)]
  data <- atl_res_patch(
    data,
    max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
    min_fixes = 3, min_duration = 120
  )
  data <- atl_thin_data(
    data = data,
    interval = 60,
    id_columns = c("tag", "species"),
    method = "aggregate"
  )
  
  # run interpolation
  data_int <- atl_interpolate_track(
    data = data,
    tag = "tag",
    x = "x",
    y = "y",
    time = "time",
    patch = "patch",
    interp_interval = 60,
    max_gap = 60 * 15,
    max_dist = 1000,
    patches_only = TRUE
  )
  
  # returns a data.table
  expect_s3_class(data_int, "data.table")
  
  # output has more rows than input (interpolation added rows)
  expect_gt(nrow(data_int), nrow(data))
  
  # expected columns are present
  expect_true(all(c(
    "tag", "time", "datetime", "x", "y", "patch",
    "gap_next", "dist_next", "interpolated"
  ) %in% names(data_int)))
  
  # datetime is POSIXct
  expect_s3_class(data_int$datetime, "POSIXct")
  
  # datetime is third column
  expect_equal(names(data_int)[3], "datetime")
  
  # interpolated column is logical
  expect_type(data_int$interpolated, "logical")
  
  # no interpolated rows exceed max_gap
  expect_true(all(
    data_int[interpolated == TRUE]$gap_next <= 60 * 15
  ))
  
  # no interpolated rows exceed max_dist
  expect_true(all(
    data_int[interpolated == TRUE]$dist_next <= 1000
  ))
  
  # no interpolated rows have NA patch when patches_only = TRUE
  expect_false(any(
    data_int[interpolated == TRUE, is.na(patch)]
  ))
  
  # x and y have no NAs after interpolation
  expect_false(anyNA(data_int$x))
  expect_false(anyNA(data_int$y))
  
  # rows are ordered by tag and time
  expect_equal(
    data_int,
    data_int[order(tag, time)]
  )
  
  # patch column is character
  expect_type(data_int$patch, "character")
  
   # patches_only = TRUE errors if patch column is missing
  data_no_patch <- copy(data)
  data_no_patch[, patch := NULL]
  expect_error(
    atl_interpolate_track(
      data = data_no_patch,
      tag = "tag", x = "x", y = "y", time = "time",
      patch = "patch", patches_only = TRUE
    )
  )
  
  # patches_only = FALSE runs without patch column
  expect_s3_class(
    atl_interpolate_track(
      data = data_no_patch,
      tag = "tag", x = "x", y = "y", time = "time",
      interp_interval = 60, max_gap = 60 * 15,
      patches_only = FALSE
    ),
    "data.table"
  )
  
  # max_dist = NULL skips distance filter and dist_next column is absent
  data_int_nodist <- atl_interpolate_track(
    data = as.data.frame(data),
    tag = "tag", x = "x", y = "y", time = "time",
    patch = "patch", interp_interval = 60,
    max_gap = 60 * 15, max_dist = NULL,
    patches_only = TRUE
  )
  expect_false("dist_next" %in% names(data_int_nodist))
  
  # missing required columns error
  expect_error(
    atl_interpolate_track(
      data = data[, .(tag, time)],
      tag = "tag", x = "x", y = "y", time = "time",
      patches_only = FALSE
    )
  )
})

test_that("atl_interpolate_track handles tags with fewer than 2 rows", {
  # prepare example data
  data <- data_example[tag == "3038"]
  data <- data[, .(species, posID, tag, time, datetime, x, y, tideID)]
  data <- atl_res_patch(
    data,
    max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
    min_fixes = 3, min_duration = 120
  )
  data <- atl_thin_data(
    data = data,
    interval = 60,
    id_columns = c("tag", "species"),
    method = "aggregate"
  )
  
  single_row <- data[1]
  
  # tag with only 1 row triggers warning and is skipped,
  # and since no tags remain, a second warning is also thrown
  expect_warning(
    expect_warning(
      atl_interpolate_track(
        data = single_row,
        tag = "tag", x = "x", y = "y", time = "time",
        patch = "patch", max_gap = 300000, patches_only = TRUE
      ),
      regexp = "fewer than 2 rows"
    ),
    regexp = "No tags with sufficient data"
  )

})
