# Electric Vehicle Range Analysis

[![reproduce](https://github.com/mrz82/ev-range-analysis/actions/workflows/ci.yml/badge.svg)](https://github.com/mrz82/ev-range-analysis/actions/workflows/ci.yml)

**Does drivetrain configuration (AWD vs. 2WD) moderate the relationship between
battery capacity and driving range, after controlling for vehicle size?**

A reproducible statistical analysis of 478 electric vehicles (2025 model year),
originally completed as a STAT 306 (Introduction to Statistical Inference for
Data Science) final project at UBC and refactored here into a clean, reproducible
portfolio project.

> The original model and reported numbers are **preserved exactly** (adjusted
> R² ≈ 0.844, interaction p = 0.041). This repository reorganizes the code and
> adds documentation, automated reproducibility checks, and a **robustness
> analysis**. The robustness analysis does **not** change the original estimates;
> it qualifies how strongly the drivetrain interaction can be claimed (see
> [Robustness](#robustness-of-the-interaction)).

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

| Quantity | Value | Robust? |
|---|---|---|
| Observations | 478 (2WD: 287, AWD: 191) | — |
| log(battery) coefficient | **+1.12** (elasticity), p < 10⁻¹⁴⁰ | ✅ highly robust |
| log(length) coefficient | **−1.15**, p < 10⁻²⁰ | ✅ highly robust |
| Multiple R² / Adjusted R² | 0.845 / **0.844** | ✅ stable |
| Multicollinearity (GVIF) | 2.11 (all predictors; no concern) | — |
| Interaction term (β₃) | −0.12, **nominal p = 0.041** | ⚠️ **not robust** (see below) |

**Conclusion.** Battery capacity and vehicle length are **strong, robust**
predictors of EV range on the log scale (together ≈ 84% of variance). The
project's headline question — whether drivetrain *moderates* the battery–range
relationship — is answered **"suggestive but not conclusive"**: the interaction
is significant under ordinary least squares (p = 0.041) but **loses significance
under heteroskedasticity-robust standard errors, after removing a single
influential vehicle, and in a three-level drivetrain specification** (details
below). Directionally, 2WD vehicles appear to gain slightly more range per
additional kWh than AWD vehicles, but the evidence is weak. All findings are
**associational and cross-sectional — not causal.**

## Robustness of the interaction

Because the diagnostics flagged mild heteroskedasticity and an influential
observation, `R/05_sensitivity.R` stress-tests the interaction. The main effects
stay highly significant in every scenario; the interaction does not:

| Scenario | Interaction p | Significant at 0.05? |
|---|---|---|
| OLS (as reported) | 0.041 | yes (barely) |
| HC3 heteroskedasticity-robust SE | **0.057** | no |
| Drop single most influential vehicle | **0.146** | no |
| Drop all Cook's D > 4/n (29 points) | 0.005 | yes (stronger) |
| Three-level FWD/RWD/AWD interaction | **0.312** | no |

The interaction's sign is stable but its significance is fragile — hence it is
reported as **suggestive**, not established. This is exactly why the sensitivity
analysis is run and published rather than hidden.

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
| `fig8_sensitivity_interaction.png` | Interaction p-value across robustness checks |

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
├── .github/workflows/ci.yml  # CI: reproduce + verify on every push
├── R/
│   ├── 00_setup.R            # packages, paths, validation helpers
│   ├── 01_clean_data.R       # cleaning + validation
│   ├── 02_eda.R              # summary tables + figures
│   ├── 03_model.R            # selection, final model, diagnostics
│   ├── 04_verify.R           # reproducibility checks vs. the report
│   ├── 05_sensitivity.R      # robustness: HC3 SE, influence, 3-level
│   ├── render_report.R       # renders the HTML report
│   ├── run_all.R             # runs the full pipeline (+ both gates)
│   └── legacy/
│       └── R_Script_update_4_original.R   # original submitted script (unchanged)
├── figures/                  # generated plots
├── output/tables/            # generated summary/model/robustness tables (CSV)
├── report/
│   ├── Final-Report.pdf       # authoritative original group report
│   ├── ev_range_report.Rmd    # self-contained reproducible report (source)
│   └── ev_range_report.html   # rendered report (generated)
└── docs/
    └── METHODOLOGY.md
```

## Reproduce from scratch

### Requirements

- R ≥ 4.3
- R packages: `tidyverse`, `car`, `leaps` (analysis); `rmarkdown`, `knitr` + a
  `pandoc` install (HTML report only)

### Install dependencies

```r
install.packages(c("tidyverse", "car", "leaps", "rmarkdown", "knitr"))
```

Or, for a fully isolated environment without touching the system R (uses
[conda-forge](https://conda-forge.org) via `micromamba`/`conda`):

```bash
micromamba create -y -n ev -c conda-forge \
  r-base=4.3 r-tidyverse r-car r-leaps r-rmarkdown r-knitr pandoc
micromamba run -n ev Rscript R/run_all.R
```

### Run the whole analysis

```bash
# from the project root (or from anywhere — the path is resolved automatically)
Rscript R/run_all.R
```

This cleans the data and regenerates every figure and table, then runs **two
verification gates** (each exits non-zero on any mismatch, so CI fails if results
drift):

1. `04_verify.R` — checks the core results (n, coefficients, adjusted R²,
   selection statistics) against the values in `report/Final-Report.pdf`.
2. `05_sensitivity.R` — reproduces the robustness numbers (HC3 p, influence-refit
   p, three-level p).

You can also run any step on its own, e.g. `Rscript R/03_model.R` (each step
re-reads the cleaned data, so run `01_clean_data.R` first). Scripts locate the
project root from their own location, so they work from any working directory.

### HTML report

```bash
Rscript R/run_all.R          # produce the data/figures/tables first
Rscript R/render_report.R    # -> report/ev_range_report.html (self-contained)
```

Open [`report/ev_range_report.html`](report/ev_range_report.html) — a polished,
standalone report with the research question, methodology, results, diagnostics,
and the robustness analysis. Continuous integration
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs the full pipeline
and both gates on every push and uploads the report as an artifact.

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
