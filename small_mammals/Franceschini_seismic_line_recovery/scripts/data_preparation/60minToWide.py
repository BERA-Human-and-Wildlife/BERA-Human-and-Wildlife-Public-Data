import pandas as pd
from pathlib import Path

# ——————————————————————————————
# File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
INPUT_FILE  = DATA_DIR / "Independent_Detections_60min.csv"
OUTPUT_FILE = DATA_DIR / "Independent_Detections_60min_wide.csv"

# ——————————————————————————————
# Load the raw detections
df = pd.read_csv(INPUT_FILE)

# Pivot to wide format: rows = location, cols = species, values = counts
wide_df = df.pivot_table(
    index='location',
    columns='species_common_name',
    aggfunc='size',
    fill_value=0
).reset_index()

# Save the wide table
wide_df.to_csv(OUTPUT_FILE, index=False)

print(f"✅ Saved wide-format table to {OUTPUT_FILE}")
