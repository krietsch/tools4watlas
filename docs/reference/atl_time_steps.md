# Generate time steps and file names for an animation of movements

This function creates a sequence of time steps based on a given datetime
vector and time interval. It also generates corresponding file names in
a provided folder path for each time step. The function also gives a
message showing the total number of frames (also saves this as text
file, to be used when plotting a progress bar) and how long the
animation would take, giving a set fps (frames per second).

## Usage

``` r
atl_time_steps(
  datetime_vector,
  time_interval = "10 min",
  output_path,
  create_path = FALSE,
  fps = 24
)
```

## Arguments

- datetime_vector:

  A vector of datetime values (POSIXct or similar). Can be a min and max
  or simple a full vector from the data

- time_interval:

  A character string specifying the time interval (e.g., "30 sec", "10
  min", "1 hour").

- output_path:

  A character string specifying the directory of the folder where the
  files will be saved.

- create_path:

  A logical value. If TRUE, the function creates the directory if it
  does not exist.

- fps:

  A numeric value specifying the frames per second (fps). Only used to
  calculate the duration of the final animation. The frame rate needs to
  be specified in ffmpeg.

## Value

A data.table with two columns:

- `datetime`: The generated time steps.

- `path`: Corresponding file paths for each time step.

## Author

Johannes Krietsch

## Examples

``` r
library(tools4watlas)

# load example data
data <- data_example

# create time steps
ts <- atl_time_steps(
  datetime_vector = data$datetime,
  time_interval = "10 min",
  output_path = tempdir(),
  create_path = FALSE
)
#> Number of frames: 139 - Animation duration: 5.79 sec (0.1 min) with 24 fps
ts
#>                 datetime
#>                   <POSc>
#>   1: 2023-09-23 01:00:00
#>   2: 2023-09-23 01:10:00
#>   3: 2023-09-23 01:20:00
#>   4: 2023-09-23 01:30:00
#>   5: 2023-09-23 01:40:00
#>  ---                    
#> 135: 2023-09-23 23:20:00
#> 136: 2023-09-23 23:30:00
#> 137: 2023-09-23 23:40:00
#> 138: 2023-09-23 23:50:00
#> 139: 2023-09-24 00:00:00
#>                                                               path
#>                                                             <char>
#>   1: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/001.png
#>   2: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/002.png
#>   3: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/003.png
#>   4: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/004.png
#>   5: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/005.png
#>  ---                                                              
#> 135: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/135.png
#> 136: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/136.png
#> 137: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/137.png
#> 138: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/138.png
#> 139: C:\\Users\\JKRIET~1\\AppData\\Local\\Temp\\RtmpcfggNZ/139.png
```
