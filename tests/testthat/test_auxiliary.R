
# Tests for atl_spec_cols

# Test that function returns a named vector when option is "vector"
test_that("atl_spec_cols returns named vector", {
  result <- atl_spec_cols("vector")
  expect_type(result, "character")
  expect_named(result)
  expect_true(all(nzchar(names(result))))
})

# Test that function returns a data.table when option is "table"
test_that("atl_spec_cols returns data.table", {
  result <- atl_spec_cols("table")
  expect_s3_class(result, "data.table")
  expect_true(all(c("species", "colour") %in% colnames(result)))
  expect_equal(nrow(result), length(atl_spec_cols("vector")))
})

# Test that function defaults to "vector" output
test_that("atl_spec_cols defaults to vector", {
  result <- atl_spec_cols()
  expect_type(result, "character")
})

# Test invalid input handling
test_that("atl_spec_cols handles invalid input", {
  expect_error(atl_spec_cols("invalid"), 
               "'arg' should be one of \"vector\", \"table\"")
})

# Tests for atl_spec_labs

# Test that function returns a named vector
test_that("atl_spec_labs returns named vector", {
  result <- atl_spec_labs("multiline")
  expect_type(result, "character")
  expect_named(result)
  expect_true(all(nzchar(names(result))))
})

# Test multiline output format
test_that("atl_spec_labs multiline format contains newlines", {
  result <- atl_spec_labs("multiline")
  expect_true(any(grepl("\\n", result)))
})

# Test singleline output format
test_that("atl_spec_labs singleline format does not contain newlines", {
  result <- atl_spec_labs("singleline")
  expect_false(any(grepl("\\n", result)))
})

# Test function defaults to "multiline" output
test_that("atl_spec_labs defaults to multiline", {
  result <- atl_spec_labs()
  expect_true(any(grepl("\\n", result)))
})

# Test function defaults to "short_multiline" output
test_that("atl_spec_labs defaults to multiline", {
  result <- atl_spec_labs("short_multiline")
  expect_true(any(grepl("\\n", result)))
})

# Test function defaults to "short_singleline" output
test_that("atl_spec_labs defaults to multiline", {
  result <- atl_spec_labs("short_singleline")
  expect_false(any(grepl("\\n", result)))
})

# Test invalid input handling
test_that("atl_spec_labs handles invalid input", {
  expect_error(atl_spec_labs("invalid"), 
               "'arg' should be one of \"multiline\", \"singleline\"")
})


# tests for atl_tag_cols()
test_that("atl_tag_cols returns named vector by default", {
  # create example tags
  tags <- c("a", "b", "c")
  
  # run function
  res <- atl_tag_cols(tags)
  
  # check class and structure
  expect_type(res, "character")
  expect_named(res, tags)
  expect_true(all(grepl("^#", res))) # check for hex color format
  expect_equal(length(res), length(unique(tags)))
})

test_that("atl_tag_cols returns data.table when option = 'table'", {
  # create example tags
  tags <- c("x", "y", "z")
  
  # run function
  res <- atl_tag_cols(tags, option = "table")
  
  # check class and columns
  expect_s3_class(res, "data.table")
  expect_true(all(c("tag", "colour") %in% names(res)))
  expect_true(all(res$tag %in% tags))
  expect_true(all(grepl("^#", res$colour)))
  expect_equal(nrow(res), length(unique(tags)))
})

test_that("atl_tag_cols handles numeric tags correctly", {
  # create numeric tags
  tags <- c(101, 202, 303)
  
  # run function
  res <- atl_tag_cols(tags)
  
  # check names are character
  expect_named(res, as.character(tags))
  expect_true(all(grepl("^#", res)))
})

test_that("atl_tag_cols removes duplicates", {
  # create duplicated tags
  tags <- c("a", "a", "b")
  
  # run function
  res <- atl_tag_cols(tags)
  
  # check unique length
  expect_equal(length(res), length(unique(tags)))
})

test_that("atl_tag_cols fails with invalid option", {
  # invalid option should error
  expect_error(atl_tag_cols(c("a", "b"), option = "wrong"))
})


# Tests for atl_t_col

# Test valid color conversion
test_that("atl_t_col returns correct transparent color", {
  result <- atl_t_col("blue", percent = 50)
  expect_type(result, "character")
  expect_match(result, "#", fixed = TRUE)
})

# Test transparency limits
test_that("atl_t_col handles transparency limits", {
  result_0 <- atl_t_col("red", percent = 0)
  result_100 <- atl_t_col("red", percent = 100)
  expect_match(result_0, "FF", fixed = TRUE)  # Fully opaque
  expect_match(result_100, "00", fixed = TRUE) # Fully transparent
})

# Test invalid color input
test_that("atl_t_col handles invalid color input", {
  expect_error(atl_t_col(123),
               "The 'color' parameter should be a single character string.")
  expect_error(atl_t_col(c("red", "blue")),
               "The 'color' parameter should be a single character string.")
})

# Test invalid percent input
test_that("atl_t_col handles invalid percent input", {
  expect_error(atl_t_col("blue", percent = -10),
               "The 'percent' parameter should be a numeric value between 0" )
  expect_error(atl_t_col("blue", percent = 110),
               "The 'percent' parameter should be a numeric value between 0" )
  expect_error(atl_t_col("blue", percent = "fifty"),
               "The 'percent' parameter should be a numeric value between 0" )
})

# tests for atl_tag_labs()
test_that("atl_tag_labs creates correct labels", {
  # create example data
  data <- data.table::data.table(
    tag = c("t1", "t2", "t1"),
    rings = c(1001, 2002, 1001),
    name = c("alice", "bob", "carol")
  )
  
  # run function
  res <- atl_tag_labs(data, c("rings", "name"))
  
  # check structure
  expect_type(res, "character")
  expect_named(res, c("t1", "t2"))
  expect_equal(unname(res["t1"]), "1001 alice")
  expect_equal(unname(res["t2"]), "2002 bob")
})

test_that("atl_tag_labs handles custom separator", {
  # create example data
  data <- data.table::data.table(
    tag = c("a", "b"),
    rings = c(11, 22),
    name = c("x", "y")
  )
  
  # run with custom separator
  res <- atl_tag_labs(data, c("rings", "name"), sep = "_")
  
  # check separator used
  expect_equal(unname(res["a"]), "11_x")
  expect_equal(unname(res["b"]), "22_y")
})

test_that("atl_tag_labs replaces NA values with empty strings", {
  # create example data with NA
  data <- data.table::data.table(
    tag = c("t1", "t2"),
    rings = c(1, NA),
    name = c("sam", "lee")
  )
  
  # run function
  res <- atl_tag_labs(data, c("rings", "name"))
  
  # check na handling
  expect_equal(unname(res["t1"]), "1 sam")
  expect_equal(unname(res["t2"]), " lee")
})

test_that("atl_tag_labs errors if 'tag' column missing", {
  # create data without tag
  data <- data.table::data.table(id = c(1, 2), name = c("a", "b"))
  
  # check error
  expect_error(atl_tag_labs(data, c("id", "name")),
               "Error: 'tag' column is missing")
})

test_that("atl_tag_labs errors if required columns missing", {
  # create incomplete data
  data <- data.table::data.table(tag = c("x", "y"), rings = c(1, 2))
  
  # check error
  expect_error(
    atl_tag_labs(data, c("rings", "name")),
    "Error: The following columns are missing"
  )
})

test_that("atl_tag_labs returns one label per unique tag", {
  # create duplicated tags
  data <- data.table::data.table(
    tag = c("a", "a", "b"),
    rings = c(1, 2, 3),
    name = c("x", "y", "z")
  )
  
  # run function
  res <- atl_tag_labs(data, c("rings", "name"))
  
  # check only unique tags kept
  expect_equal(length(res), length(unique(data$tag)))
  expect_equal(unname(res["a"]), "1 x")
})

