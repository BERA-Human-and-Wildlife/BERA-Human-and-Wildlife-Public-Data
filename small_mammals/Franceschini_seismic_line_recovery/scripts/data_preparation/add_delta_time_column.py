import pandas as pd

# === File paths ===
obs_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_Observations.csv"
trans_file = "C:/Users/alefr/Documents/2024_dataFix/Final_Data_With_NewExG_Transitions.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_With_DeltaTimes.csv"

# === Load data ===
obs = pd.read_csv(obs_file)
trans = pd.read_csv(trans_file)

# === Clean column names and normalize location names ===
obs.columns = obs.columns.str.strip().str.lower()
trans.columns = trans.columns.str.strip().str.lower()
obs['location'] = obs['location'].astype(str).str.strip().str.upper()
trans['locations'] = trans['locations'].astype(str).str.strip().str.upper()

# === Parse image datetime ===
obs['image_date_time'] = pd.to_datetime(obs['image_date_time'], errors='coerce')

# === Parse start date and time from transitions ===
trans['start_datetime_raw'] = trans['start_date'].astype(str) + ' ' + trans['start_time'].astype(str)
trans['start_datetime_parsed'] = pd.to_datetime(trans['start_datetime_raw'], dayfirst=True, errors='coerce')
trans['start_date'] = trans['start_datetime_parsed'].dt.date
trans['start_time'] = trans['start_datetime_parsed'].dt.time

# === Merge deployment metadata into observations (left join = keep all obs) ===
obs = obs.merge(
    trans[['locations', 'start_date', 'start_time']],
    how='left',
    left_on='location',
    right_on='locations'
)

# === Build start datetime safely ===
obs['start_datetime'] = pd.to_datetime(
    obs['start_date'].astype(str) + ' ' + obs['start_time'].astype(str),
    errors='coerce'
)

# === Calculate delta time in hours (keep NaNs if missing deployment data) ===
obs['delta_time_hours'] = (obs['image_date_time'] - obs['start_datetime']).dt.total_seconds() / 3600

# === Save the updated dataset ===
obs.to_csv(output_file, index=False)

print(f"✅ Delta time calculated and added to all entries.")
print(f"📄 File saved to: {output_file}")
print(f"🟢 Total rows: {len(obs)}")
