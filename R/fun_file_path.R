#' Get the file path for WATLAS or GIS data based on the user's name.
#'
#' This function returns a predefined file path based on the user's system
#' username and the selected data type.
#' Users must be predefined in the function.
#'
#' For local users with access to the NIOZ network, I would recommend to add a
#' shortcut to your OneDrive of the “WATLAS” SharePoint folder:
#' `Documents/data/`.
#' The path in the function then refers to this copy on your OneDrive. Files in
#' this folder (e.g. `tags_watlas_all.xlsx` and tide data) are often updated and
#' changes are then automatically updated on your computer.
#'
#' The second source of data is the “Birds, fish ’n chips” SharePoint folder:
#' `Documents/data/GIS/` which has the subfolders rasters and shapefiles. One
#' can also create a OneDrive shortcut for this folder, however it contains many
#' large files and files usually don't change. I would therefore recommend to
#' only copy necessary data in a local folder on your computer and then link
#' the path to this folder.
#'
#' To build all articles for the package website, you need to specify your user
#' paths here.
#'
#' @param data_type A character string indicating the type of data. Options are:
#'   - `"watlas_teams"`: Path to “WATLAS” SharePoint folder: `Documents/data/`
#'   - `"rasters"`: Path to “Birds, fish ’n chips” SharePoint folder:
#'  ` Documents/data/GIS/rasters/`
#'   - `"shapefiles"`: Path to “Birds, fish ’n chips” SharePoint folder:
#'   `Documents/data/GIS/shapefiles/`
#'   - `"sqlite_db"`: Path to ZEUS folder:
#'   `ZEUS/cos/birds/bijleveld/fieldwork/WATLAS/localizations`
#'
#' @return A character string representing the full file path to the selected
#'   data type for the current user.
#' @export
#'
#' @examples
#' \dontrun{
#' # test if all files can be accessed using atl_file_path() function
#'
#' # packages
#' library(tools4watlas)
#'
#' # file path to WATLAS teams data folder
#' fp <- atl_file_path("watlas_teams")
#' # check file path exists
#' file.exists(paste0(
#'   fp, "waterdata/allYears-tidalPattern-west_terschelling-UTC.csv"
#' ))
#'
#' # file path to Birds, fish 'n chips GIS/rasters folder
#' fp <- atl_file_path("rasters")
#' # check file path exists
#' file.exists(paste0(fp, "bathymetry/2024/bodemhoogte_20mtr_UTM31_int.tif"))
#'
#'
#' # file path to Birds, fish 'n chips GIS/shapefiles folder
#' fp <- atl_file_path("shapefiles")
#' # check file path exists
#' file.exists(
#'   paste0(fp, "open_street_map/land-polygons-complete-4326/land_polygons.shp")
#' )
#'
#' # file path to sqlite databases
#' db_fp <- atl_file_path("sqlite_db")
#' # check file path exists
#' file.exists(
#'   paste0(db_fp, "watlas-2024.sqlite")
#' )
#' }
atl_file_path <- function(data_type = c("watlas_teams",
                                        "rasters",
                                        "shapefiles",
                                        "sqlite_db")) {
  # get the username
  user_name <- Sys.info()[["user"]]

  # define the data type to be selected
  data_type <- match.arg(data_type)

  # use switch to select the file path based on the username
  path <- switch(user_name,
    "allert" = switch(data_type,
      "watlas_teams" = paste0(
        "C:/Users/allert/NIOZ/",
        "WATLAS - Documenten/data/"
      ),
      "rasters" = paste0(
        "C:/Users/allert/NIOZ/",
        "Birds, fish 'n chips - Documenten/data/GIS/rasters/"
      ),
      "shapefiles" = paste0(
        "C:/Users/allert/NIOZ/",
        "Birds, fish 'n chips - Documenten/data/GIS/shapefiles/"
      ),
      "sqlite_db" = paste0(
        "C:/Users/allert/NIOZ/",
        "add_correct_path_here/"
      )
    ),
    "jkrietsch" = switch(data_type,
      "watlas_teams" = paste0(
        "C:/Users/jkrietsch/OneDrive - NIOZ/",
        "WATLAS_data/"
      ),
      "rasters" = paste0(
        "C:/Users/jkrietsch/OneDrive - NIOZ/",
        "Documents/map_data/"
      ),
      "shapefiles" = paste0(
        "C:/Users/jkrietsch/OneDrive - NIOZ/",
        "Documents/map_data/"
      ),
      "sqlite_db" = paste0(
        "C:/Users/jkrietsch/OneDrive - NIOZ/",
        "Documents/watlas_data/localizations/"
      )
    ),
    stop(
      "User not recognized, please add data for your user in this function ",
      "in tools4watlas or define the path to the folder directly.", 
      call. = FALSE
    )
  )

  path
}
