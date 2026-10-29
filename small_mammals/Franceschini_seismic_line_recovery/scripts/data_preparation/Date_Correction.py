import pandas as pd
from datetime import timedelta

# === File path ===
input_file = "C:/Users/alefr/Documents/2024_dataFix/Combined_2023_2024_Observations.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_Observations.csv"

# === Load data ===
df = pd.read_csv(input_file)
df.columns = df.columns.str.strip().str.lower()

# === Normalize 'location' and parse timestamps ===
df['location'] = df['location'].astype(str).str.strip().str.lower()
df['image_date_time'] = pd.to_datetime(df['image_date_time'], errors='coerce')

# === FIX: Shift all dates for location 'sm-n-l-217' forward by 15 days (time stays unchanged) ===
mask_217 = df['location'] == 'sm-n-l-217'
df.loc[mask_217, 'image_date_time'] = df.loc[mask_217, 'image_date_time'] + timedelta(days=18)

# === Drop invalid datetimes if any ===
df = df.dropna(subset=['image_date_time'])

# === Split datetime into separate columns ===
df['image_date'] = df['image_date_time'].dt.date
df['image_time'] = df['image_date_time'].dt.time

# === Save cleaned/prepared file ===
df.to_csv(output_file, index=False)

print(f"✅ Camera data prepared and saved to:\n{output_file}")
