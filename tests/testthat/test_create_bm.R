test_that("atl_create_bm works with defaults", {
  bm <- atl_create_bm(buffer = 5000)
  expect_s3_class(bm, "ggplot") # Check if output is a ggplot object
})

test_that("atl_create_bm works with input data", {
  # Create sample data
  sample_data <- data.table::data.table(
    x = c(5.25, 5.26),
    y = c(53.25, 53.26)
  )

  bm <- atl_create_bm(data = sample_data, buffer = 1000)
  expect_s3_class(bm, "ggplot") # Output should be a ggplot object
})


test_that("atl_create_bm handles NULL data correctly", {
  bm <- atl_create_bm(data = NULL)
  expect_s3_class(bm, "ggplot") # Default produces a ggplot object
})

test_that("atl_create_bm fails with invalid input", {
  # Invalid data type
  expect_error(atl_create_bm(data = "invalid"))
})


test_that("atl_create_bm returns ggplot object for default settings", {
  bm <- atl_create_bm(buffer = 500)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm handles NULL data and creates bbox around Griend", {
  bm <- atl_create_bm(data = NULL, buffer = 100)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm errors on invalid option", {
  expect_error(
    atl_create_bm(option = "invalid"),
    "Error: The option must be either 'osm' or 'bathymetry'"
  )
})

test_that("atl_create_bm converts bbox input to data.table", {
  bbox <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 1, ymax = 1))
  bm <- atl_create_bm(data = bbox)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm works with single-point data.frame", {
  df <- data.frame(x = 0, y = 0)
  bm <- atl_create_bm(data = df, buffer = 100)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm returns ggplot for bathymetry option", {
  # create a small raster for testing
  r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 1, ymin = 0, ymax = 1)
  terra::values(r) <- matrix(1:25, 5, 5)
  
  bm <- atl_create_bm(
    data = data.table(x = 0:1, y = 0:1),
    option = "bathymetry",
    raster_data = r,
    shade = FALSE
  )
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm returns ggplot for bathymetry and shade option", {
  skip_on_os("mac")
  # create a small raster for testing
  r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 1, ymin = 0, ymax = 1)
  terra::values(r) <- matrix(1:25, 5, 5)
  
  bm <- atl_create_bm(
    data = data.table(x = 0:1, y = 0:1),
    option = "bathymetry",
    raster_data = r,
    shade = TRUE
  )
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm returns ggplot with asp = NULL", {
  df <- data.frame(x = 0:1, y = 0:1)
  bm <- atl_create_bm(data = df, asp = NULL)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm returns ggplot without scalebar when scalebar = FALSE", {
  df <- data.frame(x = 0:1, y = 0:1)
  bm <- atl_create_bm(data = df, scalebar = FALSE)
  expect_s3_class(bm, "ggplot")
})

test_that("atl_create_bm works with data in different projection", {
  # Create data in EPSG:4326
  coords <- data.table::data.table(
    lon = c(4.8, 4.85),
    lat = c(52.6, 52.65)
  )
  
  # Call function with projection EPSG:4326 (will be transformed internally)
  bm <- atl_create_bm(
    data = coords,
    x = "lon",
    y = "lat",
    buffer = 1000,
    asp = "1:1",
    projection = sf::st_crs(4326),
    option = "osm"
  )
  
  expect_s3_class(bm, "ggplot")
  
  # coord_sf limits should be in UTM31 (approx 650000-660000 / 5900000-5910000)
  xlim <- ggplot2::ggplot_build(bm)$layout$panel_params[[1]]$x.range
  ylim <- ggplot2::ggplot_build(bm)$layout$panel_params[[1]]$y.range
  
  expect_true(all(xlim > 600000 & xlim < 700000))
  expect_true(all(ylim > 5800000 & ylim < 6000000))
})

