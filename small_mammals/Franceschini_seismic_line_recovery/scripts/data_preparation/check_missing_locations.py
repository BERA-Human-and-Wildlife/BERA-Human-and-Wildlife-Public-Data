import os
import pandas as pd

# === CONFIG ===
csv_path = r"C:\Users\alefr\Documents\2024_dataFix\Locations_used.csv"
image_folder = r"\\nfs2.wildtrax.ca\BUworkspace\BayneLabWorkSpace\Alessandro_Workspace\GR_Pictures_Only"

# === LOAD CSV LOCATIONS ===
df = pd.read_csv(csv_path)
csv_locations = set(df["Locations"].dropna().str.strip().str.upper())

# === LOAD FILENAMES AND EXTRACT BASES ===
folder_files = os.listdir(image_folder)
folder_locations = set()

for fname in folder_files:
    if "_GR" in fname.upper():
        base = fname.upper().split("_GR")[0].strip()
        folder_locations.add(base)

# === COMPARE ===
extra_locations = folder_locations - csv_locations

# === PRINT RESULTS ===
print(f"🖼️ Total picture locations found: {len(folder_locations)}")
print(f"📄 Total locations in CSV: {len(csv_locations)}")
print(f"⚠️ Locations in folder but NOT in CSV: {len(extra_locations)}\n")

for loc in sorted(extra_locations):
    print(f"❌ Not in CSV: {loc}")

# === OPTIONAL: Save to CSV ===
output_csv = os.path.join(image_folder, "extra_locations_not_in_CSV.csv")
pd.DataFrame({"Extra_Locations": list(extra_locations)}).to_csv(output_csv, index=False)
print(f"\n📄 Extra locations saved to: {output_csv}")
