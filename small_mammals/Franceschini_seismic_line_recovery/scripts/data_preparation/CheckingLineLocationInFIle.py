import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR           = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
LINE_FILE          = DATA_DIR / "Line_locations.csv"
INDEP_FILE         = DATA_DIR / "Independent_Detections_60min.csv"
MISSING_OUTPUT     = DATA_DIR / "line_locations_not_in_60min.csv"

# ——————————————————————————————
# 2️⃣ Load the data
df_lines = pd.read_csv(LINE_FILE)
df_indep = pd.read_csv(INDEP_FILE)

# ——————————————————————————————
# 3️⃣ Compare unique locations
loc_lines = set(df_lines['location'].dropna().unique())
loc_indep = set(df_indep['location'].dropna().unique())

missing = sorted(loc_lines - loc_indep)

# ——————————————————————————————
# 4️⃣ Report & save missing locations
if missing:
    print(f"❗️ {len(missing)} locations from Line_locations not found in Independent_Detections_60min:")
    for loc in missing:
        print(f"  • {loc}")
    pd.DataFrame({'missing_location': missing}).to_csv(MISSING_OUTPUT, index=False)
    print(f"\n✅ Missing locations saved to {MISSING_OUTPUT}")
else:
    print("✅ All locations in Line_locations are present in Independent_Detections_60min.")
