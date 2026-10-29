# Small Mammals

This thematic area covers how small-mammal communities respond to linear disturbances in the boreal forest, such as seismic lines, pipelines and transmission lines, and to the recovery of those disturbances. Both projects use baited camera traps placed in line–forest interior pairs.

| Project | Access |
|---|---|
| Linear feature width | ✅ **Open.** Data and code are included (CC BY 4.0). |
| Vegetation recovery on seismic lines | ✅ **Open.** Data and code are included (CC BY-NC 4.0). |

## Projects

| Project | Lead | Years | Summary |
|---|---|---|---|
| [`Franceschini_linear_feature_width/`](Franceschini_linear_feature_width/) | Alessandro Franceschini (Bayne Lab) | 2023 | How linear feature width (3–150 m) affects habitat use by 9 species (binomial GLMMs) and community composition (RDA). Published: *Can. J. Zool.* 2025, [doi:10.1139/cjz-2025-0078](https://doi.org/10.1139/cjz-2025-0078). |
| [`Franceschini_seismic_line_recovery/`](Franceschini_seismic_line_recovery/) | Alessandro Franceschini (Bayne Lab) | 2023 | How vegetation recovery on seismic lines (low, medium, high vs forest interior) affects detections of *Sorex* spp., red-backed vole, deer mouse and red squirrel (negative binomial GLMMs). Published: *J. Mammal.* 2026, [doi:10.1093/jmammal/gyag073](https://doi.org/10.1093/jmammal/gyag073). |

## Folder structure

```
small_mammals/
├── README.md
├── Franceschini_linear_feature_width/
│   ├── README.md
│   ├── docs/      the published paper
│   ├── data/      raw/ · processed/ · analysis/
│   ├── results/   Tables S1–S2 (GLMM coefficients, AIC comparisons)
│   └── scripts/   numbered R pipeline + species_models/
└── Franceschini_seismic_line_recovery/
    ├── README.md
    ├── data/      raw/ · processed/ · analysis/
    └── scripts/   data_preparation/ (Python + R) · analysis/ (R)
```

In both projects, `data/analysis/` holds the datasets the models actually use. Start there.
