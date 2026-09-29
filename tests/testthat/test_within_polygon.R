
test_that("atl_within_polygon adds logical column to data", {
  data <- data_example
  
  griend_east <- sf::st_sfc(
    sf::st_point(c(5.275, 53.2523)),
    crs = sf::st_crs(4326)
  ) |>
    sf::st_transform(crs = sf::st_crs(32631))
  bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
  bbox_sf <- sf::st_as_sfc(bbox_crop) |>
    sf::st_set_crs(sf::st_crs(32631))
  
  result <- atl_within_polygon(data, polygon = bbox_sf)
  
  expect_true("bbox_sf" %in% names(result))
  expect_type(result$bbox_sf, "logical")
})

test_that("atl_within_polygon col_name argument works", {
  data <- data_example
  
  griend_east <- sf::st_sfc(
    sf::st_point(c(5.275, 53.2523)),
    crs = sf::st_crs(4326)
  ) |>
    sf::st_transform(crs = sf::st_crs(32631))
  bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
  bbox_sf <- sf::st_as_sfc(bbox_crop) |>
    sf::st_set_crs(sf::st_crs(32631))
  
  result <- atl_within_polygon(
    data, polygon = bbox_sf, col_name = "in_area"
  )
  
  expect_true("in_area" %in% names(result))
  expect_type(result$in_area, "logical")
})

test_that("atl_within_polygon detects points inside polygon", {
  data <- data_example
  
  griend_east <- sf::st_sfc(
    sf::st_point(c(5.275, 53.2523)),
    crs = sf::st_crs(4326)
  ) |>
    sf::st_transform(crs = sf::st_crs(32631))
  bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
  bbox_sf <- sf::st_as_sfc(bbox_crop) |>
    sf::st_set_crs(sf::st_crs(32631))
  
  result <- atl_within_polygon(
    data, polygon = bbox_sf, col_name = "in_area"
  )
  
  expect_true(any(result$in_area))
  expect_true(any(!result$in_area))
})

test_that("atl_within_polygon TRUE rows are inside polygon", {
  data <- data_example
  
  griend_east <- sf::st_sfc(
    sf::st_point(c(5.275, 53.2523)),
    crs = sf::st_crs(4326)
  ) |>
    sf::st_transform(crs = sf::st_crs(32631))
  bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
  bbox_sf <- sf::st_as_sfc(bbox_crop) |>
    sf::st_set_crs(sf::st_crs(32631))
  
  result <- atl_within_polygon(
    data, polygon = bbox_sf, col_name = "in_area"
  )
  
  inside <- result[result$in_area == TRUE, ]
  expect_true(all(
    data.table::between(inside$x, bbox_crop["xmin"], bbox_crop["xmax"]) &
      data.table::between(inside$y, bbox_crop["ymin"], bbox_crop["ymax"])
  ))
})

test_that("atl_within_polygon does not change number of rows", {
  data <- data_example
  
  griend_east <- sf::st_sfc(
    sf::st_point(c(5.275, 53.2523)),
    crs = sf::st_crs(4326)
  ) |>
    sf::st_transform(crs = sf::st_crs(32631))
  bbox_crop <- atl_bbox(griend_east, asp = "16:9", buffer = 2000)
  bbox_sf <- sf::st_as_sfc(bbox_crop) |>
    sf::st_set_crs(sf::st_crs(32631))
  
  result <- atl_within_polygon(
    data, polygon = bbox_sf, col_name = "in_area"
  )
  
  expect_equal(nrow(result), nrow(data))
})

test_that("atl_within_polygon errors on non-data.frame input", {
  bbox_sf <- sf::st_as_sfc(sf::st_bbox(c(
    xmin = 0, xmax = 1, ymin = 0, ymax = 1
  ), crs = sf::st_crs(32631)))
  
  expect_error(
    atl_within_polygon(list(x = 1, y = 2), polygon = bbox_sf),
    "not a dataframe"
  )
})

test_that("atl_within_polygon errors when polygon is not sf/sfc", {
  data <- data_example
  
  expect_error(
    atl_within_polygon(data, polygon = data.frame(x = 1, y = 2)),
    "not class sf or sfc"
  )
})

test_that("atl_within_polygon errors on non-polygon geometry", {
  data <- data_example
  point <- sf::st_sfc(
    sf::st_point(c(663000, 5905000)),
    crs = sf::st_crs(32631)
  )
  
  expect_error(
    atl_within_polygon(data, polygon = point),
    "not \\*POLYGON"
  )
})

test_that("atl_within_polygon errors when polygon has no CRS", {
  data <- data_example
  bbox_sf <- sf::st_as_sfc(sf::st_bbox(c(
    xmin = 0, xmax = 1, ymin = 0, ymax = 1
  ))) |>
    sf::st_set_crs(NA)
  
  expect_error(
    atl_within_polygon(data, polygon = bbox_sf),
    "no CRS"
  )
})

test_that("atl_within_polygon errors when polygon CRS is not EPSG:32631", {
  data <- data_example
  bbox_sf <- sf::st_as_sfc(sf::st_bbox(c(
    xmin = 5.0, xmax = 5.5, ymin = 53.0, ymax = 53.5
  ), crs = sf::st_crs(4326)))
  
  expect_error(
    atl_within_polygon(data, polygon = bbox_sf),
    "EPSG:32631"
  )
})
