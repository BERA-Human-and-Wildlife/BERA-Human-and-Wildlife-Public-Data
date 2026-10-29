import pandas as pd

# Load the original dataset
df = pd.read_csv(r"C:\Users\afran\Documents\Chapter 2\Data preparation\BU_Franceschini_-_Small_Mammals_-_2023_main_report.csv")

# Fix the mislabeled location
df.loc[(df["equipment_serial"] == "HLPWMQ10173512") & (df["location"] == "SM-N-F-554"), "location"] = "SM-N-F-556"

# Save the corrected version
df.to_csv(r"C:\Users\afran\Documents\Chapter 2\Data preparation\BU_Franceschini_FIXED.csv", index=False)


df = pd.read_csv(r"C:\Users\afran\Documents\Chapter 2\Data preparation\BU_Franceschini_FIXED.csv")
print(df[df["equipment_serial"] == "HLPWMQ10173512"]["location"].value_counts())
