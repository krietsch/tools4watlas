
test_that("cleaning raw data works", {
  # make test_data
  starttime <- Sys.time()
  attr(starttime, "tzone") <- "CET"
  starttime_num <- as.numeric(Sys.time()) * 1e3 # get numeric in milliseconds
  message(glue::glue("starttime = {starttime} and \\
                     starttime num = {starttime_num}"))

  test_data <- data.frame(
    x = cumsum(runif(
      n = 1e3,
      min = 0, max = 1
    )),
    y = cumsum(runif(
      n = 1e3,
      min = 0, max = 1
    )),
    time = seq(starttime_num,
      (starttime_num + 1e6),
      length.out = 1000
    ),
    nbs = round(runif(1e3, min = 1, max = 5)),
    tag = "31001000435",
    sd = 50,
    varx = 0,
    vary = 0,
    covxy = 0
  )

  # make copy
  test_output <- data.table::copy(test_data)
  # run function
  atl_median_smooth(
    data = test_output,
    moving_window = 3
  )

  # test on real data
  real_data <- data.table::fread("../testdata/whole_season_tx_435.csv")
  
  data.table::setnames(real_data, 
                       c("TAG", "X", "Y", "TIME"),
                       c("tag", "x", "y", "time"))
  
  
  test_output_real <- atl_median_smooth(
    data = real_data,
    tag = "tag",
    x = "x",
    y = "y",
    time = "time",
    moving_window = 5
  )

  # do tests
  # test that the vector class is data.table and data.frame
  expect_s3_class(
    object = test_output,
    class = c("data.table", "data.frame")
  )
  expect_s3_class(
    object = test_output_real,
    class = c("data.table", "data.frame")
  )

  # check that no rows are removed
  expect_equal(nrow(test_data), nrow(test_output))
})

test_that("atl_median_smooth() warns and returns NULL when data has no rows", {
  skip_if_not_installed("tools4watlas")
  
  # create empty data.table with correct columns
  empty_data <- data.table::data.table(
    tag = character(0),
    x = double(0),
    y = double(0),
    time = double(0)
  )
  
  expect_warning(
    result <- atl_median_smooth(
      data = empty_data,
      moving_window = 3
    ),
    "no data remaining"
  )
  
  expect_null(result)
})
