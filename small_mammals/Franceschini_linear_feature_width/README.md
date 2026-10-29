# The Influence of Linear Feature Width on Small Mammal Communities in Northeastern Alberta

> ✅ **Open data.** The data and code in this folder are released under CC BY 4.0 (see `LICENSE`). Please cite the paper below.

**Thematic area:** Small mammals  
**Authors:** Alessandro Franceschini, Juan Andrés Martínez-Lanfranco, Erin Bayne. Department of Biological Sciences, University of Alberta (Bayne Lab), BERA Human and Wildlife Team  
**Field season:** 24 May – 20 August 2023  
**Region:** southern Lower Athabasca region, northeastern Alberta (Cold Lake to Wandering River, and Wolf Lake to Anzac)  
**Publication:** Franceschini A., Martínez-Lanfranco J.A., Bayne E. (2025). *Can. J. Zool.* 103: 1–14. [doi:10.1139/cjz-2025-0078](https://doi.org/10.1139/cjz-2025-0078). Open access (CC BY 4.0). A copy is in `docs/`.

## About the study

The study asks how the **width** of vegetated linear features affects small-mammal use and community composition. Feature widths ranged from 3 to 150 m, covering low-impact seismic lines, conventional seismic lines, and pipelines or transmission lines.

**Sites.**
- Baited remote cameras with a short focal length were placed at **354 sites**. Each site on a line was paired with a control site in the adjacent forest interior.
- Sites were stratified by width class (1–5, 6–10 and 10–150 m) and ecotype (upland deciduous, mixedwood, lowland coniferous).
- After removing cameras disturbed by bears or that malfunctioned, **302 sites** remained (157 forest, 146 line).

**Sampling effort.** Cameras ran for four nights. Only detections from the **2nd to the 94th hour** after deployment were used.

**Community-level analyses:**
- a **redundancy analysis (RDA)** on the Hellinger-transformed presence–absence matrix, with log-width, ecotype and day of the year as predictors;
- variation partitioning;
- a **fourth-corner analysis** linking species' forest affiliation to width.

**Species-level analyses.** A **binomial GLMM** (`glmmTMB`) was fitted for each of the 9 species with naïve occupancy ψ ≥ 0.05. Each model includes:
- `log(width + 1)`, scaled;
- ecotype;
- day of the year;
- a residual **spatial autocovariate**, from a GAM trend surface on latitude and longitude;
- a random intercept for each line–control **pair**.

Log-width was compared with a quadratic width term using AIC.

**Main findings.** Width had a significant negative effect on:
- southern red-backed vole (β = −0.74)
- American red squirrel (−0.71)
- deer mouse (−0.56)
- short-tailed weasel (−1.12)

No species responded positively. Wider features showed lower overall use rather than a replacement by open-habitat species.

## Species

Species are named as in the paper (Table 2) in every file. In the data files they appear as `GENUS.SPECIES` columns, for example `MYODES.GAPPERI` and `SOREX.SPP`.

| Data column | Species | Naïve ψ | Width effect (Table 3) |
|---|---|---|---|
| `MYODES.GAPPERI` | Southern red-backed vole (*Myodes gapperi*) | 0.42 | negative, p < 0.001 |
| `SOREX.SPP` | Shrews (*Sorex* spp.; all shrews pooled) | 0.45 | n.s. |
| `TAMIASCIURUS.HUDSONICUS` | American red squirrel (*Tamiasciurus hudsonicus*) | 0.24 | negative, p < 0.001 |
| `PEROMYSCUS.MANICULATUS` | Deer mouse (*Peromyscus maniculatus*) | 0.16 | negative, p = 0.020 |
| `MICROTUS.DRUMMONDII` | Meadow vole (*Microtus drummondii*) | 0.09 | n.s. |
| `LEPUS.AMERICANUS` | Snowshoe hare (*Lepus americanus*) | 0.09 | n.s. (p = 0.051) |
| `MARTES.AMERICANA` | American marten (*Martes americana*) | 0.07 | n.s. |
| `ZAPUS.PRINCEPS` | Western jumping mouse (*Zapus princeps*) | 0.06 | n.s. |
| `MUSTELA.ERMINEA` | Short-tailed weasel (*Mustela erminea*) | 0.05 | negative, p = 0.022 |

The other taxa in the detection files are *Ursus americanus*, *Glaucomys sabrinus*, *Procyon lotor*, *Canis lupus familiaris*, *Odocoileus virginianus*, *Perisoreus canadensis* (a bird) and *Homo sapiens*. They were not modelled.

## Folder contents

```
Franceschini_linear_feature_width/
├── README.md
├── docs/
│   └── Franceschini_2025_CJZ_linear_feature_width.pdf   ← the published paper
├── data/
│   ├── raw/
│   │   ├── DataTEAM_STD.csv.gz         ← image-level detections within the analysis window (gzipped)
│   │   └── TableCovs_corrected.csv     ← camera deployments and site attributes (all 462 deployments)
│   ├── processed/
│   │   ├── camera_days.txt             ← trap-days per camera
│   │   └── events_1day.csv             ← site × species detection-days (1-day independence)
│   └── analysis/
│       ├── GLM_data_1day.csv           ← analysis dataset: 303 sites, detections + site attributes
│       └── Data_ALE.csv                ← the same, plus model variables (log-width, binary responses, autocovariates)
├── results/
│   ├── supplement_models.csv           ← Supplementary Table S1: GLMM coefficients for all 9 species
│   ├── AIC_comparison_full.csv         ← Supplementary Table S2: log-width vs width vs quadratic, by species
│   └── AIC_log_vs_widthpoly.csv        ← log-width vs quadratic ΔAIC
└── scripts/                            ← R scripts, numbered in the order they run
```

## Data flow

```
WildTrax project (raw images and tags; available on request)
   │ 01  clean the export, drop failed cameras, keep the analysis time window
   ▼
data/raw/DataTEAM_STD.csv.gz ─ 02 ─► data/processed/events_1day.csv, camera_days.txt
                                                    │
data/raw/TableCovs_corrected.csv ───── 03 ─────────►┤  join, keep Deciduous / Mixedwood / Lowland
                                                    ▼
                                    data/analysis/GLM_data_1day.csv
                                                    │ 04 / species_models/
                                                    ▼
                                    data/analysis/Data_ALE.csv ─► Fig. 3, Table 3
                                                    │
                     05 ─► results/supplement_models.csv (Table S1)
                     06 ─► results/AIC_*.csv (Table S2)
                     07 ─► RDA (Fig. 2), variation partitioning, fourth-corner
```

## Datasets

### `data/raw/DataTEAM_STD.csv.gz`: image-level detections
- **Content:** one row per tagged image within each camera's analysis window. There are about 353,000 rows (250 MB uncompressed). Read it in R with `read.csv(gzfile(...))`.
- **Columns:** WildTrax fields (`location`, `image_date_time`, `Genus`, `Species`, `Scientific.Name`, `species_common_name`, `individual_count`, …), the site attributes, deployment start and end, `TimeDifference` (hours since the camera started), and TEAM-library fields (`Sampling.Unit.Name`, `bin`, `td.photo`).
- Observer names and IDs have been removed.

### `data/raw/TableCovs_corrected.csv`: deployment and site table
- **Format:** semicolon-separated, with commas as decimal separators. Read it with `read.csv(..., sep = ";")`.
- **Coordinates:** NAD83 decimal degrees.

| Column | Description |
|---|---|
| `Locations` | Camera site ID. `-L` = line, `-F` = forest control. |
| `SP.Group` | Line–control pair ID, used as the random effect |
| `Family` | Feature type of the pair: `3D` = low-impact seismic, `C` = conventional seismic, `P` = pipeline, `T` = transmission line |
| `Latitude`, `Longitude` | Site coordinates |
| `Start_Date`, `Start_Time`, `End_Date`, `End_Time` | When the camera was deployed and retrieved |
| `Month`, `Month2` | Month of deployment |
| `Type_of_CT` | Camera model: white flash (Reconyx PC900) or infrared (Hyperfire 2) |
| `Position` | `Line` or `Forest` |
| `Footprint_Type`, `Footprint_Fine` | Feature class, at coarse and fine resolution |
| `Width` | Linear feature width in metres. 0 for controls. |
| `Veg_Cover` | Dominant vegetation at the camera |
| `Intensity_Use` | Observed human use of the line |
| `Habitat` | Ecotype. The analysis used Deciduous, Mixedwood and Lowland; Upland Spruce and Pine sites were excluded. |

### `data/processed/`
- **`events_1day.csv`:** 356 sites × 18 taxa. Each value is the number of days on which the taxon was detected, using a 1-day independence interval. `None none` counts images with no animal. These are the counts reported in Table 2.
- **`camera_days.txt`:** start date, end date and trap-days for each camera. 302 cameras accumulated 1,306 camera-days in total.

### `data/analysis/`: model-ready data
- **`GLM_data_1day.csv`:** one row per site (303 sites: 157 forest, 146 line). It has the detection-days per species, the site attributes, `Julian_Date` and `julian_date_scaled`.
- **`Data_ALE.csv`:** the same 303 rows, plus the variables used in the GLMMs:
  - `log_Width` = log(Width + 1), and `log_Width_scale`;
  - binary detection columns such as `MYODES_BINARY`, `SOREX_BIN`, `MUSTELA_FRENATA_BINOMIAL` and `Martes_Americana_bin`;
  - the species' spatial autocovariates (`autocov_*`).

### `results/`
- **`supplement_models.csv`:** fixed effects for every species and predictor: estimate, SE, z, p, Wald 95 % CI, AIC, and marginal and conditional R². This is the source of Table 3 and Supplementary Table S1.
- **`AIC_comparison_full.csv`, `AIC_log_vs_widthpoly.csv`:** AIC, log-likelihood and degrees of freedom for log-width, linear width and quadratic width for each species (Supplementary Table S2). ΔAIC was below 2 for every species, so there was no support for a quadratic effect.

## Scripts

| Script | Purpose |
|---|---|
| `01_Getting data ready.R` | Cleans the WildTrax export, fixes site names, removes failed cameras, and applies the time window |
| `02_Detection events (TEAM).R` | Builds camera-days, 1-day independent events, naïve occupancy and species accumulation (uses `TEAM library 1.8.R`) |
| `03_Merge data, exploration, validation.R` | Joins detections with the site table, keeps the three ecotypes, adds day of year, and explores the data → `GLM_data_1day.csv` |
| `04_Species GLMMs and Figure 3.R` | Final binomial GLMMs with spatial autocovariates for all 9 species, and Figure 3 |
| `species_models/*.R` | The same models one species at a time, with DHARMa diagnostics, R² and summary tables |
| `05_Model table (Table S1).R` | Exports `supplement_models.csv` |
| `06_AIC log vs quadratic width (Table S2).R` | Compares log-width with quadratic width |
| `07_RDA and fourth-corner (Figure 2).R` | RDA, variation partitioning, `glmm.hp`, and the fourth-corner analysis (`ade4`) |
| `HighstatLibV10.R`, `TEAM library 1.8.R` | Helper libraries loaded with `source()` |

**Notes on running the scripts**
- Change the absolute `setwd()` and `read.csv()` paths (e.g. `E://UoA/Thesis/...`) to the repository paths.
- Script 03 originally also joined landscape covariates that are not used in the paper. Those files are not included, so remove the `Habitat_Amount`, `ED`, `TE` and `Covs_ArcGIS` lines before running it.
- `rgdal` and `maptools` have been retired from CRAN. Remove those `library()` calls; they are not needed for the analyses.

## Data availability

The raw camera-trap images, tags and locations are stored in **WildTrax** and are available from the lead author on request (afrances@ualberta.ca), as stated in the paper.

## Citation

Franceschini, A., Martínez-Lanfranco, J.A., and Bayne, E. 2025. The influence of linear feature width on small mammal communities in northeastern Alberta. *Canadian Journal of Zoology* 103: 1–14. https://doi.org/10.1139/cjz-2025-0078
