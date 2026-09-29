
test_that(
  "atl_transform_dt adds transformed coordinate columns", {
    
    library(data.table)
    
    dt <- data.table(
      x = 650272.5,
      y = 5902705
    )
    
    res <- atl_transform_dt(dt)
    
    expect_true("x_4326" %in% names(res))
    expect_true("y_4326" %in% names(res))
    expect_true("x" %in% names(res))
    expect_true("y" %in% names(res))
  }
)


test_that(
  "atl_transform_dt returns numeric transformed coordinates", {
    
    library(data.table)
    
    dt <- data.table(
      x = 650272.5,
      y = 5902705
    )
    
    res <- atl_transform_dt(dt)
    
    expect_type(res$x_4326, "double")
    expect_type(res$y_4326, "double")
  }
)


test_that(
  "atl_transform_dt sets CRS attribute correctly", {
    
    library(data.table)
    library(sf)
    
    dt <- data.table(
      x = 650272.5,
      y = 5902705
    )
    
    res <- atl_transform_dt(dt)
    
    crs_attr <- attr(res, "crs")
    
    expect_s3_class(crs_attr, "crs")
    expect_equal(crs_attr$epsg, 4326)
  }
)


test_that(
  "atl_transform_dt works with custom coordinate names", {
    
    library(data.table)
    
    dt <- data.table(
      east = 650272.5,
      north = 5902705
    )
    
    res <- atl_transform_dt(
      data = dt,
      x = "east",
      y = "north"
    )
    
    expect_true("east_4326" %in% names(res))
    expect_true("north_4326" %in% names(res))
  }
)


test_that(
  "atl_transform_dt returns unchanged empty data", {
    
    library(data.table)
    
    dt <- data.table(
      x = numeric(),
      y = numeric()
    )
    
    res <- atl_transform_dt(dt)
    
    expect_equal(res, dt)
    expect_null(attr(res, "crs"))
  }
)

test_that("atl_transform_dt() stops when target CRS has no EPSG code", {
  
  data <- data.table::data.table(
    x = c(663000, 664000),
    y = c(5905000, 5906000)
  )
  
  # create a CRS without an EPSG code using a WKT proj string
  crs_no_epsg <- sf::st_crs(
    "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000"
  )
  
  expect_error(
    atl_transform_dt(
      data = data,
      from = sf::st_crs(32631),
      to = crs_no_epsg
    ),
    "Target CRS has no EPSG code."
  )
})
