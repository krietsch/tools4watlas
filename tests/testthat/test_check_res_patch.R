# library(testthat)
# library(tools4watlas)
# library(ggplot2)

test_that("atl_check_res_patch() works with example data files", {
  skip_if_not_installed("tools4watlas")
  
  # Load example tracking data
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  # Compute residency patches
  data <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  # Locate example tide data files
  fp <- system.file("extdata", package = "tools4watlas")
  
  tidal_pattern_fp <- paste0(
    fp, "/example-tidalPattern-west_terschelling-UTC.csv"
  )
  measured_water_height_fp <- paste0(
    fp, "/example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv"
  )
  
  # Read tide data
  tide_data <- data.table::fread(tidal_pattern_fp) |> as.data.frame()
  tide_data_highres <- data.table::fread(measured_water_height_fp) |> 
    as.data.frame()
  
  # Pick one tide ID to plot
  tide_id <- unique(data$tideID)[1]
  
  # Run the function
  result <- atl_check_res_patch(
    data = data,
    tide_data = tide_data,
    tide_data_highres = tide_data_highres,
    tide = tide_id,
    waterlevel_min = -200,
    waterlevel_max = 200,
    buffer_res_patches = 30,
    filename = NULL,
    roosts = TRUE
  )
  
  # Check output type
  expect_s3_class(result, "ggplot")
  
})

test_that("atl_check_res_patch() errors without buffer_res_patches", {
  skip_if_not_installed("tools4watlas")
  
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  data <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  fp <- system.file("extdata", package = "tools4watlas")
  
  tidal_pattern_fp <- paste0(
    fp, "/example-tidalPattern-west_terschelling-UTC.csv"
  )
  measured_water_height_fp <- paste0(
    fp, "/example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv"
  )
  
  tide_data <- data.table::fread(tidal_pattern_fp)
  tide_data_highres <- data.table::fread(measured_water_height_fp)
  
  expect_error(
    atl_check_res_patch(
      data = data,
      tide_data = tide_data,
      tide_data_highres = tide_data_highres,
      tide = unique(data$tideID)[1]
    ),
    "buffer_res_patches"
  )
})

# Helper to build valid inputs (avoids repeating setup)
make_patch_data <- function() {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
}

make_tide_data <- function() {
  fp <- system.file("extdata", package = "tools4watlas")
  list(
    tide_data = data.table::fread(
      paste0(fp, "/example-tidalPattern-west_terschelling-UTC.csv")
    ),
    tide_data_highres = data.table::fread(
      paste0(fp, "/example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv")
    )
  )
}

# Test: errors on invalid tide ID (no data for tag and tide)
test_that("atl_check_res_patch() errors when no data for given tide", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  expect_error(
    atl_check_res_patch(
      data = data,
      tide_data = tides$tide_data,
      tide_data_highres = tides$tide_data_highres,
      tide = 999999L, # non-existent tide ID
      buffer_res_patches = 30
    ),
    "No data for this tag and tide."
  )
})

# Test: accepts plain data.frame inputs (triggers setDT conversion)
test_that("atl_check_res_patch() coerces data.frame inputs to data.table", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data() |> as.data.frame()
  tides <- make_tide_data()
  
  result <- atl_check_res_patch(
    data = data,
    tide_data = tides$tide_data |> as.data.frame(),
    tide_data_highres = tides$tide_data_highres,
    tide = unique(data$tideID)[1],
    buffer_res_patches = 30,
    filename = NULL
  )
  
  expect_s3_class(result, "ggplot")
})

# Test: errors when required columns missing from data
test_that("atl_check_res_patch() errors on missing columns in data", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  data_bad <- data[, .(tag, x, y, time)] # missing datetime and patch
  
  expect_error(
    atl_check_res_patch(
      data = data_bad,
      tide_data = tides$tide_data,
      tide_data_highres = tides$tide_data_highres,
      tide = unique(data$tideID)[1],
      buffer_res_patches = 30
    )
  )
})

# Test: errors when required columns missing from tide_data
test_that("atl_check_res_patch() errors on missing columns in tide_data", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  tide_data_bad <- tides$tide_data[, .(tideID)] # missing low_time etc.
  
  expect_error(
    atl_check_res_patch(
      data = data,
      tide_data = tide_data_bad,
      tide_data_highres = tides$tide_data_highres,
      tide = unique(data$tideID)[1],
      buffer_res_patches = 30
    )
  )
})

# Test: saves PNG when filename is provided
test_that("atl_check_res_patch() saves PNG when filename is given", {
  skip_if_not_installed("tools4watlas")
  skip_if_not_installed("ragg")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  tmp <- tempfile()
  
  atl_check_res_patch(
    data = data,
    tide_data = tides$tide_data,
    tide_data_highres = tides$tide_data_highres,
    tide = unique(data$tideID)[1],
    buffer_res_patches = 30,
    filename = tmp
  )
  
  expect_true(file.exists(paste0(tmp, ".png")))
  expect_gt(file.size(paste0(tmp, ".png")), 0)
  
  unlink(paste0(tmp, ".png"))
})

# Test: non-zero offset shifts tide lines without error
test_that("atl_check_res_patch() works with non-zero offset", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  result <- atl_check_res_patch(
    data = data,
    tide_data = tides$tide_data,
    tide_data_highres = tides$tide_data_highres,
    tide = unique(data$tideID)[1],
    buffer_res_patches = 30,
    offset = 60,
    filename = NULL
  )
  
  expect_s3_class(result, "ggplot")
})

# Test: errors when buffer_res_patches is explicitly NULL
test_that("atl_check_res_patch() errors when buffer_res_patches is NULL", {
  skip_if_not_installed("tools4watlas")
  
  data  <- make_patch_data()
  tides <- make_tide_data()
  
  expect_error(
    atl_check_res_patch(
      data = data,
      tide_data = tides$tide_data,
      tide_data_highres = tides$tide_data_highres,
      tide = unique(data$tideID)[1],
      buffer_res_patches = NULL
    ),
    "buffer_res_patches"
  )
})

# Test: multiple tags in data — only first tag is used
test_that("atl_check_res_patch() subsets to first tag when multiple tags present", {
  skip_if_not_installed("tools4watlas")
  
  tides <- make_tide_data()
  
  # build patch data for two different tags
  data_3038 <- make_patch_data()
  
  data_3288 <- data_example[
    tag == "3288",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  data_3288 <- atl_res_patch(
    data_3288,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  # combine both tags — function should silently use only first tag (3038)
  data_multi <- data.table::rbindlist(list(data_3038, data_3288), fill = TRUE)
  
  result <- atl_check_res_patch(
    data = data_multi,
    tide_data = tides$tide_data,
    tide_data_highres = tides$tide_data_highres,
    tide = unique(data_3038$tideID)[1],
    buffer_res_patches = 30,
    filename = NULL
  )
  
  expect_s3_class(result, "ggplot")
})

