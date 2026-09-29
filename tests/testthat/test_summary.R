
# Sample data for testing
test_data <- data.table(
  tag = c("A", "A", "A", "B", "B"),
  x = c(1, 2, 3, 4, 5),
  y = c(5, 4, 3, 2, 1),
  time = c(1, 3, 6, 2, 8),
  datetime = as.POSIXct(c("2023-01-01 12:00:00", "2023-01-01 12:01:00", 
                          "2023-01-01 12:03:00", "2023-01-02 14:00:00", 
                          "2023-01-02 14:05:00"), tz = "UTC")
)

test_that("atl_summary returns correct structure", {
  summary <- atl_summary(test_data, id_columns = "tag")
  
  expect_s3_class(summary, "data.table")
  expect_true(all(c("tag", "n_positions", "first_data", "last_data", "days_data", 
                    "min_gap", "max_gap", "max_gap_factor", "fix_rate") %in% names(summary)))
})


test_that("atl_summary correctly calculates statistics", {
  summary <- atl_summary(test_data, id_columns = "tag")
  
  # Check number of positions
  expect_equal(summary[tag == "A"]$n_positions, 3)
  expect_equal(summary[tag == "B"]$n_positions, 2)
  
  # Check first and last date
  expect_equal(summary[tag == "A"]$first_data, min(test_data$datetime[test_data$tag == "A"]))
  expect_equal(summary[tag == "B"]$last_data, max(test_data$datetime[test_data$tag == "B"]))
  
  # Check min/max gap calculations
  expect_equal(summary[tag == "A"]$min_gap, min(diff(test_data$time[test_data$tag == "A"])))
  expect_equal(summary[tag == "B"]$max_gap, max(diff(test_data$time[test_data$tag == "B"])))
})
