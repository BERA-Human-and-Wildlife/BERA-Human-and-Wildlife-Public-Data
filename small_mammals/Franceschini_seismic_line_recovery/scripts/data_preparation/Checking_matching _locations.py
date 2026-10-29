import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
FILE1       = DATA_DIR / "Independent_Forest_Detections_60min.csv"
FILE2       = DATA_DIR / "ForestPointStart_corrected.csv"
OUTPUT_FILE = DATA_DIR / "matching_locations.csv"

# ——————————————————————————————
# 2️⃣ Load data
df1 = pd.read_csv(FILE1)
df2 = pd.read_csv(FILE2)

# ——————————————————————————————
# 3️⃣ Compute unique matching locations
set1   = set(df1['location'].dropna().unique())
set2   = set(df2['location'].dropna().unique())
common = sorted(set1 & set2)

# ——————————————————————————————
# 4️⃣ Save matches to CSV
pd.DataFrame({'location': common}).to_csv(OUTPUT_FILE, index=False)

print(f"✅ Saved {len(common)} matching locations to {OUTPUT_FILE}")

