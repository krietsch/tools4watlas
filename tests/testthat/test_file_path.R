
test_that("atl_file_path returns correct paths for recognized users", {
  mockery::stub(atl_file_path, "Sys.info", function() list(user = "jkrietsch"))
  expect_equal(atl_file_path("watlas_teams"), "C:/Users/jkrietsch/OneDrive - NIOZ/WATLAS_data/")
  expect_equal(atl_file_path("rasters"), "C:/Users/jkrietsch/OneDrive - NIOZ/Documents/map_data/")
  expect_equal(atl_file_path("shapefiles"), "C:/Users/jkrietsch/OneDrive - NIOZ/Documents/map_data/")
})

test_that("atl_file_path throws an error for unrecognized users", {
  mockery::stub(atl_file_path, "Sys.info", function() list(user = "unknown_user"))
  expect_error(atl_file_path("watlas_teams"), "User not recognized")
})

test_that("atl_file_path handles invalid data types", {
  mockery::stub(atl_file_path, "Sys.info", function() list(user = "allert"))
  expect_error(atl_file_path("invalid_type"), "'arg' should be one of")
})
