import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths
DATA_DIR         = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
DETECTIONS_FILE  = DATA_DIR / "Independent_Forest_Detections_60min.csv"
METADATA_FILE    = DATA_DIR / "matching_locations.csv"
OUTPUT_FILE      = DATA_DIR / "Location_Species_Counts_60min_Merged.csv"

# ——————————————————————————————
# 2️⃣ Load & normalize detection data
det = pd.read_csv(DETECTIONS_FILE)
det.columns = det.columns.str.strip().str.lower()                     # strip & lowercase cols
det['location'] = det['location'].astype(str).str.strip().str.upper()  # uppercase locations
det['species_common_name'] = (
    det['species_common_name']
    .astype(str)
    .str.strip()
    .str.lower()
)  # clean species names

# ——————————————————————————————
# 3️⃣ Count entries per location × species
counts = (
    det
    .groupby(['location', 'species_common_name'])
    .size()
    .reset_index(name='count')
)

# ——————————————————————————————
# 4️⃣ Pivot to wide format
wide = counts.pivot(
    index='location',
    columns='species_common_name',
    values='count'
).fillna(0).reset_index()

# Optional: make column names valid strings (no spaces)
wide.columns.name = None
wide.columns = [c.replace(' ', '_') for c in wide.columns]

# ——————————————————————————————
# 5️⃣ Load metadata & normalize
meta = pd.read_csv(METADATA_FILE)
meta.columns = meta.columns.str.strip().str.lower()
meta['location'] = meta['location'].astype(str).str.strip().str.upper()

# ——————————————————————————————
# 6️⃣ Left‑join wide counts onto metadata
merged = meta.merge(
    wide,
    on='location',
    how='left'
).fillna(0)  # fill NaNs with 0 for locations with no detections

# ——————————————————————————————
# 7️⃣ Save the final table
merged.to_csv(OUTPUT_FILE, index=False)

print("✅ Prepared wide-format species counts per location and merged with ForestPointStart metadata.")
print(f"📄 Output saved to: {OUTPUT_FILE}")
print(f"🟢 Final shape: {merged.shape}")  # rows × columns
