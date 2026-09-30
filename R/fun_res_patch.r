#' Construct residence patches from position data
#'
#' A cleaned movement track of one individual at a time can be classified into
#'  residence patches using the
#' function \code{atl_res_patch}.
#' The function expects a specific organisation of the data: there should be
#' at least the following columns, \code{x}, \code{y}, and \code{time},
#' corresponding to the coordinates, and the time as \code{POSIXct}.
#' \code{atl_res_patch} requires only three parameters: (1) the maximum
#' speed threshold between localizations (called \code{max_speed}), (2) the
#' distance threshold between proto-patches of positions (called
#' \code{lim_spat_indep}), and (3) the time interval between proto-patches
#' (called \code{lim_time_indep}). As the code initially only looks at
#' proto-patches, at the end it checks if positions within patches are
#' interrupted by short flights (with a distance larger than
#' \code{lim_spat_indep} to the last position of the proto-patch before and
#' first position of the next proto-patch). If there are more than
#' \code{min_fixes} in this bout, then the patch will be split. If there are
#' less, we assume this to be single outliers and only assign no patch ID
#'
#' Derived from `atlastools::atl_res_patch()` in the \pkg{atlastools}
#' package (Gupte et al., 2022), licensed under GPL-3.
#'
#' @author Pratik R. Gupte, Christine E. Beardsworth, Allert I. Bijleveld &
#' Johannes Krietsch
#' @references
#' Gupte, P. R., Beardsworth, C. E., Spiegel, O., Lourie, E., Toledo, S.,
#' Nathan, R., & Bijleveld, A. I. (2022). A guide to pre-processing
#' high-throughput animal tracking data. *Journal of Animal Ecology*, 91,
#' 287-307. \doi{10.1111/1365-2656.13610}
#' @param data A dataframe of any class that is or extends data.frame of one
#' individual only. The dataframe must contain at least two spatial coordinates,
#' \code{x} and \code{y}, and a temporal coordinate, \code{time}.
#' @param max_speed A numeric value specifying the maximum speed (m/s) between
#' two coordinates that would be considered non-transitory
#' @param lim_spat_indep A numeric value of distance in metres of the spatial
#' distance between two patches for them to the considered independent.
#' @param lim_time_indep A numeric value of time in minutes of the time
#' difference between two patches for them to be considered independent.
#' @param min_fixes The minimum number of fixes for a group of
#' spatially-proximate number of points to be considered a preliminary residence
#' patch.
#' @param min_duration The minimum duration (in seconds) for classifying
#' residence patches.
#'
#' @return A data.table that has the added column
#' \code{patch} as character indicating the patch ID.
#' @import data.table
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # calculate residence patches for one red knot
#' data <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 2, min_duration = 60
#' )
#'
#' # summary of residence patches
#' data_summary <- atl_res_patch_summary(data)
#' data_summary
#' @export
atl_res_patch <- function(data,
                          max_speed = 3,
                          lim_spat_indep = 75,
                          lim_time_indep = 180,
                          min_fixes = 2,
                          min_duration = 60) {
  # Initialize necessary variables to avoid NSE (Non-Standard Evaluation) issues
  row_id <- newpatch <- nfixes <- patch <- speed <- tag <- duration <- NULL
  patchdata <- spat_diff <- time_diff_end_start <- i.patch <- NULL # nolint
  time <- time_diff <- time_end <- time_start <- spat_diff_end_start <- NULL
  patch_new <- patch_filled <- proto_bout <- far_pre <- far_post <- NULL
  has_flight <- i.has_flight <- x <- y <- x_pre <- x_post <- NULL # nolint
  dist_pre <- dist_post <- outlier <- i.outlier <- NULL # nolint
  y_pre <- y_post <- n_beyond <- NULL

  # Validate input
  assertthat::assert_that(is.data.frame(data),
    msg = glue::glue("Input is not a data.frame or data.table, it has class
                     {stringr::str_flatten(class(data), collapse = ' ')}")
  )
  assertthat::assert_that(
    all(c(max_speed, lim_spat_indep, lim_time_indep, min_fixes) > 0),
    msg = "All input parameters must be positive"
  )
  lim_time_indep <- lim_time_indep * 60 # Convert to seconds

  # Check data structure
  required_columns <- c("x", "y", "time")
  atl_check_data(data, names_expected = required_columns)

  # Convert data to data.table if not already
  if (!is.data.table(data)) {
    data.table::setDT(data)
  }
  data.table::setorderv(data, "time")

  # Delete existing 'patch' column if it exists to avoid conflicts
  if ("patch" %in% names(data)) {
    warning("Column 'patch' already existed and is overwritten.", call. = FALSE)
    data[, patch := NULL]
  }

  # Ensure data is ordered by time
  assertthat::assert_that(min(diff(data$time)) >= 0,
    msg = "Data for segmentation is not ordered by time"
  )

  # Create unique row ID
  data[, row_id := seq_len(nrow(data))]

  # Copy of original data
  data_original <- copy(data)

  tryCatch(expr = {
    # Calculate spatial and time differences
    data[, `:=`(
      spat_diff = atl_simple_dist(data = data, x = "x", y = "y"),
      time_diff = c(Inf, as.numeric(diff(time)))
    )]
    data[1, c("spat_diff")] <- Inf
    data[, `:=`(speed = spat_diff / time_diff)]
    data[1, c("speed")] <- Inf

    # Create proto-patches based on thresholds
    data[, `:=`(patch, cumsum(speed > max_speed | spat_diff >
                                lim_spat_indep | time_diff > lim_time_indep))]

    # Filter based on minimum fixes
    data[, `:=`(nfixes, .N), by = c("tag", "patch")]
    data <- data[nfixes >= min_fixes]
    data[, `:=`(nfixes, NULL)] # remove nfixes-column
    # Subset by id and patch
    data <- data[, list(list(.SD)), by = list(tag, patch)]
    setnames(data, old = "V1", new = "patchdata")
    data[, `:=`(nfixes, as.integer(lapply(patchdata, nrow)))]

    # Summarize patch data
    data[, `:=`(patch_summary, lapply(patchdata, function(dt) {
      dt2 <- dt[, unlist(lapply(.SD, function(d) {
        list(
          median = as.double(stats::median(d)),
          start = as.double(data.table::first(d)),
          end = as.double(data.table::last(d))
        )
      }), recursive = FALSE), .SDcols = c("x", "y", "time")]
      setnames(dt2, sub(".", "_", colnames(dt2), fixed = TRUE))
      dt2
    }))]

    patch_summary <- data[, unlist(patch_summary, recursive = FALSE),
      by = list(tag, patch)
    ]
    data[, `:=`(patch_summary, NULL)]

    # Calculate duration in patch and filter for minimal duration
    patch_summary[, `:=`(duration, as.numeric(time_end) -
                           as.numeric(time_start))]
    patch_summary <- patch_summary[duration > min_duration]

    # Recalculate variables for merging residence patches e.g. distances,
    # time, speed
    # time and distance between patches (between end and start)
    patch_summary[, `:=`(
      time_diff_end_start,
      c(Inf, as.numeric(time_start[2:length(time_start)] -
                          time_end[seq_len(length(time_end) - 1)]))
    )]
    patch_summary[, `:=`(
      spat_diff_end_start,
      c(atl_patch_dist(
        data = patch_summary,
        x1 = "x_end", x2 = "x_start",
        y1 = "y_end", y2 = "y_start"
      ))
    )]
    patch_summary[1, "spat_diff_end_start"] <- Inf
    patch_summary[, `:=`(
      speed_between_patches_end_start =
        patch_summary$spat_diff_end_start / patch_summary$time_diff_end_start
    )]
    patch_summary[1, "speed_between_patches_end_start"] <- Inf

    ## calculate distance between patches based on MEDIAN locations
    patch_summary[, `:=`(spat_diff, c(atl_patch_dist(
      data = patch_summary,
      x1 = "x_median", x2 = "x_median",
      y1 = "y_median", y2 = "y_median"
    )))]
    patch_summary[1, "spat_diff"] <- Inf
    patch_summary[, `:=`(
      speed_between_patches_medianxy =
        patch_summary$spat_diff /
        patch_summary$time_diff_end_start
    )]
    patch_summary[1, "speed_between_patches_medianxy"] <- Inf

    ## create  residence patches on new criteria
    ### new patch without speed filter & with spatial distance on end-start
    patch_summary[, `:=`(newpatch, cumsum(
      ((spat_diff > lim_spat_indep &
          spat_diff_end_start > lim_spat_indep) |
         time_diff_end_start > lim_time_indep)
    ))]

    # Merge new patches with initial proto-patches
    patch_summary <- patch_summary[, list(patch, newpatch)]
    data <- data[, unlist(patchdata, recursive = FALSE), by = list(tag, patch)]
    data <- data.table::merge.data.table(data, patch_summary, by = "patch")
    data[, `:=`(patch = newpatch, newpatch = NULL)]

    # Add patch ID to original data
    data_original[data, on = "row_id", `:=`(patch = i.patch)]

    # Fill positions that where excluded from proto-patches
    # Apply forward and backward fill
    fwd <- zoo::na.locf(data_original$patch, na.rm = FALSE)
    bwd <- zoo::na.locf(data_original$patch, fromLast = TRUE, na.rm = FALSE)

    # Fill only where both directions agree
    data_original[,
      patch_filled := ifelse(is.na(patch) & fwd == bwd, fwd, patch)
    ]

    # subset patch data and check for flights within patches
    patch_data <- data_original[!is.na(patch_filled)]

    # NA bouts
    patch_data[, proto_bout := rleid(is.na(patch))]

    # calculate distance between last proto-patch position and every NA in gap
    # reference positions: last before (locf) and first after (nocb) each NA row
    patch_data[, `:=`(
      x_pre = nafill(fifelse(is.na(patch), NA_real_, x), type = "locf"),
      y_pre = nafill(fifelse(is.na(patch), NA_real_, y), type = "locf"),
      x_post = nafill(fifelse(is.na(patch), NA_real_, x), type = "nocb"),
      y_post = nafill(fifelse(is.na(patch), NA_real_, y), type = "nocb")
    )]

    # distances to reference positions
    patch_data[is.na(patch), `:=`(
      dist_pre  = sqrt((x - x_pre)^2  + (y - y_pre)^2),
      dist_post = sqrt((x - x_post)^2 + (y - y_post)^2)
    )]

    # flag beyond threshold and count rows where both are beyond
    patch_data[is.na(patch), `:=`(
      far_pre  = dist_pre  > lim_spat_indep,
      far_post = dist_post > lim_spat_indep
    )]
    patch_data[
      is.na(patch), n_beyond := sum(far_pre & far_post),
      by = proto_bout
    ]

    # flag more than min_fixes and single outliers
    patch_data[
      is.na(patch), has_flight := n_beyond > min_fixes,
      by = proto_bout
    ]
    patch_data[is.na(patch) & !has_flight & far_pre & far_post, outlier := TRUE]

    # Filter based bouts with flights and outliers
    outliers_data <- patch_data[outlier == TRUE]
    patch_data <- patch_data[has_flight == TRUE]

    # Merge flight ID and outliers back to original data
    data_original[patch_data, on = "row_id", has_flight := i.has_flight]

    # Set patch to NA where there is a flight
    data_original[!is.na(has_flight), patch_filled := NA]

    # Reassign patch ID's to take care of split patches
    data_original[, patch_new := rleid(patch_filled)]
    data_original[is.na(patch_filled), patch_new := NA]
    data_original[,
      patch := match(patch_new, unique(stats::na.omit(patch_new)))
    ]
    data_original[, patch_new := NULL]

    # Now remove outliers from patches
    data_original[outliers_data, on = "row_id", outlier := i.outlier]
    data_original[outlier == TRUE, patch := NA]

    # Remove row_id and patch filled
    data_original[,
      c("row_id", "has_flight", "outlier", "patch_filled") := NULL
    ]

    # make patch a factor
    data_original[, patch := as.character(patch)]

    return(data_original)
  }, error = function(e) {
    message(glue::glue("there was an error in {unique(data$tag)}:\n
                       {as.character(e)}"))
  })
}
