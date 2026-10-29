# Effect of Seismic Line Regeneration on Small Mammals

**Thematic area:** Small mammals  
**Lead:** Alessandro Franceschini, University of Alberta / Bayne Lab, BERA Human and Wildlife Team  
**Field seasons:** 2023 and 2024 (late May – mid August)  
**Region:** northeastern Alberta

> 🔒 **Data available on request.** These data are restricted until they are published. The data files are not in this public repository. This README describes the data so you can decide whether you need it.
> **To request access:** email **afrances@ualberta.ca** with your name, affiliation, the dataset you need (`small_mammals/Franceschini_seismic_line_restoration`), and how you plan to use it. See [DATA_ACCESS.md](../../DATA_ACCESS.md).

## About the project

Baited camera traps were placed in **pairs**: one on a seismic line, either conventional or low-impact, and one in the adjacent undisturbed forest interior. The study tests whether small-mammal activity on the line changes with the line's **regeneration (succession) stage**, measured against the undisturbed interior.

**Response.** The count of **independent detections**, where detections of the same species at the same site less than 60 minutes apart count as one. A 15-minute version is included as a sensitivity check.

**Models.** Species-specific **negative binomial GLMMs** (`glmmTMB`, `nbinom2`), with:
- an offset of `log(active_hours)`, so that differences in camera effort are accounted for;
- a random intercept for the camera pair (`pair_id`).

The base model is `species ~ julian_date_zscore + Succession_4 + offset(log(active_hours)) + (1 | pair_id)`. It is extended with `forest_cover × Succession_4 × disturbance` and compared by AICc using `MuMIn::dredge`. Of the models within ΔAICc ≤ 2, the **most parsimonious** (fewest parameters) is reported. Stage contrasts are estimated with `emmeans`, using Dunnett comparisons against stage 4 and Tukey comparisons between all pairs.

**Main species:**
- southern red-backed vole
- dusky shrew
- deer mouse
- red squirrel
- snowshoe hare, which was explored but has few detections

## Folder contents

```
Franceschini_seismic_line_restoration/
├── README.md
├── data/
│   ├── raw/
│   │   └── Final_Data_With_NewExG_Transitions.csv         ← site / deployment table with field attributes and vegetation indices
│   ├── processed/
│   │   ├── Detections_With_Metadata_SpeciesMerged_Rev.csv.gz   ← tagged images with site metadata (gzipped)
│   │   └── Independent_Detections_60min.csv               ← independent detection events (60 min)
│   └── analysis/
│       ├── Data_60min.csv            ← MAIN analysis dataset (282 sites)
│       ├── Data_15min.csv            ← same, with a 15-min independence threshold
│       └── Dataset_CH2_scaled2.csv   ← line sites only (137), with on-line vegetation indices
├── results/
│   ├── Best_AIC_Models_per_Species.csv
│   ├── Corrected_Competitive_Models__AIC___min___2_.csv
│   └── Species_Occupancy__e_g__40_60_.csv
└── scripts/
    ├── data_preparation/   ← Python and R scripts: raw WildTrax export → analysis datasets
    └── analysis/           ← R scripts for the models, model selection and figures
```

## Main dataset: `data/analysis/Data_60min.csv`

- **Size:** 282 sites × 25 columns. One row per camera site.
- **Sites:** 141 forest interior, 76 conventional seismic and 65 low-impact seismic. They form 141 line–interior pairs.
- **Forest cover:** 92 Deciduous, 82 Mixedwood, 68 Lowland Spruce and 40 Upland Spruce.

| Column | Description | Units / values |
|---|---|---|
| `location` | Site ID. `SM-C` = conventional, `SM-N` = low-impact; `-L` = line, `-F` = forest interior. | text |
| `active_hours` | Hours the camera was active. Used as the offset. | h. Median 95; range 0–171 ⚠️ |
| `julian_date`, `julian_date_zscore` | Day of the year of deployment, raw and as a z-score | 144–224 |
| `latitude`, `longitude` | Site coordinates | decimal degrees |
| `width`, `width_zscore` | Line width. 0 for interior. | m, 0–22 |
| `seismic_line_type` | Type of site | Forest interior, Conventional seismic, Low-impact seismic |
| `disturbance` | Disturbance type of the pair | `C` = conventional, `N` = low-impact |
| `forest_cover` | Ecotype | Deciduous, Mixedwood, Lowland Spruce, Upland Spruce |
| `black.bear` … `western.jumping.mouse` (10 columns) | Count of independent detections (60 min) for each species | count |
| `pair_id`, `pair_key`, `num_id` | Pair identifiers. `pair_id` is the random effect. | |
| **`Succession_4`** | **Regeneration stage used in the final models.** 1–3 are line regeneration levels, from least to most regenerated; 4 is the undisturbed interior and serves as the baseline. | 1: 65, 2: 48, 3: 28, 4: 141 |

⚠️ Points to confirm and document:
- how the regeneration stages (`Succession_4`, 1–3) were assigned to line sites;
- why some sites have `active_hours` = 0 or more than 120 h.

## Other datasets

- **`Data_15min.csv`:** identical to `Data_60min.csv` except that detections count as independent after 15 minutes. Used as a sensitivity check.
- **`Dataset_CH2_scaled2.csv`:** the 137 **line** sites only. It adds:
  - field attributes: `humanuse_intensity`, `trail_present`, `veg_structure`, `veg_regen_status`;
  - vegetation-greenness indices computed from the camera images (`exg_*`, `vari_0`, `tgi_0`, `gli_0`, `ngrdi_0`), together with `line_*` versions taken from the bottom 60 % of a photo of the line (see `scripts/data_preparation/Line_Veg_indexes_calculation.py`); the values are the % of pixels over each threshold, with `*_scaled` z-score versions;
  - 13 species counts;
  - `Succession_4`, the regeneration stage, taken from `Data_60min.csv`.

  This dataset was used to test which vegetation index best explains detections. The results are in `results/Best_AIC_Models_per_Species.csv`.
- **`Final_Data_With_NewExG_Transitions.csv`:** one row per deployment, 244 in all (139 in 2023 and 105 in 2024). It holds the field form attributes (line width, shape, cover, tree height, human-use intensity, trail, regeneration status, vegetation structure, active restoration, forest cover, standing water), deployment and retrieval dates and times, and the vegetation indices.
- **`Independent_Detections_60min.csv`:** one row per independent detection event (11,067 rows; 2023 and 2024). Columns include the site, image time, species, count, deployment start, and hours since start (`delta_time_hours`). It includes `none`, `human` and `staff/setup` events, which are excluded from the analysis.
- **`Detections_With_Metadata_SpeciesMerged_Rev.csv.gz`:** tagged images (18,131 rows) joined to the site metadata, with species names harmonised. This is the input to `Prepare data with julian date and active hours.R` and `Prepare wide format.R`.

## Results

- **`Best_AIC_Models_per_Species.csv`:** the best vegetation-index covariate for each species, under three site filters: all sites, no Upland Spruce, and no Upland or Lowland Spruce.
- **`Corrected_Competitive_Models__AIC___min___2_.csv`:** the competing models within ΔAIC ≤ 2.
- **`Species_Occupancy__e_g__40_60_.csv`:** naïve occupancy (sites with a detection / sites) for each species and forest cover type.

## Scripts

### `data_preparation/`
These scripts run in roughly this order:
1. `Data_merge.py`, `Fix-554.py`, `Date_Correction.py`: merge the 2023 and 2024 WildTrax exports and fix dates and site names.
2. `ForestPointFilter2023.py`, `Data_filter_2023.py`, `CreateL-FPairs.py`: select the sites and build the line–interior pairs.
3. `Delta_hours.py`, `add_delta_time_column.py`, `filter_first_hour.py`, `filter_15min_independent.py`: compute time since deployment, drop the setup period, and apply the independence filters.
4. `Merge_Detection_W_Table.py`, `CheckingRestoValues.py`, `attach_transitions_to_detections.py`: join detections with the site table and the regeneration scores.
5. `Line_Veg_indexes_calculation.py`, `veg_cover_*.py`, `add_transition_columns.py`, `add_litter_bare_cover.py`: compute the image-based vegetation indices.
6. `Prepare data with julian date and active hours.R`, `Prepare wide format.R`, `AddJulianDate.py`, `ScaleJulian.py`, `60minToWide.py`: build the site × species tables.
7. The remaining `check*`, `Location*` and `*missing*` scripts are consistency checks.

### `analysis/`
| Script | Purpose |
|---|---|
| `All_species_AIC_Sel_Cleaned.R` | **Main analysis.** For each species: negative binomial GLMMs, dredge, the most parsimonious model, DHARMa diagnostics, emmeans contrasts and figures. |
| `ALL_species_AIC_Word.R` | Exports the model selection tables to Word |
| `Succession+Seismic.R`, `SuccessionNoSeismic.R`, `Seismic Interaction.R` | Models by forest cover, with and without line type and with interactions |
| `*_modSel*.R` | Vegetation-index model selection for each species (on `Dataset_CH2_scaled2.csv`) |
| `Beta Estimate combined Update.R` | Combined coefficient figure for all species |
| `PCA_SP_IND.R` | PCA of the vegetation indices |

**Notes on running the scripts**
- They use absolute paths from the author's computer, such as `C:/Users/afran/Documents/Chapter 2/...`. Change these to the repository paths before running.
- `Line_Veg_indexes_calculation.py` needs the line photos, which are not included. They are on the Bayne Lab server.

**Not included.** The original WildTrax exports (more than 700 MB), intermediate and debug files, the field deployment and retrieval forms (they contain observer details), earlier regeneration classifications (superseded by `Succession_4`), figures, and Word outputs. Archive the raw WildTrax exports in WildTrax itself or on the lab server.

## Citation

Franceschini, A. *et al.* (in prep.). *Title.* Add the reference once it is available.

## Contact

Alessandro Franceschini. *Add an email address.*
