# OHV Use on Linear Features – Apoorv Saini

**Thematic area:** Human use  
**Lead:** Apoorv Saini, BERA Human and Wildlife Team  
**Years:** 2021–2024  
**Region:** Northeastern Alberta, Canada (about 54.7–57.7 °N, 110.2–112.8 °W)

> 🔒 **Data available on request.** These data are restricted until they are published. The data files are not in this public repository. This README describes the data so you can decide whether you need it.
> **To request access:** email **afrances@ualberta.ca** with your name, affiliation, the dataset you need (`human_use/Saini_OHV_seismic_lines`), and how you plan to use it. Access is subject to the [Terms of Use](../../TERMS_OF_USE.md). See [DATA_ACCESS.md](../../DATA_ACCESS.md).

## About the project

This project examines how the features of seismic lines and other linear disturbances, along with their surroundings, affect off-highway vehicle (OHV) use along those lines. Each location has an OHV damage level (`level`: Low / High), assessed in the field. It is paired with:

- **Line attributes:** the type of linear feature and its land type (upland or lowland).
- **Accessibility:** distance to roads and road type, staging areas, campgrounds and residential areas.
- **Industrial footprint:** distance to mines, industrial facilities, and active and abandoned wells.
- **Terrain and moisture:** elevation, slope and NDWI (Normalized Difference Water Index).

## Folder contents

```
Saini_OHV_seismic_lines/
├── README.md
├── data/
│   └── Saini_BERA_OHV.csv       ← main dataset
└── metadata/
    └── data_dictionary.csv      ← column-by-column definitions
```

## The dataset: `data/Saini_BERA_OHV.csv`

- **Format:** comma-separated values, with a header row, UTF-8 encoding and no missing values.
- **Size:** 1,088 rows × 24 columns (about 200 KB).
- **Unit of observation:** one row per surveyed location on a linear feature. Each location has a unique ID in the `location` column.

### Sample summary

| | Count |
|---|---|
| Seismic lines / pipelines / powerlines | 711 / 278 / 99 |
| OHV use level: Low / High | 945 / 143 |
| Upland / Lowland | 779 / 309 |
| Survey year 2021 / 2022 / 2023 / 2024 | 10 / 162 / 643 / 273 |
| Nearest road type: Minor / Gravel / Paved | 535 / 409 / 144 |

### Columns

| Column | Description | Units / values |
|---|---|---|
| `year` | Survey year | 2021–2024 |
| `latitude`, `longitude` | Location coordinates | decimal degrees (WGS84) |
| `location` | Unique location ID | text |
| `type` | Type of linear feature | `seismicline`, `pipeline`, `powerline` |
| `level` | OHV damage level at the location (the response variable; see Methods) | `Low`, `High` |
| `easting`, `northing` | Projected coordinates | m, NAD83 / UTM Zone 12N (EPSG:26912) |
| `waterbodies.km` | Distance to the nearest waterbody | km |
| `roads.km` | Distance to the nearest road | km |
| `roadtype` | Type of the nearest road | `MINOR`, `GRAVEL`, `PAVED` |
| `mines.km` | Distance to the nearest mine | km |
| `industrial.km` | Distance to the nearest industrial facility | km |
| `activewell.km` | Distance to the nearest active well | km |
| `abwell.km` | Distance to the nearest abandoned well | km |
| `residential.km` | Distance to the nearest residential area | km |
| `cultivation.km` | Distance to the nearest cultivated land | km |
| `campground.km` | Distance to the nearest campground | km |
| `stagingarea.km` | Distance to the nearest OHV staging area | km |
| `TWP` | Alberta Township System township number | 65–100 |
| `elevation` | Elevation | m a.s.l. |
| `slope` | Terrain slope | degrees |
| `landtype` | Land type | `Upland`, `Lowland` |
| `ndwi` | Normalized Difference Water Index, mean within a 3 m buffer of the point (see Methods) | −1 to 1 |

## Methods (summary)

**OHV damage level (`level`).** Visible OHV-related damage was assessed by walking approximately 50 m along each linear feature:
- **Low:** no visible damage, or signs of past activity without deep ruts or vegetation damage;
- **High:** substantial evidence of motorized activity, including deep ruts or dead and flattened vegetation.

**NDWI.** Calculated in Google Earth Engine from Sentinel-2 surface reflectance imagery, May–August 2021–2024, using scenes with less than 10 % cloud cover. Mean values were extracted within 3 m buffers around the sampling points.

**Coordinates.** `latitude`/`longitude` are decimal degrees. `easting`/`northing` are NAD83 / UTM Zone 12N (EPSG:26912).

**Slope** is in degrees.

⚠️ *Still to add by Apoorv Saini:* the spatial layers used for the distance variables (e.g. ABMI Human Footprint Inventory, AltaLIS) and the DEM used for elevation and slope.

## Citation

*Add a thesis or paper citation once it is available.* Saini, A. (year). *Title.* BERA – Boreal Ecosystem Recovery and Assessment.

## Contact

Apoorv Saini. *Add an email address.*
