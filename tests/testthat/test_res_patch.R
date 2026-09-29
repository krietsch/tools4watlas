
test_that("atl_res_patch returns a data.table with patch column", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  expect_true(data.table::is.data.table(result))
  expect_true("patch" %in% names(result))
})

test_that("atl_res_patch preserves all original rows", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  n_rows <- nrow(data)
  
  result <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  expect_equal(nrow(result), n_rows)
})

test_that("atl_res_patch preserves original columns", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  original_cols <- c("species", "posID", "tag", "time", "datetime", "x", "y", "tideID")
  
  result <- atl_res_patch(
    data.table::copy(data),
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  expect_true(all(original_cols %in% names(result)))
})

test_that("atl_res_patch patch column is character type", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  expect_type(result$patch, "character")
})

test_that("atl_res_patch patch values are NA or non-negative integers (as characters)", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  non_na_patches <- result$patch[!is.na(result$patch)]
  expect_true(all(grepl("^[0-9]+$", non_na_patches)))
})

test_that("atl_res_patch data is ordered by time in output", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result <- atl_res_patch(
    data,
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  expect_true(all(diff(result$time) >= 0))
})

test_that("atl_res_patch warns when patch column already exists", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  data[, patch := 999L]
  
  expect_warning(
    atl_res_patch(
      data,
      max_speed = 3,
      lim_spat_indep = 75,
      lim_time_indep = 180,
      min_fixes = 3,
      min_duration = 120
    ),
    regexp = "patch.*overwritten"
  )
})

test_that("atl_res_patch overwrites pre-existing patch column correctly", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  data[, patch := 999L]
  
  result <- suppressWarnings(
    atl_res_patch(
      data,
      max_speed = 3,
      lim_spat_indep = 75,
      lim_time_indep = 180,
      min_fixes = 3,
      min_duration = 120
    )
  )
  
  expect_false(any(result$patch == "999", na.rm = TRUE))
})

test_that("atl_res_patch errors on non-data.frame input", {
  expect_error(
    atl_res_patch(list(x = 1, y = 2, time = 3)),
    regexp = "data.frame|data.table"
  )
})

test_that("atl_res_patch errors on missing required columns", {
  bad_data <- data.table::data.table(x = 1:10, y = 1:10) # missing 'time'
  
  expect_error(
    atl_res_patch(bad_data)
  )
})

test_that("atl_res_patch errors on non-positive parameter values", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  expect_error(
    atl_res_patch(data, max_speed = -1),
    regexp = "positive"
  )
  
  expect_error(
    atl_res_patch(data, lim_spat_indep = 0),
    regexp = "positive"
  )
})

test_that("atl_res_patch stricter speed threshold produces more or equal patches", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result_lenient <- atl_res_patch(
    data.table::copy(data),
    max_speed = 10,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  result_strict <- atl_res_patch(
    data.table::copy(data),
    max_speed = 1,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  n_patches_lenient <- length(unique(stats::na.omit(result_lenient$patch)))
  n_patches_strict  <- length(unique(stats::na.omit(result_strict$patch)))
  
  expect_gte(n_patches_strict, n_patches_lenient)
})

test_that("atl_res_patch higher min_fixes reduces assigned patch rows", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]
  
  result_low <- atl_res_patch(
    data.table::copy(data),
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 3,
    min_duration = 120
  )
  
  result_high <- atl_res_patch(
    data.table::copy(data),
    max_speed = 3,
    lim_spat_indep = 75,
    lim_time_indep = 180,
    min_fixes = 20,
    min_duration = 120
  )
  
  n_assigned_low  <- sum(!is.na(result_low$patch))
  n_assigned_high <- sum(!is.na(result_high$patch))
  
  expect_lte(n_assigned_high, n_assigned_low)
})


test_that("atl_res_patch returns same result on repeated calls (determinism)", {
  data <- data_example[
    tag == "3038",
    .(species, posID, tag, time, datetime, x, y, tideID)
  ]

  result1 <- atl_res_patch(data.table::copy(data),
    max_speed = 3, lim_spat_indep = 75,
    lim_time_indep = 180, min_fixes = 3, min_duration = 120
  )
  result2 <- atl_res_patch(data.table::copy(data),
    max_speed = 3, lim_spat_indep = 75,
    lim_time_indep = 180, min_fixes = 3, min_duration = 120
  )

  expect_equal(result1$patch, result2$patch)
})

