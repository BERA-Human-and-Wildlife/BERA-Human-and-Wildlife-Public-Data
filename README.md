# BERA Human and Wildlife Team – Data

This repository is the public catalogue of datasets from the **Human and Wildlife Team** of **BERA – Boreal Ecosystem Recovery and Assessment**. BERA studies how linear disturbances in Alberta's boreal forest, such as seismic lines, pipelines and powerlines, affect wildlife and human use, and how those disturbances recover.

Every dataset is described here, organised by thematic area. **Open** datasets are included in full. **On-request** datasets are described here, but their files are kept in a private repository and shared on approval (see [Requesting data](#requesting-data)).

## Datasets

| Thematic area | Project | Years | Access |
|---|---|---|---|
| [Human use](human_use/) | [OHV use on seismic lines](human_use/Saini_OHV_seismic_lines/) – Apoorv Saini | 2021–2024 | 🔒 On request (until published) |
| [Birds](birds/) | [Bird communities on linear features](birds/Kalukapuge_birds_linear_features/) – Tharindu Kalukapuge | 2021–2024 | 🔒 On request |
| [Small mammals](small_mammals/) | [Linear feature width and small mammal communities](small_mammals/Franceschini_linear_feature_width/) – Alessandro Franceschini | 2023 | ✅ **Open** – data, code and paper ([doi:10.1139/cjz-2025-0078](https://doi.org/10.1139/cjz-2025-0078)) |
| [Small mammals](small_mammals/) | [Seismic line regeneration and small mammals](small_mammals/Franceschini_seismic_line_restoration/) – Alessandro Franceschini | 2023–2024 | 🔒 On request (until published) |

## Repository structure

```
├── README.md                  ← this file
├── DATA_ACCESS.md             ← how to request on-request datasets
├── human_use/
│   └── Saini_OHV_seismic_lines/                  README only
├── birds/
│   └── Kalukapuge_birds_linear_features/         README only
└── small_mammals/
    ├── Franceschini_linear_feature_width/        README, docs/, data/, results/, scripts/, LICENSE
    └── Franceschini_seismic_line_restoration/    README only
```

Each project folder has a `README.md` that explains the study, how the data were collected, the files, and what each column means. In open projects, `data/analysis/` holds the model-ready datasets.

## Requesting data

Email **afrances@ualberta.ca** with:
- your name and affiliation;
- the dataset(s) you are requesting (use the folder path);
- a short description of how you plan to use the data.

Requests are forwarded to each dataset's owner for approval. See [DATA_ACCESS.md](DATA_ACCESS.md) for details.

## Licence and citation

- **Open datasets** are released under the licence given in their folder. The linear-feature-width data and code are under **CC BY 4.0**.
- **Please cite** the publication listed in each project's README, and acknowledge BERA – Boreal Ecosystem Recovery and Assessment.

## Contact

BERA Human and Wildlife Team, Department of Biological Sciences, University of Alberta. Email: afrances@ualberta.ca
