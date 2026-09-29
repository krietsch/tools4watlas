
test_that("data has expected columns", {
  # make some test data
  testdata <- data.table::data.table(
    x = as.double(1:1e3),
    y = as.double(1:1e3),
    time = as.numeric(1:1e3)
  )

  # set names as objects
  x <- "x"
  y <- "y"
  time <- "time"

  # expect no error
  expect_silent(object = {
    atl_check_data(
      data = testdata,
      names_expected = c("x", "y", "time")
    )
  })

  # check for passing objects as strings
  expect_silent(object = {
    atl_check_data(
      data = testdata,
      names_expected = c(x, y, time)
    )
  })

  # expect an error
  expect_error(object = {
    atl_check_data(
      data = testdata,
      names_expected = c("X", "Y", "TIME")
    )
  })
})
