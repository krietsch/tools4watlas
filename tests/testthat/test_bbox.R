
# Test that the function works with a simple polygon geometry
test_that("atl_bbox handles simple geometry", {
  geom <- sf::st_as_sfc("POLYGON((0 0, 1 0, 1 2, 0 2, 0 0))")
  bbox <- atl_bbox(geom, asp = "16:9")
  # Ensure the bbox has 4 elements (xmin, ymin, xmax, ymax)
  expect_equal(length(bbox), 4)
  # Check names
  expect_true(all(names(bbox) %in% c("xmin", "ymin", "xmax", "ymax")))
})

# Test buffer functionality (expanding the bounding box)
test_that("atl_bbox applies buffer correctly short format", {
  geom <- sf::st_as_sfc("POLYGON((0 0, 1 0, 1 2, 0 2, 0 0))")
  bbox_no_buffer <- atl_bbox(geom, asp = "16:9", buffer = 0)
  bbox_with_buffer <- atl_bbox(geom, asp = "16:9", buffer = 0.5)

  # Ensure the bounding box with buffer is larger than the one without buffer
  expect_true(bbox_with_buffer["xmax"] > bbox_no_buffer["xmax"])
  expect_true(bbox_with_buffer["ymax"] > bbox_no_buffer["ymax"])
  expect_true(bbox_with_buffer["xmin"] < bbox_no_buffer["xmin"])
  expect_true(bbox_with_buffer["ymin"] < bbox_no_buffer["ymin"])
})

test_that("atl_bbox errors if buffer <= 0 for single-point sf geometry", {
  # create single-point sf geometry
  point_sf <- sf::st_as_sfc("POINT(0 0)")
  
  # expect error if buffer <= 0
  expect_error(
    atl_bbox(point_sf, buffer = 0),
    "Buffer must be >0 if geometry is a single point"
  )
  expect_error(
    atl_bbox(point_sf, buffer = -1),
    "Buffer must be >0 if geometry is a single point"
  )
})

# Test buffer functionality (expanding the bounding box)
test_that("atl_bbox applies buffer correctly long format", {
  geom <- sf::st_as_sfc("POLYGON((0 0, 5 0, 1 2, 0 2, 0 0))")
  bbox_no_buffer <- atl_bbox(geom, asp = "1:1", buffer = 0)
  bbox_with_buffer <- atl_bbox(geom, asp = "1:1", buffer = 0.5)

  # Ensure the bounding box with buffer is larger than the one without buffer
  expect_true(bbox_with_buffer["xmax"] > bbox_no_buffer["xmax"])
  expect_true(bbox_with_buffer["ymax"] > bbox_no_buffer["ymax"])
  expect_true(bbox_with_buffer["xmin"] < bbox_no_buffer["xmin"])
  expect_true(bbox_with_buffer["ymin"] < bbox_no_buffer["ymin"])
})

# Test error handling for invalid aspect ratio format
test_that("atl_bbox throws an error for invalid asp ratio format", {
  geom <- sf::st_as_sfc("POLYGON((0 0, 1 0, 1 2, 0 2, 0 0))")

  expect_error(
    atl_bbox(geom, asp = "16-9"),
    "Aspect ratio must be in the format 'width:height'."
  )
  expect_error(
    atl_bbox(geom, asp = "16:9:1"),
    "Aspect ratio must be in the format 'width:height'."
  )
})

test_that("atl_bbox returns original bbox if asp is NULL", {
  # simple rectangle data.frame
  df <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1)
  )
  
  # get bbox with asp = NULL
  result <- atl_bbox(df, asp = NULL, buffer = 0)
  
  # check that returned object is a bbox
  expect_s3_class(result, "bbox")
  
  # check that the values match the original bbox
  original_bbox <- sf::st_bbox(c(
    xmin = min(df$x), ymin = min(df$y),
    xmax = max(df$x), ymax = max(df$y)
  ))
  expect_equal(result, original_bbox)
})
