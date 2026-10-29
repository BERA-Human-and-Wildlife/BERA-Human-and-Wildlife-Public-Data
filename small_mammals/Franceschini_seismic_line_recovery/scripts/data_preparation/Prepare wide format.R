# 1) Set working directory
setwd("C:/Users/afran/Documents/Chapter 2/Analyses")

# 2) Load needed packages (install if missing)
if (!requireNamespace("dplyr", quietly = TRUE))    install.packages("dplyr")
if (!requireNamespace("tidyr", quietly = TRUE))    install.packages("tidyr")
library(dplyr)
library(tidyr)

# 3) Read in the updated detections file
df <- read.csv("Detections_With_Metadata_SpeciesMerged_Rev_updated.csv",
               stringsAsFactors = FALSE)

# 4) Define the subset of species to include
species_list <- c(
  "common raccoon",  "deer mouse",     "none",               
  "red squirrel",    "southern red-backed vole", 
  "dusky shrew",     "black bear",     "marten",             
  "snowshoe hare",   "long-tailed weasel",       
  "western jumping mouse",     "eastern meadow vole",     
  "northern flying squirrel",  "least chipmunk"
)

# 5) Count entries per species per site, pivot to wide
df_species_wide <- df %>%
  filter(species_common_name %in% species_list) %>%
  mutate(
    # turn spaces into dots for column names
    species_name = factor(
      gsub(" ", ".", species_common_name),
      levels = gsub(" ", ".", species_list)
    )
  ) %>%
  group_by(location, species_name) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(
    names_from   = species_name,
    values_from  = n,
    values_fill  = list(n = 0)
  )

# 6) Extract one row per site with your chosen covariates
site_info <- df %>%
  select(
    location, active_hours, julian_date,
    latitude, longitude, width, seismic_line_type,
    humanuse_intensity, trail_present, veg_structure,
    veg_regen_status, forest_cover,
    exg_0, exg_0.1, exg_0.2,
    exgr_0, ngrdi_0, vari_0, gli_0, tgi_0,
    lab_veg, hsv_veg,
    vegplustransition_gt_0,
    vegplustransition_gt_0.1,
    vegplustransition_gt_0.2,
    act_veg
  ) %>%
  distinct()

# 7) Join the species counts onto the site table
wide_df <- site_info %>%
  left_join(df_species_wide, by = "location")

# 8) Write out the final wide‐format file
write.csv(
  wide_df,
  "Detections_Wide_For_Analysis.csv",
  row.names = FALSE
)


# … steps 1–7 as before …

# 7) Join the species counts onto the site table
wide_df <- site_info %>%
  left_join(df_species_wide, by = "location") %>%
  # 7b) drop the 'none' column
  select(-none)

# 8) Write out the final wide‐format file
write.csv(
  wide_df,
  "Detections_Wide_For_Analysis.csv",
  row.names = FALSE
)



# assume you’ve already built `wide_df` as in the last step

# 1) define the set of columns to standardize
vars_to_scale <- c(
  "active_hours",
  "julian_date",
  "width",
  "exg_0",             "exg_0.1",         "exg_0.2",
  "exgr_0",            "ngrdi_0",         "vari_0",
  "gli_0",             "tgi_0",           "lab_veg",
  "hsv_veg",           "vegplustransition_gt_0",
  "vegplustransition_gt_0.1",
  "vegplustransition_gt_0.2",
  "act_veg"
)

# 2) create scaled versions with dplyr::across()
library(dplyr)

wide_df <- wide_df %>%
  mutate(
    across(
      .cols   = all_of(vars_to_scale),
      .fns    = ~ as.numeric(scale(.x)),
      .names  = "{.col}_scaled"
    )
  )

# 3) (Optional) inspect
wide_df %>%
  select(ends_with("_scaled")) %>%
  summary()

# 4) (Optional) save
write.csv(
  wide_df,
  "Detections_Wide_For_Analysis_scaled.csv",
  row.names = FALSE
)



# 1) How many unique forest_cover values?
n_levels <- wide_df %>% 
  summarise(n = n_distinct(forest_cover)) %>% 
  pull(n)
print(n_levels)
# e.g. [1] 3

# 2) What are they, and how many sites per category?
wide_df %>% 
  count(forest_cover) %>% 
  arrange(desc(n)) %>% 
  print()


library(dplyr)

# 1) Filter out any 'pine' rows
wide_df_no_pine <- wide_df %>%
  filter(forest_cover != "Pine")

# 2) (Optional) Overwrite your original or save to a new CSV
write.csv(
  wide_df_no_pine,
  "Detections_Wide_For_Analysis_no_pine.csv",
  row.names = FALSE
)
