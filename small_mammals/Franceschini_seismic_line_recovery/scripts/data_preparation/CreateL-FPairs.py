import pandas as pd
from pathlib import Path
import re

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
INPUT_FILE  = DATA_DIR / "New_data_zscored.csv"            # or your latest file
OUTPUT_FILE = DATA_DIR / "New_data_with_pair_ids.csv"

# ——————————————————————————————
# 2️⃣ Load the data
df = pd.read_csv(INPUT_FILE)

# ——————————————————————————————
# 3️⃣ Extract disturbance code (C,N,P) and numeric ID, zero‑pad ID to two digits
#    from strings like "SM-C-L-03" or "SM-N-F-12"
pattern = r"^SM-([CNP])-[LF]-(\d+)$"
extracted = df['location'].str.extract(pattern)
df['disturbance'] = extracted[0]
df['num_id']       = extracted[1].astype(int).astype(str).str.zfill(2)

# ——————————————————————————————
# 4️⃣ Create a pair key combining disturbance code and numeric ID
df['pair_key'] = df['disturbance'] + '-' + df['num_id']

# ——————————————————————————————
# 5️⃣ Assign each unique pair_key a sequential integer ID
unique_keys = sorted(df['pair_key'].dropna().unique())
key_to_id    = {key: idx + 1 for idx, key in enumerate(unique_keys)}
df['pair_id'] = df['pair_key'].map(key_to_id).astype('Int64')

# ——————————————————————————————
# 6️⃣ Save the augmented file
df.to_csv(OUTPUT_FILE, index=False)

# ——————————————————————————————
# 🔢 Report how many pairs were found
print(f"✅ Saved file with `pair_id` column to {OUTPUT_FILE}")
print(f"🔢 Found {len(unique_keys)} unique location pairs")
