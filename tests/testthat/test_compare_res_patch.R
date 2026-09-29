
test_that("atl_compare_res_patch_summary works correctly", {
  
  # load example data
  data <- data_example
  
  # run atl_res_patch with two different parameter sets
  data_v1 <- atl_res_patch(
    data[tag == "3038"],
    max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
    min_fixes = 3, min_duration = 120
  )
  data_v2 <- atl_res_patch(
    data[tag == "3038"],
    max_speed = 5, lim_spat_indep = 75, lim_time_indep = 180,
    min_fixes = 3, min_duration = 120
  )
  
  # run function
  result <- atl_compare_res_patch_summary(data_v1, data_v2)
  
  # returns a data.table
  expect_s3_class(result, "data.table")
  
  # has expected columns
  expect_named(result, c("tag", "tideID", "change", "patch_v1", "patch_v2"),
               ignore.order = TRUE
  )
  
  # change column only contains valid categories
  expect_true(all(result$change %in% c("lost", "gained", "split", "merge")))
  
  # patch_v1 is NA for gained patches
  expect_true(all(is.na(result[change == "gained"]$patch_v1)))
  
  # patch_v2 is NA for lost patches
  expect_true(all(is.na(result[change == "lost"]$patch_v2)))
  
  # known output from example data: 1 gained, 2 merges
  expect_equal(nrow(result[change == "gained"]), 1)
  expect_equal(nrow(result[change == "lost"]), 0)
  expect_equal(nrow(result[change == "split"]), 0)
  expect_equal(nrow(result[change == "merge"]), 2)
  
  # merge rows have comma-separated patch_v1
  merge_rows <- result[change == "merge"]
  expect_true(all(grepl(",", merge_rows$patch_v1)))
  
  # no NAs in tag or change columns
  expect_false(anyNA(result$tag))
  expect_false(anyNA(result$change))
  
})

test_that("atl_compare_res_patch_summary errors on missing columns", {
  
  data <- data_example
  
  data_v1 <- atl_res_patch(
    data[tag == "3038"],
    max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
    min_fixes = 3, min_duration = 120
  )
  
  # remove required column from already patched data
  bad_data <- copy(data_v1)
  bad_data[, patch := NULL]
  
  expect_error(
    atl_compare_res_patch_summary(bad_data, data_v1)
  )
  
})