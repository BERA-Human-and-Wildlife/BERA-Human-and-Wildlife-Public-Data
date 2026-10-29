import pandas as pd

# === File paths ===
input_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_Observations.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Filtered_15min_Only.csv"

# === Load data ===
df = pd.read_csv(input_file)
df.columns = df.columns.str.strip().str.lower()

# === Parse datetime and normalize species/location text ===
df['image_date_time'] = pd.to_datetime(df['image_date_time'], errors='coerce')
df['location'] = df['location'].astype(str).str.strip().str.upper()
df['species_common_name'] = df['species_common_name'].astype(str).str.strip().str.lower()

# === Sort for filtering ===
df = df.sort_values(by=['location', 'species_common_name', 'image_date_time'])

# === Apply 15-minute independent detection rule ===
filtered_rows = []
for (location, species), group in df.groupby(['location', 'species_common_name']):
    last_time = None
    for _, row in group.iterrows():
        current_time = row['image_date_time']
        if last_time is None or (current_time - last_time).total_seconds() >= 900:
            filtered_rows.append(row)
            last_time = current_time

# === Save filtered result ===
filtered_df = pd.DataFrame(filtered_rows)
filtered_df.to_csv(output_file, index=False)

print(f"\n🎯 15-minute filtering done — no first-hour removals")
print(f"🟢 Final file saved to: {output_file}")
print(f"✔️ Kept {len(filtered_df)} of {len(df)} total rows")
