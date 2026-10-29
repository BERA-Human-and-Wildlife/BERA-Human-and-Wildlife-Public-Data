import pandas as pd

# === File paths ===
folder = "C:/Users/alefr/Documents/2024_dataFix"
final_file = f"{folder}/Final_Data_With_NewExG_Transitions.csv"
main_file_2023 = f"{folder}/BU_Franceschini_-_Small_Mammals_-_2023_main_report.csv"

# === Load the CSVs ===
final_df = pd.read_csv(final_file)
main_df_2023 = pd.read_csv(main_file_2023, low_memory=False)

# === Standardize column names ===
final_df.columns = final_df.columns.str.strip().str.lower()
main_df_2023.columns = main_df_2023.columns.str.strip().str.lower()

# === Step 1: Get SM- locations from final data ===
sm_locs = final_df['locations'].astype(str)
sm_locs = sm_locs[sm_locs.str.startswith("SM-")].unique()

# === Step 2: Filter 2023 main report for rows with matching 'location' ===
main_locs_2023 = main_df_2023['location'].astype(str)
filtered_main_2023 = main_df_2023[main_locs_2023.isin(sm_locs)]

# === Step 3: Find SM- values not matched in 2023 ===
missing_sm_2023 = sorted([loc for loc in sm_locs if loc not in main_locs_2023.values])

# === Step 4: Save filtered result ===
filtered_output_path = f"{folder}/Filtered_SM_Main_Report_2023.csv"
filtered_main_2023.to_csv(filtered_output_path, index=False)
print(f"✅ Filtered file saved: {filtered_output_path}")

# Optional: Save missing locations too
if missing_sm_2023:
    missing_path = f"{folder}/Missing_SM_Locations_2023.csv"
    pd.DataFrame(missing_sm_2023, columns=["Missing_SM_Locations"]).to_csv(missing_path, index=False)
    print(f"⚠️ Missing SM- locations saved: {missing_path}")
    print("🚨 These SM- values were NOT found in the 2023 file:")
    for loc in missing_sm_2023:
        print(f" - {loc}")
else:
    print("🎉 All SM- locations were matched in the 2023 file!")
