# Birds

This thematic area covers how bird communities respond to linear disturbances in the boreal forest, such as seismic lines, pipelines, transmission lines and roads, and to the recovery of those disturbances.

> 🔒 The bird data are **available on request** only. See [DATA_ACCESS.md](../DATA_ACCESS.md).

## Projects

| Project | Lead | Years | Summary |
|---|---|---|---|
| [`Kalukapuge_birds_linear_features/`](Kalukapuge_birds_linear_features/) | Tharindu Kalukapuge (Bayne Lab) | 2021–2024 | Songbird abundance from ARU and mobile surveys on linear features across Alberta. The data are linked to line width (boreal subset), human footprint within 500 m and wetland cover within 300 m. |

## Folder structure

```
birds/
├── README.md                                   ← this file
└── Kalukapuge_birds_linear_features/
    ├── README.md                               ← project description and how the files link
    ├── data/
    │   ├── ..._Species_Abundance_Matrix_...csv  ← 3,358 sites × 124 species
    │   ├── ..._BorealNaturalRegion_Width_...csv ← 736 boreal sites: line type, width, 69 species
    │   ├── ..._Footprint_Data_...csv            ← footprint area by type, 500 m buffer
    │   └── ..._Wetland_Data_...csv              ← wetland class areas, 300 m buffer
    └── metadata/
        ├── original_column_description.txt
        └── species_codes.csv
```

See each project's `README.md` for details on the data.
