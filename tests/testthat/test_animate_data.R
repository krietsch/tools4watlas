# Test atl_time_steps
# Define temporary output path
temp_path <- tempdir()

test_that("atl_time_steps generates correct time sequence", {
  datetime_vector <- as.POSIXct(c("2024-01-01 00:00:00", "2024-01-01 01:00:00"))
  ts <- atl_time_steps(datetime_vector, "30 min", temp_path, create_path = TRUE)
  
  expect_s3_class(ts, "data.table")
  expect_equal(ncol(ts), 2)
  expect_named(ts, c("datetime", "path"))
  expect_equal(nrow(ts), 3)
  expect_equal(ts$datetime, seq(datetime_vector[1], datetime_vector[2], "30 min"))
})

test_that("atl_time_steps handles directory creation", {
  new_path <- file.path(temp_path, "new_dir")
  expect_false(dir.exists(new_path))
  
  ts <- atl_time_steps(Sys.time(), "1 hour", new_path, create_path = TRUE)
  expect_true(dir.exists(new_path))
})

test_that("atl_time_steps errors if directory does not exist and create_path is FALSE", {
  nonexistent_path <- file.path(temp_path, "does_not_exist")
  expect_error(
    atl_time_steps(Sys.time(), "1 hour", nonexistent_path, create_path = FALSE),
    "Directory does not exist"
  )
})


# tests for atl_progress_bar()
test_that("atl_progress_bar runs to completion with provided total", {
  # create temporary directory
  tmp <- tempfile()
  dir.create(tmp)
  
  # create dummy png files incrementally
  for (i in 1:3) {
    file.create(file.path(tmp, paste0("frame_", i, ".png")))
  }
  
  # run function and expect "Done!" printed to console
  expect_output(
    atl_progress_bar(tmp, total = 3, refresh_rate = 0.1),
    "Done!"
  )
  
  # clean up
  unlink(tmp, recursive = TRUE)
})

test_that("atl_progress_bar reads total from total_frames.txt", {
  # create temporary directory
  tmp <- tempfile()
  dir.create(tmp)
  
  # write total_frames.txt
  writeLines("2", file.path(tmp, "total_frames.txt"))
  
  # create png files
  file.create(file.path(tmp, "f1.png"))
  file.create(file.path(tmp, "f2.png"))
  
  # expect function prints 'Done!' when complete
  expect_output(
    atl_progress_bar(tmp, refresh_rate = 0.1),
    "Done!"
  )
  
  unlink(tmp, recursive = TRUE)
})


test_that("atl_progress_bar errors if no total and no total_frames.txt", {
  # create empty temp dir
  tmp <- tempfile()
  dir.create(tmp)
  
  # expect informative error
  expect_error(
    atl_progress_bar(tmp, refresh_rate = 0.1),
    "Error: 'total' not provided and 'total_frames.txt' not found"
  )
  
  unlink(tmp, recursive = TRUE)
})

test_that("atl_progress_bar stops when all pngs exist", {
  # create temporary directory
  tmp <- tempfile()
  dir.create(tmp)
  
  # write total_frames.txt
  writeLines("2", file.path(tmp, "total_frames.txt"))
  
  # initially only one file
  file.create(file.path(tmp, "f1.png"))
  
  # create second file in advance so function completes immediately
  file.create(file.path(tmp, "f2.png"))
  
  # should run and print "Done!"
  expect_output(atl_progress_bar(tmp, refresh_rate = 0.1), "Done!")
  
  unlink(tmp, recursive = TRUE)
})


# Test atl_alpha_along and atl_size_along
test_that("along is double", {
  expect_type(atl_alpha_along(1:100, head = 20, skew = -2), "double")
  expect_type(atl_size_along(1:100, head = 70, to = c(0.1, 5)), "double")
})

test_that("along is in expected range", {
  expect_lt(max(atl_alpha_along(1:100, head = 20, skew = -2)), 1.1)
  expect_gt(min(atl_alpha_along(1:100, head = 20, skew = -2)), 0)
  expect_lt(max(atl_size_along(1:100, head = 70, to = c(0.1, 5))), 5.1)
  expect_gt(min(atl_size_along(1:100, head = 70, to = c(0.1, 5))), 0)
})

test_that("atl_alpha_along adjusts head when head >= length(x)", {
  # create short vector
  x <- 1:10
  
  # set head larger than length(x) to trigger condition
  res <- atl_alpha_along(x, head = 15, skew = -2)
  
  # check result type and length
  expect_type(res, "double")
  expect_length(res, length(x))
  
  # check values are numeric and within valid range
  expect_true(all(is.finite(res)))
  expect_gt(min(res), 0)
  expect_lt(max(res), 1.1)
})

test_that("atl_size_along adjusts head when head >= length(x)", {
  # create short vector
  x <- 1:10
  
  # set head larger than length(x) to trigger condition
  res <- atl_size_along(x, head = 20, to = c(0.1, 5))
  
  # check result type and length
  expect_type(res, "double")
  expect_length(res, length(x))
  
  # check values are numeric and within expected range
  expect_true(all(is.finite(res)))
  expect_gt(min(res), 0)
  expect_lt(max(res), 5.1)
})

# Test atl_ffmpeg_pattern
test_that("atl_ffmpeg_pattern generates correct patterns", {
  expect_equal(atl_ffmpeg_pattern("path/to/file/001.png"), "%03d.png")
  expect_equal(atl_ffmpeg_pattern("/another/path/0001.png"), "%04d.png")
  expect_equal(atl_ffmpeg_pattern("/img/123456.png"), "%06d.png")
})
