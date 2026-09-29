
test_that("atl_add_tidal_data adds tidal information correctly", {
  # Mock tracking data
  tracking_data <- data.frame(
    time = as.POSIXct(c(
      "2023-01-01 10:00:00", "2023-01-01 10:10:00",
      "2023-01-01 10:20:00"
    ), tz = "UTC"),
    x = c(100, 150, 200),
    y = c(200, 250, 300),
    datetime = as.POSIXct(c(
      "2023-01-01 10:00:00", "2023-01-01 10:10:00",
      "2023-01-01 10:20:00"
    ), tz = "UTC")
  )

  # Mock tidal data
  tide_data <- data.table(
    high_start_time = as.POSIXct(c(
      "2023-01-01 09:00:00",
      "2023-01-01 21:00:00"
    ), tz = "UTC"),
    low_time = as.POSIXct(c(
      "2023-01-01 15:00:00",
      "2023-01-02 03:00:00"
    ), tz = "UTC"),
    tideID = c(1, 2)
  )

  # Mock high-resolution tidal data
  tide_data_highres <- data.table(
    dateTime = seq(
      from = as.POSIXct("2023-01-01 09:00:00", tz = "UTC"),
      to = as.POSIXct("2023-01-01 15:00:00", tz = "UTC"),
      by = "10 min"
    ),
    waterlevel = seq(50, 150, length.out = 37) # Simulated water levels
  )

  # Run the function
  result <- atl_add_tidal_data(
    data = tracking_data,
    tide_data = tide_data,
    tide_data_highres = tide_data_highres,
    waterdata_resolution = "10 minute",
    offset = 0
  )

  # Check the result has the expected columns
  expect_true(all(c("tideID", "tidaltime", "time2lowtide", "waterlevel") %in%
                    colnames(result)))

  # Check the tideID is correctly assigned
  expect_equal(result$tideID, c(1, 1, 1)) # All points fall under tideID 1

  # Check tidaltime calculation
  expect_equal(result$tidaltime, c(60, 70, 80)) # Time since high tide in min

  # Check time2lowtide calculation
  expect_equal(result$time2lowtide, c(-300, -290, -280)) # T to low tide in min

  # Check waterlevel mapping
  datetime_example <- result$datetime[1]
  expect_equal(
    result$waterlevel[1],
    tide_data_highres[dateTime == datetime_example]$waterlevel[1]
  ) # First 3 water levels match
})

test_that("atl_add_tidal_data handles empty input gracefully", {
  # Empty tracking data
  tracking_data <- data.frame(
    time = as.POSIXct(character(0)),
    x = numeric(0),
    y = numeric(0),
    datetime = as.POSIXct(character(0))
  )

  # Mock tidal data
  tide_data <- data.frame(
    high_start_time = as.POSIXct(character(0)),
    low_time = as.POSIXct(character(0)),
    tideID = numeric(0)
  )

  # Mock high-resolution tidal data
  tide_data_highres <- data.frame(
    dateTime = as.POSIXct(character(0)),
    waterlevel = numeric(0)
  )

  # Run the function
  expect_error(atl_add_tidal_data(
    data = tracking_data,
    tide_data = tide_data,
    tide_data_highres = tide_data_highres,
    waterdata_resolution = "10 minute",
    offset = 0
  ), "Input doesn't have any rows")
})

test_that("atl_add_tidal_data errors on incorrect inputs", {
  # Incorrect data type for `data`
  expect_error(
    atl_add_tidal_data(
      data = list(),
      tide_data = data.table(),
      tide_data_highres = data.table(),
      waterdata_resolution = "10 minute",
      offset = 0
    ),
    "Data not a data.frame object!"
  )

  # Missing datetime column
  tracking_data <- data.frame(
    time = as.POSIXct(c("2023-01-01 10:00:00"), tz = "UTC"),
    x = c(100),
    y = c(200)
  )
  expect_error(
    atl_add_tidal_data(
      data = tracking_data,
      tide_data = data.table(),
      tide_data_highres = data.table(),
      waterdata_resolution = "10 minute",
      offset = 0
    ),
    "POSIXct"
  )
})


test_that("atl_add_tidal_data interpolates waterlevel correctly", {
  # mock tracking data spaced closer than highres tide data resolution
  tracking_data <- data.frame(
    datetime = as.POSIXct(c(
      "2023-01-01 09:05:00",
      "2023-01-01 09:07:00",
      "2023-01-01 09:09:00"
    ), tz = "UTC"),
    time = as.POSIXct(c(
      "2023-01-01 09:05:00",
      "2023-01-01 09:07:00",
      "2023-01-01 09:09:00"
    ), tz = "UTC"),
    x = 1:3, y = 1:3
  )
  
  # simple tide periods
  tide_data <- data.table(
    high_start_time = as.POSIXct("2023-01-01 09:00:00", tz = "UTC"),
    low_time = as.POSIXct("2023-01-01 15:00:00", tz = "UTC"),
    tideID = 1
  )
  
  # coarse waterlevel (every 10 min)
  tide_data_highres <- data.table(
    dateTime = as.POSIXct(c(
      "2023-01-01 09:00:00",
      "2023-01-01 09:10:00"
    ), tz = "UTC"),
    waterlevel = c(100, 200)
  )
  
  # run with interpolation to 1-minute steps
  result <- atl_add_tidal_data(
    data = tracking_data,
    tide_data = tide_data,
    tide_data_highres = tide_data_highres,
    waterdata_resolution = "10 min",
    waterdata_interpolation = "1 min",
    offset = 0
  )
  
  # check expected columns
  expect_true(all(c("waterlevel", "tideID", "tidaltime", "time2lowtide") %in%
                    names(result)))
  
  # check interpolation: should linearly increase from 100 to 200 across 10 min
  # 09:05 is halfway, expect roughly 150
  expect_equal(result$waterlevel[1], 150, tolerance = 0.1)
  # 09:07 is 70% along the interval → ~170
  expect_equal(result$waterlevel[2], 170, tolerance = 0.1)
  # 09:09 → ~190
  expect_equal(result$waterlevel[3], 190, tolerance = 0.1)
  
  # check tideID assignment consistent
  expect_equal(unique(result$tideID), 1)
  
  # check tidaltime is in minutes since high tide
  expect_equal(result$tidaltime, c(5, 7, 9))
})

