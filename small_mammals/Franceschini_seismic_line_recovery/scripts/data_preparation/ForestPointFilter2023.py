import pandas as pd
import re

# === FILE PATHS ===
line_file = r"C:\Users\afran\Documents\Chapter 2\Data preparation\2023_line_locations.csv"
raw_file  = r"C:\Users\afran\Documents\Chapter 2\Data preparation\BU_Franceschini_FIXED.csv"

# === Load data ===
line_df = pd.read_csv(line_file)
raw_df  = pd.read_csv(raw_file)

# === Original mapping (desired:left, current:right) ===
desired_to_current = {
    "SM-C-F-1002": "SM-C-F-1002_NA",
    "SM-C-F-1178": "SM-N-F-1178",
    "SM-C-F-1180": "SM-C-F-233",
    "SM-N-F-18":   "SM-N-F-18_2",
    "SM-N-F-76":   "SM-N-F-76_2",
    "SM-N-F-556":  "SM-N-F-556",
}

# === Invert it: actual_name_in_raw -> desired_name ===
manual_corrections = {v: k for k, v in desired_to_current.items()}

# === Apply manual fixes to raw_df up‑front ===
raw_df['location'] = raw_df['location'].replace(manual_corrections)

# === Extract unique seismic-line IDs ===
line_locations = line_df['location'].dropna().unique()

# === Auto‑match forest IDs from lines ===
def get_forest_location(line_loc):
    m = re.match(r"(SM-[CNP]-)L-(\d+)", line_loc)
    if m:
        base, num = m.groups()
        return f"{base}F-{int(num) + 1:02d}"
    return None

# === Build lookup table ===
match_df = pd.DataFrame({'line_location': line_locations})
match_df['location'] = match_df['line_location'].apply(get_forest_location)
# apply same fixes to lookup
match_df['location'] = match_df['location'].replace(manual_corrections)

# === Flag existing forest sites ===
forest_pts = set(raw_df['location'].dropna().unique())
match_df['forest_found'] = match_df['location'].isin(forest_pts)

# === Filter for valid forest points ===
valid = match_df.loc[match_df['forest_found'], 'location']
filtered_raw = raw_df[raw_df['location'].isin(valid)].copy()

# === Dummy row for truly missing site ===
missing = "SM-C-F-1002"
if missing not in forest_pts:
    dummy = {col: "NA" for col in raw_df.columns}
    dummy['location'] = missing
    filtered_raw = pd.concat([filtered_raw, pd.DataFrame([dummy])], ignore_index=True)

# === Final: ensure filtered dataset uses desired names ===
filtered_raw['location'] = filtered_raw['location'].replace(manual_corrections)

# === Save outputs ===
filtered_raw.to_csv(
    r"C:\Users\afran\Documents\Chapter 2\Data preparation\filtered_forest_dataset.csv",
    index=False
)
match_df.to_csv(
    r"C:\Users\afran\Documents\Chapter 2\Data preparation\line_forest_matches.csv",
    index=False
)
match_df[~match_df['forest_found']].to_csv(
    r"C:\Users\afran\Documents\Chapter 2\Data preparation\unmatched_locations.csv",
    index=False
)

print("🎯 DONE fam! Your folder slaps with:")
print("✅ filtered_forest_dataset.csv — renamed & filtered forest data")
print("✅ line_forest_matches.csv — line→forest lookup")
print("✅ unmatched_locations.csv — still-sus sites")
