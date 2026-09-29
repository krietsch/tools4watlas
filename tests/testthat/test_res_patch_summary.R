
# Sample dataset for testing
test_data <- data.table(
  tag = rep(c("A", "B"), each = 6),
  patch = c(1,1,1,2,2,2, 1,1,2,2,3,3),
  x = c(0,1,2,0,1,2, 10,11,20,21,30,31),
  y = c(0,1,1,2,2,3, 0,0,1,2,2,3),
  time = as.numeric(1:12)
)

# --- Test input validation ---

test_that("atl_res_patch_summary throws error for invalid inputs", {
  expect_error(atl_res_patch_summary(list(a = 1)),
               "Input is not a data.frame")
  
  bad_data <- data.table(tag = "A", x = 1, y = 1, time = 1)
  expect_error(atl_res_patch_summary(bad_data), "missing")
})

# --- Test basic structure and output ---

test_that("atl_res_patch_summary returns expected structure", {
  res <- atl_res_patch_summary(test_data)
  
  expect_s3_class(res, "data.table")
  expect_true(all(c("tag", "patch", "nfixes", "x_mean", "y_mean",
                    "dist_in_patch", "disp_in_patch", "duration") %in%
                    names(res)))
  expect_equal(nrow(res),
               length(unique(paste(test_data$tag, test_data$patch))))
})

# --- Test summary calculations ---

test_that("atl_res_patch_summary calculates summaries correctly", {
  res <- atl_res_patch_summary(test_data)
  
  # Check nfixes
  expect_equal(res[tag == "A" & patch == 1, nfixes], 3)
  
  # Check coordinate means
  expect_equal(res[tag == "A" & patch == 1, x_mean], mean(c(0, 1, 2)))
  expect_equal(res[tag == "A" & patch == 1, y_mean], mean(c(0, 1, 1)))
  
  # Check distances and durations
  expect_true(all(res$dist_in_patch >= 0))
  expect_true(all(res$disp_in_patch >= 0))
  expect_true(all(res$duration >= 0))
})

# --- Test handling of missing patches ---

test_that("atl_res_patch_summary removes rows with NA patches", {
  data_na <- copy(test_data)
  data_na$patch[3] <- NA
  
  res <- atl_res_patch_summary(data_na)
  expect_false(any(is.na(res$patch)))
})

# --- Test additional summary variables and functions ---

test_that("atl_res_patch_summary computes extra summaries", {
  extra_data <- data.table(
    tag = rep("A", 4),
    patch = c(1, 1, 2, 2),
    x = c(0, 1, 2, 3),
    y = c(0, 1, 2, 3),
    time = 1:4,
    speed = c(10, 20, 30, 40),
    temp = c(5, 6, 7, 8)
  )
  
  res <- atl_res_patch_summary(
    extra_data,
    summary_variables = c("speed", "temp"),
    summary_functions = c("mean", "sd")
  )
  
  expect_true(all(c("speed_mean", "speed_sd", "temp_mean", "temp_sd") %in%
                    names(res)))
  expect_equal(res[tag == "A" & patch == 1, speed_mean], mean(c(10, 20)))
  expect_equal(res[tag == "A" & patch == 2, temp_sd], sd(c(7, 8)))
})
