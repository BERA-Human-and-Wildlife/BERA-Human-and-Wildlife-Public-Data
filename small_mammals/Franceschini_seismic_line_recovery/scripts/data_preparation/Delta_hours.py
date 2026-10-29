import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
MAIN_FILE   = DATA_DIR / "filtered_forest_dataset.csv"
DEPLOY_FILE = DATA_DIR / "ForestPointStart_corrected.csv"
OUTPUT_FILE = DATA_DIR / "filtered_forest_dataset_with_delta.csv"

# ——————————————————————————————
# 2️⃣ Load data
df_main   = pd.read_csv(MAIN_FILE)
df_deploy = pd.read_csv(DEPLOY_FILE)

# ——————————————————————————————
# 3️⃣ Clean & parse image timestamps
df_main['image_date_time_str'] = df_main['image_date_time'].astype(str).str.strip()
df_main['image_date_time_parsed'] = pd.to_datetime(
    df_main['image_date_time_str'],
    infer_datetime_format=True,
    errors='coerce'
)

# ——————————————————————————————
# 4️⃣ Apply location‑based date shifts
corrections = {
    'SM-N-F-1058': 8,   # +8 days
    'SM-C-F-16':   8,
    'SM-C-F-20':   8,
    'SM-C-F-44':  18    # +18 days
}
for loc, days in corrections.items():
    mask = df_main['location'] == loc
    df_main.loc[mask, 'image_date_time_parsed'] += pd.Timedelta(days=days)

# ——————————————————————————————
# 5️⃣ Parse deployment datetimes
df_deploy['deployment_datetime'] = pd.to_datetime(
    df_deploy['Date'].str.strip() + ' ' + df_deploy['Time'].str.strip(),
    format="%d/%m/%Y %H:%M",
    errors='coerce'
)

# ——————————————————————————————
# 6️⃣ Map deployments → main & compute delta_hours
deploy_map = df_deploy.set_index('location')['deployment_datetime']
df_main['deployment_datetime'] = df_main['location'].map(deploy_map)
df_main['delta_hours'] = (
    df_main['image_date_time_parsed'] - df_main['deployment_datetime']
) / pd.Timedelta(hours=1)

# ——————————————————————————————
# 7️⃣ Remove first‑hour entries but restore locations with none left
# Save a copy before filtering
df_before = df_main.copy()

# Filter out those within the first hour
df_filtered = df_main[df_main['delta_hours'] >= 1].copy()

# Identify locations lost entirely by that filter
lost_locations = set(df_before['location']) - set(df_filtered['location'])

# For those locations, restore their original entries
df_lost = df_before[df_before['location'].isin(lost_locations)].copy()

# Combine filtered + restored
df_main = pd.concat([df_filtered, df_lost], ignore_index=True)

# Reporting
removed = len(df_before) - len(df_filtered)
restored = len(df_lost)
print(f"🗑️ Removed {removed} entries taken within the first hour of deployment")
print(f"🔄 Restored {restored} entries for locations that would have been empty: {sorted(lost_locations)}")

# ——————————————————————————————
# 8️⃣ Reorder columns & save
base_cols  = [
    'location',
    'image_date_time_str',
    'image_date_time_parsed',
    'deployment_datetime',
    'delta_hours'
]
other_cols = [c for c in df_main.columns if c not in base_cols]
df_main    = df_main[base_cols + other_cols]

df_main.to_csv(OUTPUT_FILE, index=False)
print(f"\n✅ Saved cleaned file with delta_hours: {OUTPUT_FILE}")
