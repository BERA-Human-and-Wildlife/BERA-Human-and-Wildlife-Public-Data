import pandas as pd

# === File paths ===
obs_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_Observations.csv"
trans_file = "C:/Users/alefr/Documents/2024_dataFix/Final_Data_With_NewExG_Transitions.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Missing_Locations_From_Observations.csv"

# === Load files ===
obs = pd.read_csv(obs_file)
trans = pd.read_csv(trans_file)

# === Normalize column names and locations ===
obs.columns = obs.columns.str.strip().str.lower()
trans.columns = trans.columns.str.strip().str.lower()
obs['location'] = obs['location'].astype(str).str.strip().str.upper()
trans['locations'] = trans['locations'].astype(str).str.strip().str.upper()

# === Get sets of locations ===
observed_locs = set(obs['location'].unique())
expected_locs = set(trans['locations'].unique())

# === Find missing locations ===
missing_locs = sorted(expected_locs - observed_locs)

# === Save to CSV if there are any
if missing_locs:
    pd.DataFrame({'missing_location': missing_locs}).to_csv(output_file, index=False)
    print(f"❗ Missing locations found: {len(missing_locs)}")
    print(f"📄 Saved list to: {output_file}")
else:
    print("✅ All locations from the transition file are present in the observations.")

# === Preview
print("🧾 Missing locations:" if missing_locs else "")
print(missing_locs[:10])
