# Small Mammal Responses to Vegetation Recovery on Seismic Lines in Alberta's Boreal Forest

> ✅ **Open data.** The data and code in this folder are released under CC BY-NC 4.0 (see `LICENSE`). Please cite the paper below.

**Thematic area:** Small mammals  
**Authors:** Alessandro Franceschini, Taylor Hart, Isabelle Lebeuf-Taylor, Erin Bayne. Department of Biological Sciences, University of Alberta (Bayne Lab), BERA Human and Wildlife Team  
**Field season:** May – August 2023  
**Region:** southern Lower Athabasca region, northeastern Alberta (Cold Lake to Anzac, west to Wandering River)  
**Publication:** Franceschini A., Hart T., Lebeuf-Taylor I., Bayne E. (2026). *Journal of Mammalogy*. [doi:10.1093/jmammal/gyag073](https://doi.org/10.1093/jmammal/gyag073)

## About the study

The study asks whether small mammals use seismic lines differently depending on how far the vegetation on the line has **recovered**, compared with the undisturbed forest interior.

**Sites.**
- Baited, ground-level camera traps (Reconyx PC900 and Hyperfire 2, with a ~25 cm focal length) were placed on **low-impact** and **conventional** seismic lines.
- Each line camera was paired with a **forest-interior control** 50 m into the adjacent forest (25 m for low-impact lines).
- Each camera ran for at least 3 nights.

**Recovery level.** Each line's recovery level was classified visually from field photos:

| Code in data | Recovery level | Description |
|---|---|---|
| `1` | Low | Minimal vegetation, mostly short grass |
| `2` | Medium | Taller forbs and grasses, possibly dense low shrubs or scattered tall shrubs and small trees |
| `3` | High | Dense medium–tall shrubs or a mix of short and tall trees; the line blends into the surrounding forest |
| `4` | Forest interior | Undisturbed control. This is the reference level in the models. |

**Response.** The number of **independent detections** per site, where detections of the same species at the same site less than 60 minutes apart count as one. A 15-minute threshold was used as a sensitivity check.

**Models.** For each taxon, a **negative binomial GLMM** (`glmmTMB`, NB1 or NB2 chosen from dispersion diagnostics) with:
- an offset of `log(active_hours)` for camera effort;
- a random intercept for the line–control pair (`pair_id`).

The global model includes `recovery`, `forest_cover`, `disturbance`, the interactions `forest_cover:recovery` and `disturbance:recovery`, and `day_year_zscore`. All subsets were ranked by AICc (`MuMIn::dredge`). From the models within ΔAICc ≤ 2, the most parsimonious one that includes `recovery` is reported. Contrasts between levels are Tukey-adjusted rate ratios (`emmeans`). Residuals were checked with `DHARMa`.

**Taxa modelled:** *Sorex* spp., southern red-backed vole (*Myodes gapperi*), deer mouse (*Peromyscus maniculatus*) and red squirrel (*Tamiasciurus hudsonicus*).

**Main findings.**
- Detections were generally lower on **low-recovery** lines than in the forest interior. Forest-interior detections were 2.95 times higher for *Sorex* spp. and 3.39 times higher for red-backed voles.
- Medium- and high-recovery lines mostly did not differ from the forest interior.
- Red-backed voles and red squirrels were detected more often on narrow low-impact lines than on conventional lines.
- Deer mouse detections varied with forest cover.

## Folder contents

```
Franceschini_seismic_line_recovery/
├── README.md
├── data/
│   ├── raw/
│   │   └── Line_site_metadata_2023.csv       ← field attributes for each seismic-line site
│   ├── processed/
│   │   └── Independent_Detections_60min.csv  ← independent detection events (60 min), line and forest sites
│   └── analysis/
│       ├── Data_60min.csv                    ← MAIN analysis dataset (one row per camera site)
│       └── Data_15min.csv                    ← same, with a 15-min independence threshold (sensitivity)
└── scripts/
    ├── data_preparation/                     ← Python and R scripts: WildTrax export → analysis datasets
    └── analysis/                             ← R scripts for the GLMMs, model selection, contrasts and figures
```

## Main dataset: `data/analysis/Data_60min.csv`

- **Size:** 282 camera sites × 25 columns. One row per site.
- **Sites:** 141 forest interior, 76 conventional seismic and 65 low-impact seismic. They form 141 line–control pairs.
- **Forest cover:** 92 Deciduous, 82 Mixedwood, 68 Lowland Spruce and 40 Upland Spruce.
- **Sites used in the models:** the analysis keeps the three ecosites in the paper (deciduous, mixedwood and lowland coniferous), so the 40 Upland Spruce sites are excluded. The deer mouse model also excludes Lowland Spruce sites, where the species was not detected.

| Column | Description | Units / values |
|---|---|---|
| `location` | Site ID. `SM-C` = conventional, `SM-N` = low-impact; `-L` = line, `-F` = forest interior. | text |
| `active_hours` | Hours the camera was active, from deployment to retrieval, or to the first bear image or last image before a malfunction. Used as the model offset. | h |
| `day_of_year`, `day_year_zscore` | Day of the year the camera was deployed, raw and as a z-score | 144–224 |
| `latitude`, `longitude` | Site coordinates | decimal degrees |
| `width`, `width_zscore` | Line width. 0 for forest interior. | m |
| `seismic_line_type` | Type of site | Forest interior, Conventional seismic, Low-impact seismic |
| `disturbance` | Disturbance type of the pair | `C` = conventional, `N` = low-impact |
| `forest_cover` | Ecosite | Deciduous, Mixedwood, Lowland Spruce, Upland Spruce |
| `recovery` | Recovery level (see the table above) | 1 = low (65 sites), 2 = medium (48), 3 = high (28), 4 = forest interior (141) |
| `pair_id`, `pair_key`, `num_id` | Pair identifiers. `pair_id` is the random effect. | |
| `sorex.spp`, `southern.red.backed.vole`, `deer.mouse`, `red.squirrel` | Independent detections (60 min) of the four modelled taxa | count |
| `black.bear`, `marten`, `meadow.vole`, `short.tailed.weasel`, `snowshoe.hare`, `western.jumping.mouse` | Independent detections of other species. Too few detections to model. | count |

`Data_15min.csv` has the same columns, with counts based on a 15-minute independence threshold.

## Other files

- **`data/processed/Independent_Detections_60min.csv`:** one row per independent detection event (11,129 rows). Columns:
  - `location`, `site_type` (line or forest interior), `latitude`, `longitude`, `equipment_serial`;
  - `image_date_time`, `species_scientific_name`, `species_common_name`, `individual_count`;
  - `start_datetime` (deployment) and `delta_time_hours` (hours since deployment).

  It includes `none`, `human` and `staff/setup` events, which are not used in the analysis. Summing the events per site and species reproduces the counts in `Data_60min.csv`. Forest-interior site names have been aligned with the analysis IDs (for example, WildTrax `SM-C-F-04` is `SM-C-F-03` here).
- **`data/raw/Line_site_metadata_2023.csv`:** one row per seismic-line site (137 rows), from the field form. It records deployment and retrieval dates and times, coordinates, line width, shape and cover, maximum tree height, human-use intensity, trail presence and width, vegetation regeneration status and structure, active restoration, forest cover, and standing water.

## Scripts

### `data_preparation/`
These scripts turn the WildTrax export into the analysis datasets. They run in roughly this order:
1. `Fix-554.py`, `Date_Correction.py`, `Data_filter_2023.py`, `ForestPointFilter2023.py`, `CreateL-FPairs.py`: fix site names and dates, select the 2023 sites, and build the line–control pairs.
2. `Delta_hours.py`, `add_delta_time_column.py`, `filter_first_hour.py`, `filter_15min_detections.py`, `filter_15min_independent.py`, `independent_filter_gui.py`: compute the time since deployment and apply the 60- and 15-minute independence filters.
3. `Merge_Detection_W_Table.py`, `Prepare data with julian date and active hours.R`, `AddJulianDate.py`, `ScaleJulian.py`: attach the site attributes, active hours and day of year.
4. `Prepare wide format.R`, `60minToWide.py`, `Subtract1fromName.py`, `Adjust_PoitStartNaming.py`: build the site × species tables and align the forest site names.
5. The `check*`, `Checking*` and `LocationCheckWide.py` scripts are consistency checks.

These scripts write the original column names (`julian_date`, `Succession_4`, `dusky.shrew`, …). In the shared datasets, those were renamed to match the paper.

### `analysis/`
| Script | Purpose |
|---|---|
| `01_Recovery GLMMs, model selection and figures.R` | Negative binomial GLMMs for each taxon, `dredge` model selection, the most parsimonious model, DHARMa diagnostics, `emmeans` contrasts and the figures |
| `02_Export model tables.R` | Exports the top-model and coefficient tables |
| `03_Combined recovery coefficients figure.R` | A combined coefficient plot of recovery effects for all taxa |

Change the absolute file paths in the scripts (for example `C:/Users/afran/Documents/...`) to the repository paths before running them.

## Species names

Species follow the paper. All shrews are pooled as *Sorex* spp. because they cannot be told apart reliably from photos. Weasels are *Mustela erminea* and meadow voles are *Microtus drummondii*, matching the identifications in the linear-feature-width study.

## Data availability

The raw camera-trap images, tags and locations are stored in **WildTrax** and are available from the lead author on request (afrances@ualberta.ca).

## Citation

Franceschini, A., Hart, T., Lebeuf-Taylor, I., and Bayne, E. 2026. Small mammal responses to vegetation recovery on seismic lines in Alberta's boreal forest. *Journal of Mammalogy*. https://doi.org/10.1093/jmammal/gyag073
