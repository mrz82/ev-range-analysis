# Data source, license, and attribution

## Dataset

**Electric Vehicle Specs Dataset (2025)**

- **Author / publisher:** Urvish Ahir
- **Hosted on:** Kaggle —
  <https://www.kaggle.com/datasets/urvishahir/electric-vehicle-specifications-dataset-2025>
  (also mirrored on Hugging Face:
  <https://huggingface.co/datasets/UrvishAhir1/Electric-Vehicle-Specs-Dataset-2025>)
- **Original data source:** scraped from <https://ev-database.org> (see the
  `source_url` column in the raw CSV, e.g.
  `https://ev-database.org/car/1904/Abarth-500e-Convertible`).
- **File in this repo:** `data/raw/electric_vehicles_spec_2025.csv`
  (478 vehicles × 22 columns).

## License

The dataset is released under the **Creative Commons Attribution 4.0
International (CC BY 4.0)** license:
<https://creativecommons.org/licenses/by/4.0/>

CC BY 4.0 permits sharing and adaptation (including redistribution in this
repository) **provided appropriate attribution is given**. Attribution is
provided above and in the project `README.md`. No changes have been made to the
raw data file; cleaning is performed non-destructively by the R scripts, which
write a separate `data/processed/ev_clean_data.csv`.

> Note: the underlying specifications originate from ev-database.org. This
> redistribution relies on the CC BY 4.0 license attached to the Kaggle dataset.
> If you intend to reuse the data beyond academic/portfolio purposes, review
> ev-database.org's own terms of use as well.

## How to obtain the data (if not present)

If `data/raw/electric_vehicles_spec_2025.csv` is missing, download it from the
Kaggle link above (free Kaggle account required) and place it at that path. The
analysis scripts expect exactly that filename and location.

## Variables used in the analysis

| Column | Role | Description |
|---|---|---|
| `range_km` | response | Driving range on a full charge (km) |
| `battery_capacity_kWh` | predictor | Usable battery capacity (kWh) |
| `drivetrain` | predictor | AWD, FWD, or RWD (FWD+RWD recoded to 2WD) |
| `length_mm` | control | Vehicle length (mm), proxy for mass |
| `brand`, `model` | identifiers | Retained only to trace observations |

The dataset does **not** specify the range testing standard (WLTP / EPA / CLTC),
which is noted as a limitation in the report.
