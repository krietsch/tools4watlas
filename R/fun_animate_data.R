# Contains all functions related to making animations

#' Generate time steps and file names for an animation of movements
#'
#' This function creates a sequence of time steps based on a given datetime
#' vector and time interval. It also generates corresponding file names in a
#' provided folder path for each time step. The function also gives a message
#' showing the total number of frames (also saves this as text file, to be used
#' when plotting a progress bar) and how long the animation would take, giving
#' a set fps (frames per second).
#'
#' @author Johannes Krietsch
#' @param datetime_vector A vector of datetime values (POSIXct or similar).
#' Can be a min and max or simple a full vector from the data
#' @param time_interval A character string specifying the time interval
#' (e.g., "30 sec", "10 min", "1 hour").
#' @param output_path A character string specifying the directory of the folder
#' where the files will be saved.
#' @param create_path A logical value. If TRUE, the function creates the
#' directory if it does not exist.
#' @param fps A numeric value specifying the frames per second (fps). Only used
#' to calculate the duration of the final animation. The frame rate needs to be
#' specified in ffmpeg.
#'
#' @returns A data.table with two columns:
#' \itemize{
#'   \item \code{datetime}: The generated time steps.
#'   \item \code{path}: Corresponding file paths for each time step.
#' }
#'
#' @export
#'
#' @examples
#' library(tools4watlas)
#'
#' # load example data
#' data <- data_example
#'
#' # create time steps
#' ts <- atl_time_steps(
#'   datetime_vector = data$datetime,
#'   time_interval = "10 min",
#'   output_path = tempdir(),
#'   create_path = FALSE
#' )
#' ts
atl_time_steps <- function(datetime_vector,
                           time_interval = "10 min",
                           output_path,
                           create_path = FALSE,
                           fps = 24) {
  # global variables
  path <- NULL

  # check if directory exists, create if wanted
  if (!dir.exists(output_path)) {
    if (create_path) {
      dir.create(output_path, recursive = TRUE)
      message("Directory created: ", output_path)
    } else {
      stop(
        "Error: Directory does not exist: ", output_path,
        "use create_path = TRUE to create directory"
      )
    }
  }

  # create time series
  ts <- data.table(datetime = seq(
    lubridate::floor_date(
      min(datetime_vector, na.rm = TRUE),
      unit = time_interval
    ),
    lubridate::ceiling_date(
      max(datetime_vector, na.rm = TRUE),
      unit = time_interval
    ),
    by = time_interval
  ))

  # total and save as text file
  total <- nrow(ts)
  write(total, file = paste0(output_path, "/total_frames.txt"))

  # generate file paths with padded numbers
  ts[, path := paste0(
    output_path, "/", stringr::str_pad(
      seq_len(.N), nchar(as.character(.N)), "left",
      pad = "0"
    ), ".png"
  )]

  # calculate animation duration
  animation_duration <- total / fps

  # print information
  message(glue::glue(
    "Number of frames: {total} - ",
    "Animation duration: {round(animation_duration, 2)} sec ",
    "({round(animation_duration / 60, 2)} min) with {fps} fps"
  ))

  ts
}

#' Display a live progress bar for PNG file generation in a directory
#'
#' This function is meant to track the progress of PNG's created in a parallel
#' loop. It will check the number of PNG files in a specified directory and
#' make a progress bar in the console. To use the function, open a new R session
#' and run the function there.
#'
#' @param file_path Path to the directory containing PNG files.
#' @param total Optional. Total number of expected PNG files. If NULL, the
#'   function reads from 'total_frames.txt' created by atl_time_steps() in the
#'   same directory.
#' @param refresh_rate Numeric value in seconds specifying how often the
#' progress bar updates.
#'
#' @returns No return value. Prints progress bar to the console.
#' @export
atl_progress_bar <- function(file_path,
                             total = NULL,
                             refresh_rate = 1) {
  # check if total is provided
  if (is.null(total)) {
    total_file <- file.path(file_path, "total_frames.txt")

    if (!file.exists(total_file)) {
      stop(paste0(
        "Error: 'total' not provided and 'total_frames.txt'",
        " not found in the specified path."
      ), call. = FALSE)
    }

    total <- scan(total_file, quiet = TRUE)
  }

  # format progress bar
  pb <- progress::progress_bar$new(
    format = "  [:bar] :current/:total (:percent) ETA: :eta",
    total = total,
    clear = FALSE,
    width = 60
  )

  # loop to scan how many files are in the directory
  repeat {
    current <- length(list.files(file_path, pattern = "\\.png$"))
    pb$update(current / total)

    if (current >= total) break

    Sys.sleep(refresh_rate)
  }

  cat("\nDone!\n")
}

#' Creates different alpha values along a vector
#'
#' Copied from https://github.com/mpio-be/windR
#'
#' @author Mihai Valcu & Johannes Krietsch
#' @param x Vector along which alpha is created
#' @param head Numeric parameter influencing the lenght of the head
#' @param skew Numeric parameter influencing the skew of alpha
#'
#' @return Numeric verctor with different alpha values
#' @export
#'
#' @importFrom scales rescale
#' @examples
#' library(ggplot2)
#' d <- data.frame(
#'   x = 1:100, y = 1:100,
#'   a = atl_alpha_along(1:100, head = 20, skew = -2)
#' )
#' bm <- ggplot(d, aes(x, y))
#' bm + geom_path(linewidth = 10)
#' bm + geom_path(linewidth = 10, alpha = d$a, lineend = "round")
atl_alpha_along <- function(x, head = 20, skew = -2) {
  if (head >= length(x)) head <- as.integer(length(x) * 0.5)
  x <- as.numeric(x)
  he <- exp(rescale(x[(length(x) - head):length(x)], c(skew, 0)))
  ta <- rep(min(he), length.out = length(x) - head - 1)
  c(ta, he)
}

#' Creates different size values along a vector
#'
#' Copied from https://github.com/mpio-be/windR
#'
#' @author Mihai Valcu & Johannes Krietsch
#' @param x Vector along which alpha is created
#' @param head Numeric parameter influencing the lenght of the head
#' @param to Numeric vector including the minimum and maximum size
#'
#' @return Numeric verctor with different size values
#' @export
#'
#' @importFrom scales rescale
#' @examples
#' library(ggplot2)
#' d <- data.frame(
#'   x = 1:100, y = 1:100,
#'   s = atl_size_along(1:100, head = 70, to = c(0.1, 5))
#' )
#' bm <- ggplot(d, aes(x, y))
#' bm + geom_path(linewidth = 1)
#' bm + geom_path(linewidth = d$s, lineend = "round")
atl_size_along <- function(x, head = 20, to = c(0.1, 2.5)) {
  if (head >= length(x)) head <- as.integer(length(x) * 0.5)
  x <- as.numeric(x)
  he <- rescale(x[(length(x) - head):length(x)], to)
  ta <- rep(min(he), length.out = length(x) - head - 1)
  c(ta, he)
}

#' Generate ffmpeg filename pattern
#'
#' This function generates a filename pattern for FFmpeg based on the number of
#' digits in the numeric part of the input file path (without the `.png`
#' extension).
#'
#' @param x A character vector of file paths, where each path should include a
#'        filename with a `.png` extension.
#'
#' @returns A character string representing the FFmpeg-compatible filename
#'          pattern (e.g., "%03d.png" for filenames like "001.png").
#' @export
#'
#' @examples
#' atl_ffmpeg_pattern("path/to/file/001.png")
#' # Returns: "%03d.png"
atl_ffmpeg_pattern <- function(x) {
  # extract number of digits in filename
  x <- nchar(sub("\\.png$", "", basename(x)))

  # create the pattern needed for ffmpeg
  paste0("%0", x, "d.png")

}
