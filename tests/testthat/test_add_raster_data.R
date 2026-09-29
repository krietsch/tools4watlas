# Create sample data
data <- data.table::data.table(x = c(1, 2, 3), y = c(4, 5, 6))
raster_matrix <- matrix(1:9, nrow = 3, ncol = 3)
example_raster <- terra::rast(raster_matrix)
terra::crs(example_raster) <- "EPSG:32631"

# Test valid raster extraction
test_that("atl_add_raster_data extracts raster values correctly", {
  skip_on_os("mac")
  data <- as.data.frame(data)
  result <- atl_add_raster_data(data, raster_data = example_raster)
  expect_s3_class(result, "data.table")
  expect_true("lyr.1" %in% names(result))
})

# Test missing coordinate columns
test_that("atl_add_raster_data handles missing coordinates", {
  skip_on_os("mac")
  data_invalid <- data.table(a = c(1, 2, 3), b = c(4, 5, 6))
  expect_error(
    atl_add_raster_data(data_invalid, raster_data = example_raster),
    "Specified x or y columns do not exist in the data."
  )
})

# Test invalid raster input
test_that("atl_add_raster_data checks raster input type", {
  skip_on_os("mac")
  expect_error(
    atl_add_raster_data(data, raster_data = "not_a_raster"),
    "Specified raster_data are not terra SpatRaster, but should be."
  )
})

# Test NA values in coordinate columns
test_that("atl_add_raster_data handles NA in coordinate columns", {
  skip_on_os("mac")
  data_na <- data.table(x = c(1, NA, 3), y = c(4, 5, 6))
  expect_error(
    atl_add_raster_data(data_na, raster_data = example_raster),
    "Specified x or y columns contain NA, but should not."
  )
})

# Test new_name renames column correctly
test_that("atl_add_raster_data uses new_name for output column", {
  skip_on_os("mac")
  data_df <- as.data.frame(data)
  result <- atl_add_raster_data(
    data_df,
    raster_data = example_raster, new_name = "my_var"
  )
  expect_true("my_var" %in% names(result))
  expect_false("lyr.1" %in% names(result))
})

# Test new_name = NULL falls back to var_name / raster layer name
test_that("atl_add_raster_data uses raster layer name when new_name is NULL", {
  skip_on_os("mac")
  data_df <- as.data.frame(data)
  result <- atl_add_raster_data(
    data_df,
    raster_data = example_raster, new_name = NULL
  )
  expect_true("lyr.1" %in% names(result))
})