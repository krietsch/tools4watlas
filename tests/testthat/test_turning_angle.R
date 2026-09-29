
test_that("angles are calculated", {
  # make test positions
  test_df <- data.table::data.table(
    tag = rep(1234, 30),
    lat = sinpi(seq_len(30) / 10),
    lon = seq_len(30) / 30,
    time = 1:30
  )
  # run function with custom col names
  test_df <- atl_turning_angle(test_df, y = "lat", x = "lon")
  test_output <- test_df$angle
  
  # do tests
  # test that the first element is NA
  expect_equal(test_output[1], NA_real_,
    info = "first angle is not NA"
  )
  # test that the vector class is numeric or double
  expect_type(test_output, "double")

  test_df_2 <- data.table::data.table(
    tag = rep(1234, 30),
    y = seq_len(30),
    x = seq_len(30),
    time = 1:30
  )

  test_df <- atl_turning_angle(test_df_2)
  test_output <- test_df_2$angle

  # test for correctness
  # test that the angles except first are 0 in this case
  # the angles are rounded
  expect_equal(floor(test_output),
    c(NA, rep(0, 28), NA),
    info = "the angle calculation is wrong"
  )

  # check no data case
  test_df <- data.frame(
    tag = 1234,
    y = seq_len(1),
    x = seq_len(1),
    time = 1
  )
  test_df <- suppressWarnings(atl_turning_angle(test_df))
  bad_angle <- test_df$angle

  expect_equal(bad_angle, NA_real_,
    info = "bad data returns angles"
  )
})
