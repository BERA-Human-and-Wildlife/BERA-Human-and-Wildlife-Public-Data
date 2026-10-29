import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
INPUT_CSV   = DATA_DIR / "Location_Species_Counts_60min_Merged.csv"
OUTPUT_CSV  = DATA_DIR / "Location_Species_Counts_60min_Merged_adjusted.csv"

# ——————————————————————————————
# 2️⃣ Load the merged counts file
df = pd.read_csv(INPUT_CSV)

# ——————————————————————————————
# 3️⃣ Extract prefix and number, subtract 1, zero‑pad to two digits, and rebuild full name
#    e.g. "SM-C-F-03" → prefix="SM-C-F-" , num="03" → int→3 → 2 → "02" → "SM-C-F-02"
pattern = r'^(.*-F-)(\d+)$'
extracted = df['location'].str.extract(pattern)

df['location_minus1'] = extracted.apply(
    lambda row: f"{row[0]}{(int(row[1]) - 1):02d}",
    axis=1
)

# ——————————————————————————————
# 4️⃣ Save the result
df.to_csv(OUTPUT_CSV, index=False)
print(f"✅ Saved file with new 'location_minus1' column to {OUTPUT_CSV}")
