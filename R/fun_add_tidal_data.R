#' Add tidal data to tracking data
#'
#' Adds a unique tide identifier, waterlevel, time from high tide and time to
#' low tide for tracking data (both in minutes).
#'
#' @author Pratik Gupte & Allert Bijleveld & Johannes Krietsch
#' @param data A dataframe with the tracking data with the timestamp column
#' 'datetime' in UTC.
#' @param tide_data Data on the timing (in UTC) of low and high tides.
#' @param tide_data_highres Data on the timing (in UTC) of the waterlevel in
#' small intervals (e.g. every 10 min) as provided from Rijkwaterstaat.
#' @param waterdata_resolution The resolution of the high resolution waterlevel
#' data. This is used for matching the high resolution tidal data to the
#' tracking data. Defaults to 10 minutes but can be set differently.
#' @param waterdata_interpolation Time interval to which the water level data
#' will be interpolated (should be smaller than water data resolution e.g.
#' 1 min). If NULL will keep the original water data resolution.
#' @param offset The offset in minutes between the location of the tidal gauge
#' and the tracking area. This value will be added to the timing of the
#' water data.
#' @return The input data but with three columns added: tideID (a unique number
#' for the tidal period between two consecutive high tides), tidaltime (time
#' since high tide in minutes), time2lowtide (time to low tide in minutes),
#' and waterlevel with reference to NAP (cm).
#' @import data.table
#'
#' @examples
#' # packages
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # delete existing tide data columns to show how they are added
#' data[, c("tideID", "tidaltime", "time2lowtide", "waterlevel") := NULL]
#'
#' # sub path to tide data
#' tidal_pattern_fp <- system.file(
#'   "extdata", "example-tidalPattern-west_terschelling-UTC.csv",
#'   package = "tools4watlas"
#' )
#' measured_water_height_fp <- system.file(
#'   "extdata", "example-gemeten_waterhoogte-west_terschelling-clean-UTC.csv",
#'   package = "tools4watlas"
#' )
#'
#' # load tide data
#' tidal_pattern <- fread(tidal_pattern_fp)
#' measured_water_height <- fread(measured_water_height_fp)
#'
#' # add tide data to movement data
#' # The offset of 30 minutes is set to match Griend.
#' data <- atl_add_tidal_data(
#'   data = data,
#'   tide_data = tidal_pattern,
#'   tide_data_highres = measured_water_height,
#'   waterdata_resolution = "10 min",
#'   waterdata_interpolation = "1 min",
#'   offset = 30
#' )
#'
#' # show first 5 rows (subset of columns to show additional ones)
#' head(data[, .(tag, datetime, tideID, tidaltime, time2lowtide, waterlevel)])
#' @export
atl_add_tidal_data <- function(data,
                               tide_data,
                               tide_data_highres,
                               waterdata_resolution = "10 min",
                               waterdata_interpolation = NULL,
                               offset = 0) {
  # global variables
  row_id <- low_time <- . <- NULL
  tideID <- time <- tidaltime <- high_start_time <- dateTime <- NULL # nolint
  temp_time <- waterlevel <- datetime <- time2lowtide <- NULL

  # check data format
  assertthat::assert_that(
    inherits(data, "data.frame"),
    msg = "Data not a data.frame object!"
  )

  # check data availability in tracking data
  assertthat::assert_that(
    nrow(data) > 0,
    msg = "Input doesn't have any rows"
  )

  # check if datetime is POSIXct
  assertthat::assert_that(
    inherits(data$datetime, "POSIXct"),
    msg = "datetime must be a POSIXct object!"
  )

  # check columns are not present already
  cols_tidal <- c("tideID", "tidaltime", "time2lowtide", "waterlevel")
  cols_exist <- cols_tidal[cols_tidal %in% names(data)]
  assertthat::assert_that(
    length(cols_exist) == 0,
    msg = paste(
      "Columns",
      paste(cols_exist, collapse = ", "),
      "exist already, water data already present?"
    )
  )

  # convert to data.table if not
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  if (!data.table::is.data.table(tide_data)) {
    data.table::setDT(tide_data)
  }
  if (!data.table::is.data.table(tide_data_highres)) {
    data.table::setDT(tide_data_highres)
  }

  # to get back original order
  col_order <- copy(colnames(data))

  # create row id (to order back to original order at the end)
  data[, row_id := .I]

  # order tracking data
  data.table::setorder(data, datetime) # order data on time

  # process tidal data
  setattr(tide_data$high_start_time, "tzone", "UTC") # time zone to UTC
  tide_data[, high_start_time := high_start_time + offset * 60] # add offset
  tide_data[, low_time := low_time + offset * 60] # 60 because offset is in min
  high_tide_data <- tide_data[, .(high_start_time, tideID)]

  # merge tracking and tidal data to get time from high tide
  temp_data <- data.table::merge.data.table(
    data, high_tide_data,
    by.x = "datetime", by.y = "high_start_time",
    all = TRUE
  )
  data.table::setorder(temp_data, datetime)

  # expand tide ID to NA
  temp_data[, tideID := data.table::nafill(tideID, "locf")]
  temp_data[, tidaltime := as.numeric(difftime(
    datetime, datetime[1],
    units = "mins"
  )), by = tideID]
  temp_data <- temp_data[!is.na(row_id)]

  # add time2lowtide
  temp_data[tide_data,
    time2lowtide := as.numeric(difftime(datetime, low_time, units = "mins")),
    on = "tideID"
  ]

  # add waterlevel to tracking data
  setattr(tide_data_highres$dateTime, "tzone", "UTC")
  tide_data_highres[, dateTime := dateTime + offset * 60]

  # merge with original waterdata_resolution or interpolate data
  if (is.null(waterdata_interpolation)) {
    # original water data resolution
    temp_data[, temp_time := lubridate::round_date(
      datetime,
      unit = waterdata_resolution
    )]
    # merge with movement data
    temp_data <- data.table::merge.data.table(
      temp_data, tide_data_highres[, .(dateTime, waterlevel)],
      by.x = "temp_time", by.y = "dateTime"
    )
  } else {
    # interpolated resolution
    temp_data[, temp_time := lubridate::round_date(
      datetime,
      unit = waterdata_interpolation
    )]
    # create sequence within the tracking data interval
    dw_int <- data.table(
      dateTime = seq(
        min(temp_data$temp_time) - 3600,
        max(temp_data$temp_time) + 3600,
        by = waterdata_interpolation
      )
    )
    # merge
    dw_int <- merge(
      dw_int, unique(tide_data_highres),
      by = "dateTime", all.x = TRUE
    )
    # interpolate missing values
    dw_int[, waterlevel := zoo::na.approx(waterlevel, dateTime, rule = 2)]
    dw_int[, waterlevel := round(waterlevel, 1)]
    # merge with movement data
    temp_data <- data.table::merge.data.table(
      temp_data, dw_int[, .(dateTime, waterlevel)],
      by.x = "temp_time", by.y = "dateTime"
    )
  }

  # set order back
  data.table::setorder(temp_data, row_id) # order data on time

  # clean data
  temp_data[, c("temp_time", "row_id") := NULL]
  setcolorder(temp_data, col_order)

  # remove offset
  tide_data[, high_start_time := high_start_time - offset * 60] # add offset
  tide_data[, low_time := low_time - offset * 60] # 60 because offset is in min
  tide_data_highres[, dateTime := dateTime - offset * 60]

  # export
  temp_data
}
