#' Compare residence patches between two parameter sets
#'
#' \code{atl_compare_res_patch_parm} identifies how residence patches change
#' when \code{atl_res_patch} is run with different parameters on the same
#' tracking data. The function compares patch assignments fix-by-fix and
#' classifies changes into four categories: (1) patches that are lost
#' (existed in v1 but not in v2), (2) patches that are gained
#' (new in v2, absent in v1), (3)
#' splits (one v1 patch becomes multiple v2 patches), and (4) merges (multiple
#' v1 patches collapse into one v2 patch). Note that simple renumbering of
#' patches due to an upstream split is not considered a true change, as the
#' fix membership of those patches remains identical.
#'
#' @author Johannes Krietsch
#' @param data_v1 A data.table with residence patches assigned using the first
#' parameter set. Must contain the columns \code{posID}, \code{tag},
#' \code{tideID}, \code{datetime}, \code{x}, \code{y}, and \code{patch}.
#' Data must be ordered by tag and time and can contain multiple tags.
#' @param data_v2 A data.table with residence patches assigned using the second
#' parameter set. Must have the same structure and row order as
#' \code{data_v1}, as patch columns are compared position-by-position.
#' @param quietly Logical. If `TRUE`, no summary messages are
#'   printed. Default is `FALSE`.
#'
#' @return A data.table summarising all detected patch changes with columns
#' \code{tag}, \code{tideID}, \code{change} (one of \code{"lost"},
#' \code{"gained"}, \code{"split"}, or \code{"merge"}), \code{patch_v1},
#' and \code{patch_v2}. For merges, \code{patch_v1} contains a
#' comma-separated list of the v1 patch IDs that merged. For splits,
#' \code{patch_v2} contains a comma-separated list of the resulting v2
#' patch IDs. The function also prints a summary of the number of changes
#' per category.
#' @import data.table
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # run atl_res_patch with two different parameter sets
#' data_v1 <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 3, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 2, min_duration = 60
#' )
#' data_v2 <- atl_res_patch(
#'   data[tag == "3038"],
#'   max_speed = 5, lim_spat_indep = 75, lim_time_indep = 180,
#'   min_fixes = 2, min_duration = 60
#' )
#'
#' # change summary
#' atl_compare_res_patch_summary(data_v1, data_v2)
#' @export
atl_compare_res_patch_summary <- function(data_v1,
                                          data_v2,
                                          quietly = FALSE) {

  # Initialize necessary variables to avoid NSE (Non-Standard Evaluation) issues
  patch_v1 <- patch_v2 <- n_v2_patches <- v2_patches <- n_v1_patches <- NULL
  v1_patches <- lost <- gained <- change <- tag <- tideID <- NULL # nolint
  datetime <- x <- y <- patch <- posID <- . <- NULL # nolint

  # validate input
  assertthat::assert_that(is.data.frame(data_v1),
    msg = glue::glue("Input is not a data.frame or data.table, it has class
                     {stringr::str_flatten(class(data), collapse = ' ')}")
  )
  assertthat::assert_that(is.data.frame(data_v2),
    msg = glue::glue("Input is not a data.frame or data.table, it has class
                     {stringr::str_flatten(class(data), collapse = ' ')}")
  )

  # check data structure
  required_columns <- c("posID", "tag", "tideID", "datetime", "x", "y", "patch")
  atl_check_data(data_v1, names_expected = required_columns)
  atl_check_data(data_v2, names_expected = required_columns)

  # comparison table
  comparison <- data_v1[
    , .(posID, tag, tideID, datetime, x, y, patch_v1 = patch)
  ]
  comparison <- merge(
    comparison,
    data_v2[, .(posID, tag, patch_v2 = patch)],
    by = c("posID", "tag"),
    all = TRUE
  )

  # splits: one v1 patch → multiple v2 patches
  patch_identity <- comparison[!is.na(patch_v1),
    {
      v2_patches <- unique(patch_v2[!is.na(patch_v2)])
      .(n_v2_patches = length(v2_patches), v2_patches = list(v2_patches))
    },
    by = .(tag, tideID, patch_v1)
  ]

  splits <- patch_identity[n_v2_patches > 1]

  # merges: multiple v1 patches → one v2 patch
  merge_check <- comparison[!is.na(patch_v2),
    {
      v1_patches <- unique(patch_v1[!is.na(patch_v1)])
      .(n_v1_patches = length(v1_patches), v1_patches = list(v1_patches))
    },
    by = .(tag, tideID, patch_v2)
  ]

  merges <- merge_check[n_v1_patches > 1]

  # lost/gained patches (patch level)
  lost_patches <- comparison[!is.na(patch_v1),
    .(lost = all(is.na(patch_v2))),
    by = .(tag, tideID, patch_v1)
  ][lost == TRUE]

  gained_patches <- comparison[!is.na(patch_v2),
    .(gained = all(is.na(patch_v1))),
    by = .(tag, tideID, patch_v2)
  ][gained == TRUE]

  # summary table
  summary_splits <- splits[,
    {
      .(
        change = "split",
        patch_v1 = as.character(patch_v1),
        patch_v2 = paste(unlist(v2_patches), collapse = ", ")
      )
    },
    by = .(tag, tideID, patch_v1)
  ][, patch_v1 := NULL]

  summary_merges <- merges[,
    {
      .(
        change = "merge",
        patch_v1 = paste(unlist(v1_patches), collapse = ", "),
        patch_v2 = as.character(patch_v2)
      )
    },
    by = .(tag, tideID, patch_v2)
  ][, patch_v2 := NULL]

  summary_lost <- lost_patches[,
    {
      .(
        change = "lost",
        patch_v1 = as.character(patch_v1),
        patch_v2 = NA_character_
      )
    },
    by = .(tag, tideID, patch_v1)
  ][, patch_v1 := NULL]

  summary_gained <- gained_patches[,
    {
      .(
        change = "gained",
        patch_v1 = NA_character_,
        patch_v2 = as.character(patch_v2)
      )
    },
    by = .(tag, tideID, patch_v2)
  ][, patch_v2 := NULL]

  change_summary <- rbindlist(
    list(summary_splits, summary_merges, summary_lost, summary_gained),
    use.names = TRUE
  )
  setorder(change_summary, tag, tideID, change)

  # print
  if (!quietly) {
    cat("=== Patch changes summary ===\n")
    cat("Lost    (v1 patches gone in v2) :", nrow(lost_patches), "\n")
    cat("Gained  (new patches in v2)     :", nrow(gained_patches), "\n\n")
    cat("Splits  (one v1 -> multiple v2):", nrow(splits), "\n")
    cat("Merges  (multiple v1 -> one v2):", nrow(merges), "\n\n")
  }

  # return
  change_summary
}
