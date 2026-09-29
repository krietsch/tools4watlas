
test_that("data kept within bounds", {
  # make test_data
  test_data <- data.table::data.table(
    X = as.double(seq_len(1000)),
    Y = as.double(seq_len(1000)),
    TIME = seq_len(1000)
  )

  test_data <- test_data[200:500, `:=`(
    X = rnorm(301, 300, 20),
    Y = rnorm(301, 800, 20)
  )]
  # test polygon
  test_polygon <- sf::st_multipoint(x = matrix(c(250, 250, 500, 500),
    ncol = 2,
    byrow = T
  ))
  test_polygon <- sf::st_buffer(test_polygon, dist = 200)
  test_area <- sf::st_sf(data.frame(
    feature = 1,
    geom = sf::st_sfc(test_polygon)
  ))
  sf::st_crs(test_area) <- 32631 # the WATLAS system CRS

  # run function
  test_output <- atl_filter_bounds(
    data = test_data,
    x = "X",
    y = "Y",
    x_range = c(100, 600),
    y_range = c(100, 650),
    sf_polygon = test_area,
    remove_inside = FALSE
  )

  # do tests
  # test that the vector class is data.table and data.frame
  expect_s3_class(object = test_output, class = c(
    "data.table",
    "data.frame"
  ))

  # check that some rows are removed or that none are added
  expect_gte(nrow(test_data), nrow(test_output))

  # check the correct points are kept
  expect_true(all(data.table::between(test_output$X, 100, 600)),
    info = "within bounds not working"
  )

  expect_true(all(data.table::between(test_output$Y, 100, 650)),
    info = "within bounds not working"
  )
})

test_that("data removed within bounds", {
  # make test_data
  test_data <- data.table::data.table(
    X = as.double(seq_len(1000)),
    Y = as.double(seq_len(1000)),
    TIME = seq_len(1000)
  )

  test_data <- test_data[200:500, `:=`(
    X = rnorm(301, 300, 20),
    Y = rnorm(301, 800, 20)
  )]

  # run function
  test_output <- atl_filter_bounds(
    data = test_data,
    x = "X",
    y = "Y",
    x_range = c(200, 500),
    y_range = c(700, 900),
    remove_inside = TRUE
  )

  # do tests
  # test that the vector class is data.table and data.frame
  expect_s3_class(object = test_output, class = c(
    "data.table",
    "data.frame"
  ))

  # check that some rows are removed or that none are added
  expect_gte(nrow(test_data), nrow(test_output))

  # check the correct points are kept
  expect_true(
    all(!(data.table::between(test_output$X, 200, 500) &
      data.table::between(test_output$Y, 700, 900))),
    info = "within bounds not working"
  )
})

test_that("data filtered correctly by polygon only", {
  # create test data
  test_data <- data.frame(
    X = c(1, 2, 3, 4, 5),
    Y = c(1, 2, 3, 4, 5)
  )
  
  # define a square polygon covering points (2,2) to (4,4)
  poly_coords <- list(matrix(c(
    2,2,
    4,2,
    4,4,
    2,4,
    2,2
  ), ncol = 2, byrow = TRUE))
  test_polygon <- sf::st_polygon(poly_coords)
  
  # convert to sf object (required by atl_within_polygon)
  sf_poly <- sf::st_sf(geometry = sf::st_sfc(test_polygon, crs = 32631))
  
  # run function to keep points **inside polygon**
  filtered_inside <- atl_filter_bounds(
    data = test_data,
    x = "X",
    y = "Y",
    sf_polygon = sf_poly,
    remove_inside = FALSE
  )
  
  # points inside polygon: (2,2), (3,3), (4,4)
  expect_equal(filtered_inside$X, c(2, 3, 4))
  expect_equal(filtered_inside$Y, c(2, 3, 4))
  
})

test_that("remove_inside = TRUE with polygon removes points inside polygon", {
  
  data <- data.table::copy(data_example)
  
  # get bbox of data to keep all points in bbox filter
  x_range <- range(data$x, na.rm = TRUE)
  y_range <- range(data$y, na.rm = TRUE)
  
  result <- atl_filter_bounds(
    data = data,
    x = "x",
    y = "y",
    sf_polygon = grienderwaard,
    remove_inside = TRUE
  )
  
  # use atl_within_polygon to independently check no points inside remain
  result <- atl_within_polygon(
    result,
    polygon = grienderwaard,
    col_name = "on_grienderwaard"
  )
  
  expect_true(all(result$on_grienderwaard == FALSE))
  expect_lt(nrow(result), nrow(data))
})

# Test: data.frame input is returned as data.frame (was_df path)
test_that("data.frame input is returned as data.frame", {
  test_data <- data.frame(
    X = as.double(1:10),
    Y = as.double(1:10)
  )
  
  result <- atl_filter_bounds(
    data = test_data,
    x = "X",
    y = "Y",
    x_range = c(1, 10),
    y_range = c(1, 10),
    remove_inside = FALSE
  )
  
  expect_s3_class(result, "data.frame")
})

# Test: warning when all rows are removed
test_that("warning issued when all rows removed", {
  test_data <- data.table::data.table(
    X = as.double(1:5),
    Y = as.double(1:5)
  )
  
  expect_warning(
    atl_filter_bounds(
      data = test_data,
      x = "X",
      y = "Y",
      x_range = c(100, 200),
      y_range = c(100, 200),
      remove_inside = FALSE
    ),
    "cleaned data has no rows remaining"
  )
})

# Test: error on non-dataframe input
test_that("error on non-dataframe input", {
  expect_error(
    atl_filter_bounds(
      data = "not_a_dataframe",
      x_range = c(1, 10),
      y_range = c(1, 10)
    ),
    "input not a dataframe object"
  )
})

# Test: error when remove_inside is not logical
test_that("error when remove_inside is not logical", {
  test_data <- data.table::data.table(X = as.double(1:5), Y = as.double(1:5))
  
  expect_error(
    atl_filter_bounds(
      data = test_data,
      x_range = c(1, 10),
      y_range = c(1, 10),
      remove_inside = "yes"
    ),
    "remove inside needs TRUE/FALSE"
  )
})

# Test: error when required x/y columns are missing
test_that("error when x or y columns missing from data", {
  test_data <- data.table::data.table(A = as.double(1:5), B = as.double(1:5))
  
  expect_error(
    atl_filter_bounds(
      data = test_data,
      x = "X",
      y = "Y",
      x_range = c(1, 10),
      y_range = c(1, 10)
    )
  )
})

# Test: error when no bounds or polygon supplied
test_that("error when no bounds or polygon supplied", {
  test_data <- data.table::data.table(X = as.double(1:5), Y = as.double(1:5))
  
  expect_error(
    atl_filter_bounds(
      data = test_data,
      x = "X",
      y = "Y"
    )
  )
})

# Test: error when bound lengths are not 2
test_that("error on incorrect bound lengths", {
  test_data <- data.table::data.table(X = as.double(1:5), Y = as.double(1:5))
  
  expect_error(
    atl_filter_bounds(
      data = test_data,
      x = "X",
      y = "Y",
      x_range = c(1, 5, 10),
      y_range = c(1, 5)
    ),
    "incorrect bound lengths"
  )
})

