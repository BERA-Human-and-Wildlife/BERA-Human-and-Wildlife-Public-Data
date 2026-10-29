import pandas as pd
import tkinter as tk
from tkinter import simpledialog, messagebox

# === Ask user for the interval ===
root = tk.Tk()
root.withdraw()  # hide the root window

try:
    interval_min = simpledialog.askinteger("Set Filter Interval", "Enter interval in minutes (e.g. 15):", minvalue=1)
    if interval_min is None:
        raise Exception("No input provided. Exiting.")
except Exception as e:
    messagebox.showerror("Input Error", str(e))
    exit()

interval_sec = interval_min * 60

# === File paths ===
input_file = "C:/Users/afran/Documents/Chapter 2/Data preparation/filtered_forest_dataset_with_delta.csv"
output_file = f"C:/Users/afran/Documents/Chapter 2/Data preparation/Independent_Forest_Detections_{interval_min}min.csv"

# === Load and clean data ===
df = pd.read_csv(input_file)
df.columns = df.columns.str.strip().str.lower()
df['location'] = df['location'].astype(str).str.strip().str.upper()
df['species_common_name'] = df['species_common_name'].astype(str).str.strip().str.lower()
df['image_date_time'] = pd.to_datetime(df['image_date_time'], errors='coerce')
df = df.sort_values(by=['location', 'species_common_name', 'image_date_time'])

# === Apply independent detection filter ===
filtered_rows = []
for (loc, species), group in df.groupby(['location', 'species_common_name']):
    last_time = None
    for _, row in group.iterrows():
        current_time = row['image_date_time']
        if last_time is None or (current_time - last_time).total_seconds() >= interval_sec:
            filtered_rows.append(row)
            last_time = current_time

# === Save output ===
filtered_df = pd.DataFrame(filtered_rows)
filtered_df.to_csv(output_file, index=False)

messagebox.showinfo("Done!", f"Filtered {len(filtered_df)} rows saved to:\n{output_file}")
