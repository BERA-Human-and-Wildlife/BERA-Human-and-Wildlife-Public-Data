# 1) Set your working directory
# ─────────────────────────────────────────────────────────────────────────────
setwd("C:/Users/afran/Documents/Chapter 2/Analyses")

# ─────────────────────────────────────────────────────────────────────────────
# 2) Load required packages (install if needed)
# ─────────────────────────────────────────────────────────────────────────────
if (!requireNamespace("dplyr",    quietly=TRUE)) install.packages("dplyr")
if (!requireNamespace("lubridate",quietly=TRUE)) install.packages("lubridate")

library(dplyr)
library(lubridate)

# ─────────────────────────────────────────────────────────────────────────────
# 3) Read in your data
# ─────────────────────────────────────────────────────────────────────────────
# Make sure the CSV file is in the working directory:
file_name <- "Detections_With_Metadata_SpeciesMerged_Rev.csv"
detections <- read.csv(file_name, stringsAsFactors = FALSE)

# 4) Parse correctly and compute hours active
# ─────────────────────────────────────────────────────────────────────────────
detections <- detections %>%
  mutate(
    # start_date is DD/MM/YYYY and start_time is HH:MM:SS
    deploy   = dmy_hms(paste(start_date, start_time)),
    # end_date is DD/MM/YYYY but end_time is only HH:MM
    retrieve = dmy_hm(paste(end_date,   end_time)),
    active_hours = as.numeric(difftime(retrieve, deploy, units = "hours"))
  )

# check the range:
range(detections$active_hours, na.rm = TRUE)
# you should see something around 96–120 hours for a 4–5 day deployment

# ─────────────────────────────────────────────────────────────────────────────
# 5) Extract one value per site
# ─────────────────────────────────────────────────────────────────────────────
site_active_hours <- detections %>%
  select(location, active_hours) %>%
  distinct()

# Inspect:
print(head(site_active_hours))
# now you should see positives ~96–120 for a ~4–5 day deployment



library(dplyr)

# 1) Which sites have negative hours?
neg_sites <- site_active_hours %>%
  filter(active_hours < 0)

# 2) See them:
print(neg_sites)
#>   location active_hours
#> 1  SM-XXX-…     -12.34
#> 2  SM-YYY-…     -24.56
#> …

# If you want the raw deploy/retrieve datetimes too, you can look
# at the full detections table:

neg_records <- detections %>%
  filter(active_hours < 0) %>%
  select(location,
         start_date, start_time,
         end_date,   end_time,
         active_hours) %>%
  distinct()

print(neg_records)



# ─────────────────────────────────────────────────────────────────────────────
# 1) Set working directory
# ─────────────────────────────────────────────────────────────────────────────
setwd("C:/Users/afran/Documents/Chapter 2/Analyses")

# ─────────────────────────────────────────────────────────────────────────────
# 2) Load packages (install if missing)
# ─────────────────────────────────────────────────────────────────────────────
if (!requireNamespace("dplyr",    quietly=TRUE)) install.packages("dplyr")
if (!requireNamespace("lubridate",quietly=TRUE)) install.packages("lubridate")
library(dplyr)
library(lubridate)

# ─────────────────────────────────────────────────────────────────────────────
# 3) Read in your data
# ─────────────────────────────────────────────────────────────────────────────
df <- read.csv(
  "Detections_With_Metadata_SpeciesMerged_Rev.csv",
  stringsAsFactors = FALSE
)

# ─────────────────────────────────────────────────────────────────────────────
# 4) Correct the two records, parse date‐times, compute active_hours & julian_date
# ─────────────────────────────────────────────────────────────────────────────
df2 <- df %>%
  # 4a) Fix the mis‐entered fields
  mutate(
    end_time = if_else(location == "SM-N-L-1049", "18:27", end_time),
    end_date = if_else(location == "SM-N-L-1139", "28/07/2023", end_date)
  ) %>%
  # 4b) Build POSIXct deploy/retrieve, compute hours active, and julian day
  mutate(
    # combine and parse
    deploy       = dmy_hms(paste(start_date, start_time)),  # DD/MM/YYYY + HH:MM:SS
    retrieve     = dmy_hm( paste(end_date,   end_time)   ),  # DD/MM/YYYY + HH:MM
    # difference in hours
    active_hours = as.numeric(difftime(retrieve, deploy, units = "hours")),
    # day of year, restarting at 1 each Jan 1
    julian_date  = yday(deploy)
  )

# ─────────────────────────────────────────────────────────────────────────────
# 5) (Optional) Look at any corrected rows
# ─────────────────────────────────────────────────────────────────────────────
df2 %>%
  filter(location %in% c("SM-N-L-1049", "SM-N-L-1139")) %>%
  select(location, start_date, start_time, end_date, end_time,
         active_hours, julian_date) %>%
  print()

# ─────────────────────────────────────────────────────────────────────────────
# 6) Write out full updated dataset
# ─────────────────────────────────────────────────────────────────────────────
write.csv(
  df2,
  file = "Detections_With_Metadata_SpeciesMerged_Rev_updated.csv",
  row.names = FALSE
)
