# Electric Vehicle Range Analysis

**Does drivetrain configuration (AWD vs. 2WD) moderate the relationship between
battery capacity and driving range, after controlling for vehicle size?**

A reproducible statistical analysis of 478 electric vehicles (2025 model year),
originally completed as a STAT 306 (Introduction to Statistical Inference for
Data Science) final project at UBC and refactored here into a clean, reproducible
portfolio project.

> The statistical methodology, model, and findings are **preserved exactly** from
> the original group project. This repository reorganizes the code and adds
> documentation and reproducibility checks; it does **not** change the analysis.

---

## Research question

As EVs become central to low-emission transport, "range anxiety" remains a key
consumer concern. Battery capacity is the most direct driver of range, but
drivetrain configuration may also matter: all-wheel-drive (AWD) vehicles are
generally heavier and mechanically more complex than two-wheel-drive (2WD)
vehicles, so they may convert stored energy into distance less efficiently.

We test whether drivetrain **moderates** the battery-capacity → range
relationship, controlling for vehicle length (a proxy for mass, since weight is
not in the dataset).

## Data

- **Source:** [Electric Vehicle Specs Dataset (2025)](https://www.kaggle.com/datasets/urvishahir/electric-vehicle-specifications-dataset-2025)
  by Urvish Ahir (Kaggle), scraped from [ev-database.org](https://ev-database.org).
- **License:** CC BY 4.0 — redistributed here **with attribution**. See
  [data/DATA_SOURCE.md](data/DATA_SOURCE.md).
- **Analysis variables:** `range_km` (response), `battery_capacity_kWh`
  (predictor), `drivetrain` (AWD vs. 2WD = FWD+RWD), `length_mm` (control).
- **Final cleaned sample:** 478 EVs (no missing values in the analysis variables;
  no duplicates).

## Methodology (summary)

All continuous variables are log-transformed (motivated by the physical
reasoning *mass ∝ length* and *range ∝ battery / length*), which makes the
interaction additive on the log scale and lets coefficients be read as
elasticities. Predictors were chosen by **best-subset selection** (Mallows' Cₚ
and adjusted R²); the battery × drivetrain **interaction** was then added because
it is central to the research question.

**Final model**

```
log(range) = β0 + β1·log(battery) + β2·drivetrain + β3·log(battery)·drivetrain
             + β4·log(length) + ε          (drivetrain: 0 = 2WD, 1 = AWD)
```

Full details, assumptions, and limitations: [docs/METHODOLOGY.md](docs/METHODOLOGY.md).

## Key results

| Quantity | Value |
|---|---|
| Observations | 478 (2WD: 287, AWD: 191) |
| log(battery) elasticity, 2WD | **+1.12%** range per +1% battery |
| log(battery) elasticity, AWD | **+1.00%** range per +1% battery |
| Interaction term (β3) | −0.12, **p = 0.041** (significant at α = 0.05) |
| log(length) coefficient | −1.15 (p < 2×10⁻¹⁶) |
| Multiple R² / Adjusted R² | 0.845 / **0.844** |
| Multicollinearity (GVIF) | 2.11 (all predictors; no concern) |

**Conclusion.** Battery capacity is a strong predictor of EV range, but drivetrain
configuration meaningfully moderates that relationship: after controlling for
length, 2WD vehicles gain more range per additional kWh than AWD vehicles. For a
typical 100 kWh / 4800 mm vehicle, the model implies ~29 km more range for the
2WD configuration than the AWD equivalent. These are **associational**,
cross-sectional findings, not causal claims.

## Figures

Generated into [`figures/`](figures/) by the analysis:

| File | Content |
|---|---|
| `fig0_boxplots_quant.png` | Boxplots of range, battery, length (outlier check) |
| `fig1_range_hist_by_drivetrain.png` | Distribution of range by drivetrain |
| `fig2_range_vs_battery.png` | Range vs. battery capacity |
| `fig3_range_vs_battery_by_drivetrain.png` | Range vs. battery by drivetrain |
| `fig4_range_vs_length.png` | Range vs. vehicle length |
| `fig5_battery_vs_length.png` | Battery capacity vs. vehicle length |
| `fig6_diagnostics.png` | Residuals, Q-Q, scale-location, leverage |
| `fig7_cooks_distance.png` | Cook's distance |

## Project structure

```
ev-range-analysis/
├── README.md
├── CONTRIBUTIONS.md          # group credits + individual contributions
├── LICENSE                   # code license (all rights reserved)
├── .gitignore
├── data/
│   ├── raw/
│   │   └── electric_vehicles_spec_2025.csv   # original Kaggle data (CC BY 4.0)
│   ├── processed/            # ev_clean_data.csv (generated)
│   └── DATA_SOURCE.md        # provenance, license, attribution
├── R/
│   ├── 00_setup.R            # packages, paths, validation helpers
│   ├── 01_clean_data.R       # cleaning + validation
│   ├── 02_eda.R              # summary tables + figures
│   ├── 03_model.R            # selection, final model, diagnostics
│   ├── 04_verify.R           # reproducibility checks vs. the report
│   ├── run_all.R             # runs the full pipeline
│   └── legacy/
│       └── R_Script_update_4_original.R   # original submitted script (unchanged)
├── figures/                  # generated plots
├── output/tables/            # generated summary/model tables (CSV)
├── report/
│   └── Final-Report.pdf       # authoritative final report
└── docs/
    └── METHODOLOGY.md
```

## Reproduce from scratch

### Requirements

- R ≥ 4.3
- R packages: `tidyverse`, `car`, `leaps`

### Install dependencies

```r
install.packages(c("tidyverse", "car", "leaps"))
```

Or, for a fully isolated environment without touching the system R (uses
[conda-forge](https://conda-forge.org) via `micromamba`/`conda`):

```bash
micromamba create -y -n ev -c conda-forge r-base=4.3 r-tidyverse r-car r-leaps
micromamba run -n ev Rscript R/run_all.R
```

### Run the whole analysis

```bash
# from the project root
Rscript R/run_all.R
```

This cleans the data, regenerates every figure and table, and finishes by
running `04_verify.R`, which checks the computed numbers against the values in
`report/Final-Report.pdf` and prints a PASS/FAIL table (exiting non-zero on any
failure). You can also run any step on its own, e.g. `Rscript R/03_model.R`
(each step re-reads the cleaned data, so run `01_clean_data.R` first).

### Reproducibility check

The last step reproduces this table (all 15 checks currently **PASS**):

```
                       check expected   actual status
              N observations      478      478   PASS
                   Intercept   10.930  10.9325   PASS
           log(battery) coef    1.120   1.1153   PASS
            interaction coef   -0.120  -0.1201   PASS
         interaction p-value    0.041   0.0409   PASS
          Adjusted R-squared    0.844   0.8439   PASS
          ... (15 total)                         PASS
```

## Attribution & license

- **Code & documentation:** © 2026 the project authors. All rights reserved
  (no reuse license granted — see [LICENSE](LICENSE)).
- **Dataset:** CC BY 4.0, Urvish Ahir / ev-database.org — see
  [data/DATA_SOURCE.md](data/DATA_SOURCE.md).
- **Authors & individual contributions:** see [CONTRIBUTIONS.md](CONTRIBUTIONS.md).
