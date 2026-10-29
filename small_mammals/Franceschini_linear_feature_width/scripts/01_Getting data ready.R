setwd("D://UoA/Thesis/First_chapter_analysis")

source("TEAM library 1.8.R")
library(lubridate)
library(tidyr)
library(dplyr)
library(chron)
library(reshape)
library(vegan)
library(plotrix)
library(ggplot2)
library(maptools)
library(rgdal)

camera_trap_data <- read.csv("BU_Franceschini_-_Small_mammal_data_2023_main_report.csv")
camera_trap_data <- camera_trap_data %>%
  select(-location_buffer_m, -image_snow, -image_snow_depth_m, -image_water_depth_m,
         -age_class, -sex_class, -behaviours, -health_diseases, -coat_colours, -coat_attributes,
         -tine_attributes, -direction_travel, -has_collar, -has_eartag, -ihf, -tag_needs_review, 
         - tag_is_verified, -tag_is_verified, -latitude, -longitude)





# Replace 'CurrentName' with 'NewName' in the 'location' column
camera_trap_data$location[camera_trap_data$location == "SM-C-F-1136"] <- "SM-P-F-1136"
camera_trap_data$location[camera_trap_data$location == "SM-N-F-1178"] <- "SM-C-F-1178"
camera_trap_data$location[camera_trap_data$location == "SM-C-F-233"] <- "SM-C-F-1180"
camera_trap_data$location[camera_trap_data$location == "SM-N-F-1218"] <- "SM-C-F-1218"

unique(camera_trap_data$location)


camera_trap_data <- camera_trap_data %>%
  separate(col = species_scientific_name, into = c("Genus", "Species"), sep = " ")
unique(camera_trap_data$Genus)
unique(camera_trap_data$Species)


camera_trap_data <- camera_trap_data %>%
  mutate(Genus = replace_na(Genus, "None"),
         Species = replace_na(Species, "none"))

camera_trap_data$Genus <- as.character(camera_trap_data$Genus)
camera_trap_data <- camera_trap_data %>%
  mutate(Genus = replace(Genus, Genus == "" | is.na(Genus), "None"))

camera_trap_data$Scientific.Name <- paste(camera_trap_data$Genus, camera_trap_data$Species, sep = " ")

# Split the data frame into two parts
Data_none <- camera_trap_data %>% filter(Genus == "None")
Data_other <- camera_trap_data %>% filter(Genus != "None")

# For df_none, keep only the first 100 rows for each unique location
set.seed(123)  # Set a seed for reproducibility
Data_none_filtered <- Data_none %>%
  group_by(location) %>%
  sample_n(min(100, n())) %>%
  ungroup()

# Combine the two data frames
final_Data <- bind_rows(Data_none_filtered, Data_other)

final_Data <- camera_trap_data


final_Data$image_date_time <- as.POSIXct(final_Data$image_date_time, tz = "America/Edmonton") # Specify the timezone if needed
final_Data$date <- as.Date(final_Data$image_date_time)
final_Data$time <- format(final_Data$image_date_time, format = "%H:%M:%S")

final_Data$date <- as.Date(final_Data$date, format = "%Y-%m-%d")



specific_locations4 <- c("SM-C-F-1082", "SM-N-L-1099", "SM-C-L-1083")  # Replace with your specific location identifiers


final_Data <- final_Data %>%
  mutate(date = as.Date(ifelse(location %in% specific_locations4, 
                        date + 4, 
                        date), origin = "1970-01-01"))


specific_locations8 <- c("SM-C-F-20", "SM-C-F-16", "SM-N-F-1058")  # Replace with your specific location identifiers


final_Data <- final_Data %>%
  mutate(date = as.Date(ifelse(location %in% specific_locations8, 
                               date + 8, 
                               date), origin = "1970-01-01"))


specific_locations18 <- c("SM-C-F-44",  "SM-N-L-217")  # Replace with your specific location identifiers



final_Data <- final_Data %>%
  mutate(date = as.Date(ifelse(location %in% specific_locations18, 
                               date + 18, 
                               date), origin = "1970-01-01"))



final_Data$image_date_time <- as.POSIXct(paste(final_Data$date, final_Data$time), format = "%Y-%m-%d %H:%M:%S")


camera_active_periods <- read.csv("TableCovs_corrected.csv", sep = ";")
camera_active_periods$location<-camera_active_periods$Locations
final_Data <- final_Data %>%
  left_join(camera_active_periods, by = "location")


final_Data$Sampling.Event <- 2023





date_parsed <- dmy(final_Data$Start_Date)
date_formatted <- format(date_parsed, "%Y-%m-%d")
final_Data$Start_Date<-date_formatted
final_Data$Camera.Start.Date.and.Time <- paste(final_Data$Start_Date, final_Data$Start_Time)
final_Data$Camera.Start.Date.and.Time <- as.POSIXct(final_Data$Camera.Start.Date.and.Time, format="%Y-%m-%d %H:%M")


date_parsed <- dmy(final_Data$End_Date)
date_formatted <- format(date_parsed, "%Y-%m-%d")
final_Data$End_Date<-date_formatted
final_Data$Camera.End.Date.and.Time <- paste(final_Data$End_Date, final_Data$End_Time)
final_Data$Camera.End.Date.and.Time <- as.POSIXct(final_Data$Camera.End.Date.and.Time, format="%Y-%m-%d %H:%M")



final_Data$Photo.Date<-final_Data$date
final_Data$Photo.Time<-final_Data$time

final_Data$Start.Date<-final_Data$Start_Date
final_Data$End.Date<-final_Data$End_Date



df2 <- read.csv("LocationsCorrupted.csv")

final_Data$Locations<-final_Data$location

camera_trap_data <- final_Data %>% filter(!(Locations %in% df2$Locations))


# Standardizing the sampling effort to 96 hours
# Calculate the time difference in hours
camera_trap_data$TimeDifference <- difftime(camera_trap_data$image_date_time, camera_trap_data$Start.Date, units = "hours")

# Filter rows where the time difference is less than or equal to 96 hours
camera_trap_data_STD2 <- camera_trap_data %>% filter(TimeDifference <= 96)



filtered_df <- Data1 %>% filter(Locations == "SM-N-F-554")



# final_Data <- final_Data %>%
#   select(-Camera.Start.Date.and.Time, -Camera.End.Date.and.Time)

data1<-camera_trap_data_STD2



filtered_data <- data1 %>%
  filter(location == "SM-N-F-554")
ad<-filtered_data$image_date_time
# The dates are correct!

data1$Sampling.Unit.Name<- data1$Locations


data1$Longitude <- gsub(",", ".", data1$Longitude)
data1$Latitude <- gsub(",", ".", data1$Latitude)



Data1<-fix.dta(data1)


write.csv(Data1, file = "DataTEAM_STD.CSV")
