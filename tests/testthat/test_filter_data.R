
test_that("data is correctly filtered", {
  # make some test data
  test_data <- data.frame(
    x = as.double(1:1e3),
    y = as.double(1:1e3),
    time = as.numeric(1:1e3),
    cov_1 = runif(1000, 1, 100)
  )
  # test output here
  test_output <- atl_filter_covariates(
    test_data,
    "data.table::between(cov_1, 25, 75)"
  )
  # check for min and max
  expect_gte(min(test_output$cov_1), 25)
  expect_lte(min(test_output$cov_1), 75)

  # check warning
  expect_warning(
    atl_filter_covariates(
      test_data,
      "data.table::between(cov_1, 0, 0.5)"
    ),
    regexp = "*no rows remaining*"
  )
})
