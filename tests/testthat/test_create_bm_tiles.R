test_that(
  "atl_create_bm_tiles works with defaults", {
    skip_on_os("mac")
    
    bm <- atl_create_bm_tiles(buffer = 500)

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles works with input data", {
    skip_on_os("mac")

    dt <- data.table::data.table(
      x = 650272.5,
      y = 5902705
    )

    bm <- atl_create_bm_tiles(data = dt, buffer = 100)

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles handles NULL data", {
    skip_on_os("mac")

    bm <- atl_create_bm_tiles(data = NULL, buffer = 100)

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles converts bbox input", {
    skip_on_os("mac")

    bbox <- sf::st_bbox(
      c(
        xmin = 650000,
        ymin = 5902500,
        xmax = 650500,
        ymax = 5903000
      ),
      crs = sf::st_crs(32631)
    )

    bm <- atl_create_bm_tiles(data = bbox)

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles works with data.frame input", {
    skip_on_os("mac")

    df <- data.frame(
      x = 650272.5,
      y = 5902705
    )

    bm <- atl_create_bm_tiles(data = df, buffer = 100)

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles works without scalebar", {
    skip_on_os("mac")

    dt <- data.table::data.table(
      x = 650272.5,
      y = 5902705
    )

    bm <- atl_create_bm_tiles(
      data = dt,
      scalebar = FALSE
    )

    expect_s3_class(bm, "ggplot")
  }
)


test_that(
  "atl_create_bm_tiles errors on invalid data", {
    skip_on_os("mac")

    expect_error(
      atl_create_bm_tiles(data = "invalid")
    )
  }
)
