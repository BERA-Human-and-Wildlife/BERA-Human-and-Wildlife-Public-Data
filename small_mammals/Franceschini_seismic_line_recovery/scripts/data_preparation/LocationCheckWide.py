import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR            = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
WIDE_FILE           = DATA_DIR / "Independent_Detections_60min_wide.csv"
LINE_FILE           = DATA_DIR / "Line_locations.csv"
MISSING_IN_WIDE     = DATA_DIR / "locations_in_line_not_in_wide.csv"
MISSING_IN_LINE     = DATA_DIR / "locations_in_wide_not_in_line.csv"

# ——————————————————————————————
# 2️⃣ Load the data
df_wide = pd.read_csv(WIDE_FILE)
df_line = pd.read_csv(LINE_FILE)

# ——————————————————————————————
# 3️⃣ Compute unique location sets
loc_wide = set(df_wide['location'].dropna().unique())
loc_line = set(df_line['location'].dropna().unique())

# ——————————————————————————————
# 4️⃣ Identify missing locations
missing_in_wide = sorted(loc_line - loc_wide)
missing_in_line = sorted(loc_wide - loc_line)

# ——————————————————————————————
# 5️⃣ Save missing lists
pd.DataFrame({'missing_from_wide': missing_in_wide}).to_csv(MISSING_IN_WIDE, index=False)
pd.DataFrame({'missing_from_line': missing_in_line}).to_csv(MISSING_IN_LINE, index=False)

# ——————————————————————————————
# 6️⃣ Print summary
print(f"❗️ {len(missing_in_wide)} locations in Line_locations not found in wide file")
print(f"❗️ {len(missing_in_line)} locations in wide file not found in Line_locations")
