
test_that("atl_get_data handles input validation correctly", {
  # Check for valid tag input
  expect_error(
    atl_get_data(
      tag = list(123),
      tracking_time_start = "2023-01-01 00:00:00",
      tracking_time_end = "2023-01-02 00:00:00"
    ),
    "tag provided must be numeric or character"
  )

  # Check for tag length
  expect_error(
    atl_get_data(
      tag = "12345678",
      tracking_time_start = "2023-01-01 00:00:00",
      tracking_time_end = "2023-01-02 00:00:00"
    ),
    "tag should be either < 7 digits or full 11 digits"
  )

  # Check for valid start and end times
  expect_error(
    atl_get_data(
      tag = "1234",
      tracking_time_start = 20230101,
      tracking_time_end = "2023-01-02 00:00:00"
    ),
    "start tracking time is not a character"
  )

  expect_error(
    atl_get_data(
      tag = "1234",
      tracking_time_start = "2023-01-01 00:00:00",
      tracking_time_end = 20230102
    ),
    "end tracking time is not a character"
  )

  # Check for timezone input
  expect_error(
    atl_get_data(
      tag = "1234",
      tracking_time_start = "2023-01-01 00:00:00",
      tracking_time_end = "2023-01-02 00:00:00",
      timezone = 123
    ),
    "timezone provided must be numeric or character"
  )
})

test_that("atl_get_data handles database connections", {
  # Mock RSQLite and RMySQL connections
  mock_sqlite <- mockery::mock(data.frame(
    TAG = c("31001001234"), TIME = c(1672444800000),
    X = c(100), Y = c(200), NBS = c(4),
    VARX = c(1), VARY = c(1), COVXY = c(0)
  ))
  mockery::stub(atl_get_data, "RSQLite::dbGetQuery", mock_sqlite)

  # Test with local SQLiteDB
  result <- atl_get_data(
    tag = "1234",
    tracking_time_start = "2023-01-01 00:00:00",
    tracking_time_end = "2023-01-02 00:00:00",
    SQLiteDB = "dummy_path.db"
  )
  expect_true(is.data.frame(result))
  expect_equal(ncol(result), 10)
  expect_equal(result$tag[1], "1234")

  # Test with existing connection
  mock_connection <- mockery::mock(data.frame(
    TAG = c("31001001234"), TIME = c(1672444800000),
    X = c(100), Y = c(200), NBS = c(4),
    VARX = c(1), VARY = c(1), COVXY = c(0)
  ))
  mockery::stub(atl_get_data, "DBI::dbGetQuery", mock_connection)
  result <- atl_get_data(
    tag = "1234",
    tracking_time_start = "2023-01-01 00:00:00",
    tracking_time_end = "2023-01-02 00:00:00",
    use_connection = mock_connection
  )
  expect_true(is.data.frame(result))
  expect_equal(result$tag[1], "1234")
})

test_that("atl_get_data retrieves and processes data correctly", {
  # Mock RSQLite and RMySQL connections
  mock_sqlite <- mockery::mock(data.frame(
    TAG = c("31001001234"), TIME = c(1672444800000),
    X = c(100), Y = c(200), NBS = c(4),
    VARX = c(1), VARY = c(1), COVXY = c(0)
  ))
  mockery::stub(atl_get_data, "RSQLite::dbGetQuery", mock_sqlite)

  # Test with local SQLiteDB
  result <- atl_get_data(
    tag = "1234",
    tracking_time_start = "2023-01-01 00:00:00",
    tracking_time_end = "2023-01-02 00:00:00",
    SQLiteDB = "dummy_path.db"
  )
  expect_true(is.data.frame(result))
  expect_equal(ncol(result), 10)

  # Check result structure
  expect_true(is.data.frame(result))
  expect_equal(names(result), c(
    "posID", "tag", "time", "datetime",
    "x", "y", "nbs", "varx", "vary", "covxy"
  ))

  # Check time conversion and tag formatting
  expect_equal(result$time[1], 1672444800) # Milliseconds to seconds
  expect_equal(result$tag[1], "1234") # Short format
})

test_that("atl_get_data gives correct warning", {
  sqlite_db <- system.file(
    "extdata", "watlas_example.SQLite", package = "tools4watlas"
  )
  con <- RSQLite::dbConnect(RSQLite::SQLite(), sqlite_db)
  
  expect_warning(
    result <- atl_get_data(
      tag = "31001000001",
      tracking_time_start = "2023-01-01 00:00:00",
      tracking_time_end = "2023-01-02 00:00:00",
      use_connection = con
    ),
    regexp = "No data available for tag 0001 in this time period."
  )
  
  # close connection
  RSQLite::dbDisconnect(con)
  
  # Validate result is an empty data.table with correct columns
  expected_cols <- c("posID", "tag", "time", "datetime", "x", "y", "nbs", "varx", "vary", "covxy")
  expect_true(is.data.table(result))
  expect_equal(colnames(result), expected_cols)
  expect_equal(nrow(result), 0)
  
})
