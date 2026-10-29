import pandas as pd

# === File paths ===
folder = "C:/Users/alefr/Documents/2024_dataFix"
file_2023 = f"{folder}/Filtered_SM_Main_Report_2023.csv"
file_2024 = f"{folder}/Filtered_SM24_Main_Report_2024.csv"
output_file = f"{folder}/Combined_2023_2024_Observations.csv"

# === Load both filtered files ===
df_2023 = pd.read_csv(file_2023)
df_2024 = pd.read_csv(file_2024)

# === Normalize column names ===
df_2023.columns = df_2023.columns.str.strip().str.lower()
df_2024.columns = df_2024.columns.str.strip().str.lower()

# === Define the columns to keep ===
cols_to_keep = [
    "location",
    "latitude",
    "longitude",
    "equipment_serial",
    "image_date_time",
    "species_scientific_name",
    "species_common_name",
    "individual_count"
]

# === Filter both datasets ===
df_2023_filtered = df_2023[cols_to_keep]
df_2024_filtered = df_2024[cols_to_keep]

# === Merge the datasets ===
combined_df = pd.concat([df_2023_filtered, df_2024_filtered], ignore_index=True)

# === Save merged file ===
combined_df.to_csv(output_file, index=False)
print(f"✅ Combined file saved: {output_file}")
