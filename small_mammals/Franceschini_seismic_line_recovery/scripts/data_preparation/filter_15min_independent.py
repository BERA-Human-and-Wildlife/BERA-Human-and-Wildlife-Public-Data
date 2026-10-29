import pandas as pd

# === File paths ===
input_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_No_FirstHour.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Independent_Detections_15min.csv"

# === Load data ===
df = pd.read_csv(input_file)

# === Normalize columns ===
df.columns = df.columns.str.strip().str.lower()
df['location'] = df['location'].astype(str).str.strip().str.upper()
df['species_common_name'] = df['species_common_name'].astype(str).str.strip().str.lower()
df['image_date_time'] = pd.to_datetime(df['image_date_time'], errors='coerce')

# === Sort for group-based filtering ===
df = df.sort_values(by=['location', 'species_common_name', 'image_date_time'])

# === Apply 15-minute independent detection rule ===
filtered_rows = []
for (loc, species), group in df.groupby(['location', 'species_common_name']):
    last_time = None
    for _, row in group.iterrows():
        current_time = row['image_date_time']
        if last_time is None or (current_time - last_time).total_seconds() >= 900:
            filtered_rows.append(row)
            last_time = current_time

# === Final DataFrame ===
independent_df = pd.DataFrame(filtered_rows)
independent_df.to_csv(output_file, index=False)

print(f"✅ Applied 15-minute filter per species per location")
print(f"🟢 Kept {len(independent_df)} of {len(df)} rows")
print(f"📄 Final file saved to: {output_file}")
