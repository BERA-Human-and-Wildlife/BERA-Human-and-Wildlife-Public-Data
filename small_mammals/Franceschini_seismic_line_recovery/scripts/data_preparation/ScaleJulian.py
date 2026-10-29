import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
INPUT_FILE  = DATA_DIR / "New_data.csv"
OUTPUT_FILE = DATA_DIR / "New_data_zscored.csv"

# ——————————————————————————————
# 2️⃣ Load the data
df = pd.read_csv(INPUT_FILE)

# ——————————————————————————————
# 3️⃣ Compute Z‑score for julian_date and width
#    - julian_date
mean_jd = df['julian_date'].mean()
std_jd  = df['julian_date'].std(ddof=0)  # population std
df['julian_date_zscore'] = (df['julian_date'] - mean_jd) / std_jd

#    - width
mean_w = df['width'].mean()
std_w  = df['width'].std(ddof=0)
df['width_zscore'] = (df['width'] - mean_w) / std_w

# ——————————————————————————————
# 4️⃣ Save the augmented file
df.to_csv(OUTPUT_FILE, index=False)
print(f"✅ Saved file with 'julian_date_zscore' and 'width_zscore' to {OUTPUT_FILE}")
