import pandas as pd
from pathlib import Path

# ——————————————————————————————
# 1️⃣ File paths (update as needed)
DATA_DIR    = Path(r"C:\Users\afran\Documents\Chapter 2\Data preparation")
INPUT_CSV   = DATA_DIR / "Location_Species_Counts_Merged_With_ActiveHours_Modified.csv"
OUTPUT_CSV  = DATA_DIR / "Location_Species_Counts_Merged_With_JulianDate.csv"

# ——————————————————————————————
# 2️⃣ Load the data
df = pd.read_csv(INPUT_CSV)

# ——————————————————————————————
# 3️⃣ Parse 'start_date' and compute Julian date (day-of-year since 01/01/2023)
#    - Convert to datetime, specifying dayfirst for dd/mm/yyyy
df['start_date_parsed'] = pd.to_datetime(
    df['start_date'],
    format="%d/%m/%Y",
    dayfirst=True,
    errors='coerce'
)

#    - Reference for 1 January 2023
ref = pd.Timestamp(year=2023, month=1, day=1)

#    - Compute Julian date: days since ref, plus 1 so Jan 1 → 1
df['julian_date'] = (df['start_date_parsed'] - ref).dt.days + 1

# ——————————————————————————————
# 4️⃣ Save the augmented file
df.to_csv(OUTPUT_CSV, index=False)

print(f"✅ Saved file with 'julian_date' column to {OUTPUT_CSV}")
