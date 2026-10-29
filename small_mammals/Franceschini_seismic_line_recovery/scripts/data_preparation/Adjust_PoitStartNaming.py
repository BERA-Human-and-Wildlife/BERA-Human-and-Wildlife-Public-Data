import pandas as pd

# === FILE PATHS (update as needed) ===
input_path  = r"C:\Users\afran\Documents\Chapter 2\Data preparation\ForestPointStart.csv"
output_path = r"C:\Users\afran\Documents\Chapter 2\Data preparation\ForestPointStart_corrected.csv"

# === Load the data ===
df = pd.read_csv(input_path)

# === Mapping: actual names in the file -> desired names ===
mapping_current_to_desired = {
    "SM-C-F-1002_NA": "SM-C-F-1002",
    "SM-N-F-1178":    "SM-C-F-1178",
    "SM-C-F-233":     "SM-C-F-1180",
    "SM-N-F-18_2":    "SM-N-F-18",
    "SM-N-F-76_2":    "SM-N-F-76",
    "SM-N-F-556":     "SM-N-F-556"
}

# === Apply renaming to the 'location' column ===
df['location'] = df['location'].replace(mapping_current_to_desired)

# === Save the corrected file as CSV ===
df.to_csv(output_path, index=False)

print(f"✅ Saved corrected file to {output_path}")
