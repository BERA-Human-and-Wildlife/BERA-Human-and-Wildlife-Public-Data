import pandas as pd

# === File paths ===
input_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_With_DeltaTimes.csv"
output_file = "C:/Users/alefr/Documents/2024_dataFix/Prepared_No_FirstHour.csv"

# === Load data ===
df = pd.read_csv(input_file)

# === Clean column names (just in case) ===
df.columns = df.columns.str.strip().str.lower()

# === Filter out rows with delta < 1 hour ===
filtered_df = df[df['delta_time_hours'] >= 1].copy()

# === Save the result ===
filtered_df.to_csv(output_file, index=False)

print(f"⏱️ First-hour detections removed.")
print(f"🟢 Kept {len(filtered_df)} rows out of {len(df)}")
print(f"📄 Filtered file saved to: {output_file}")
