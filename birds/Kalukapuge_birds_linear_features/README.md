# Bird Communities on Linear Features – Tharindu Kalukapuge

**Thematic area:** Birds  
**Lead:** Tharindu Kalukapuge, Bayne Lab (BERA Human and Wildlife Team)  
**Years:** 2021–2024  
**Region:** Alberta, Canada. All sites span about 49.0–59.6 °N and 110.2–120.6 °W; the boreal subset spans about 54.4–59.6 °N and 110.2–119.4 °W.

> 🔒 **Data available on request.** These data are internal to the BERA Human and Wildlife Team. Access needs the data owner's approval. The data files are not in this public repository. This README describes the data so you can decide whether you need it.
> **To request access:** email **afrances@ualberta.ca** with your name, affiliation, the dataset you need (`birds/Kalukapuge_birds_linear_features`), and how you plan to use it. See [DATA_ACCESS.md](../../DATA_ACCESS.md).

## About the project

This project surveyed songbirds at sites on linear features: conventional and low-impact seismic lines, pipelines, transmission lines, roads and truck trails. It asks how bird abundance and community composition relate to the width of the line, to the human footprint around the site, and to the amount of wetland around the site. The data come from two survey types, recorded in the `project` column:

- **ARU:** stationary autonomous recording unit sites (`2021_23_ARU`, `2024_ARU`)
- **Mobile:** mobile survey points (`2021_23_Mobile`, `2024_Mobile`)

## Folder contents

```
Kalukapuge_birds_linear_features/
├── README.md
├── data/
│   ├── Linear_Feature_Species_Abundance_Matrix_2021_2024_Data_TharinduKalukapuge_BayneLab.csv
│   ├── Linear_Feature_SelectedSites_BorealNaturalRegion_Width_Data_TharinduKalukapuge_BayneLab.csv
│   ├── Linear_Feature_Footprint_Data_2021_2024_Data_TharinduKalukapuge_BayneLab.csv
│   └── Linear_Feature_Wetland_Data_2021_2024_Data_TharinduKalukapuge_BayneLab.csv
└── metadata/
    ├── original_column_description.txt   ← column descriptions supplied by the author
    └── species_codes.csv                  ← all species codes, the files they appear in, and total counts
```

## How the files link

The four files share a site ID: the `location` column, which is called `Name` in the wetland file.

```
Species_Abundance_Matrix (3,358 sites, all of Alberta)
 ├── Footprint_Data          3,349 sites matched (500 m buffer)
 └── Wetland_Data            909 sites, all matched (300 m buffer)
      └── SelectedSites_BorealNaturalRegion_Width   736 boreal sites, all matched
```

The width file is the **analysis subset**. It keeps only sites in the Boreal Natural Region and adds the feature type and line width.

## Datasets

### 1. `Species_Abundance_Matrix`: bird counts at every site
- **Size:** 3,358 rows × 128 columns. One row per site.
- **Columns:** `location` (site ID), `latitude`, `longitude` (decimal degrees), `project` (survey type and period), followed by **124 four-letter species codes** in columns 5–128.
- **Values:** whole-number abundance of each species at the site, from 0 to 10. ⚠️ Confirm whether this is the maximum count per visit or the total across visits, and how many visits or recordings each site had.
- **Sample:** `2021_23_Mobile` 2,772 · `2021_23_ARU` 307 · `2024_Mobile` 236 · `2024_ARU` 43. On average 7 species are detected per site, and 14 sites have no detections. The most abundant species are WTSP, TEWA, SWTH, YRWA, AMRO, OVEN, REVI and CHSP.

### 2. `SelectedSites_BorealNaturalRegion_Width`: boreal sites with line width
- **Size:** 736 rows × 75 columns. One row per site. No missing values.
- **Columns:** `location`, `latitude`, `longitude`, `project`, then:
  - `Footprint_Type`: the type of feature the survey was done on;
  - `Line_Width_m`: the width of the feature from edge to edge, in metres;
  - **69 species codes** in columns 7–75, a subset of the 124 species in the abundance matrix.
- **Feature types and median widths:** pipeline 221 sites (33 m) · conventional seismic 163 (7 m) · gravel road, two-lane 86 (35 m) · gravel road, one-lane 81 (26 m) · vegetated road edge 77 (32 m) · transmission line 67 (63 m) · low-impact seismic 30 (5 m) · truck trail 11 (26 m). Widths range from 2 to 207 m.

### 3. `Footprint_Data`: human footprint within 500 m
- **Size:** 3,404 rows × 83 columns. One row per site.
- **Columns:**
  - `location`;
  - **76 footprint-type columns**, from `CONVENTIONAL_SEISMIC` to `AIRP_RUNWAY`. Each gives the total area (m²) of that footprint type within the buffer, including every feature of that type, not only the line that was surveyed;
  - `nearest_feature_type`, `nearest_year` and `nearest_source`, which describe the footprint feature nearest the site;
  - `buffer_area`: 785,398 m² for every site, which is a circle of radius 500 m;
  - `total_footprint_area` (m²);
  - `footprint_proportion`: the share of the buffer covered by footprint, from 0 to 1 (median 0.22).
- **Footprint groups:** linear features; roads; wells and oil and gas facilities; pits, mines and water; forestry and clearing; agriculture; residential, urban and recreation; rail and airports; reclamation and industrial sites (`RIS_` prefix). `metadata/original_column_description.txt` lists which columns belong to each group.
- **Notes:**
  - `nearest_feature_type` writes types with hyphens (`TRANSMISSION-LINE`), while the area columns use underscores (`TRANSMISSION_LINE`).
  - Sources include AHFMP (most sites), several ABMI vintages, BASEFE and AVI.
  - Missing values (`NA`): `nearest_feature_type` and `nearest_year` for 102 sites, and `nearest_source` for 215 sites.
  - One site has `nearest_year` = 1900, which is probably a placeholder for an unknown year.

### 4. `Wetland_Data`: wetland cover within 300 m
- **Size:** 909 rows × 18 columns. One row per site. No missing values.
- **Columns:**
  - `Name` (site ID), `latitude`, `longitude`;
  - area in m² and proportion of the buffer for each ABMI wetland class: `Fen`, `Bog`, `Marsh`, `Swamp` and `OpenWater`, as `_m2` and `_prop` columns;
  - `BufferArea_m2`: 282,743 m² for every site, which is a circle of radius 300 m;
  - `Total_Lowland_m2` / `Lowland_prop`: the five classes added together;
  - `Upland_m2` / `Upland_prop`: what is left of the buffer after the lowland classes. The upland figure is derived, not mapped, and `Upland_prop` = 1 − `Lowland_prop`.
- **Sample:** the median lowland cover is 1.6 % of the buffer and the mean is 17 %.

## Data notes and known issues

- The abundance matrix has **9 sites with missing coordinates**: BU21-10-11, P-E0-3-21, P-E0-M177, S-E0-M220, BUM-23-863, BUM-23-864, BUM-23-874, BUM-23-886 and BUM-23-888.
- Site **BUM-23-1003** has a **positive longitude** (111.01). It is almost certainly −111.01.
- Species codes follow the standard four-letter alpha codes (e.g. WTSP = White-throated Sparrow). `metadata/species_codes.csv` lists all 124 codes.
- Site ID prefixes (BUM, BBS, P, S, R, PM, SM, …) identify the original sampling programs. ⚠️ Their meanings are to be documented.

## Methods (summary)

*To be completed by Tharindu Kalukapuge.* Please cover:
- the ARU recording schedule and how recordings were processed (e.g. WildTrax, number of minutes listened);
- the mobile survey protocol;
- how line width was measured (field or imagery);
- the footprint layers used (ABMI Human Footprint Inventory and its year);
- the ABMI wetland inventory version.

## Citation

*Add a thesis or paper reference once it is available.* Kalukapuge, T. (year). *Title.* Bayne Lab, University of Alberta / BERA – Boreal Ecosystem Recovery and Assessment.

## Contact

Tharindu Kalukapuge, Bayne Lab. *Add an email address.*
