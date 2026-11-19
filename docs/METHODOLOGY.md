# Methodology

This document expands on the analysis summarized in the `README.md`. It mirrors
the methodology in `report/Final-Report.pdf`, which is the authoritative source.

## 1. Research question

> Does drivetrain configuration (AWD vs. 2WD) moderate the association between
> battery capacity and driving range, after controlling for vehicle size
> (length)?

Length is used as a proxy for mass because vehicle weight is not available in the
dataset. Length is a plausible **confounder**: it is associated with both battery
capacity (longer vehicles carry larger batteries) and range (heavier vehicles
consume more energy), so it must be controlled for.

## 2. Data cleaning and preparation

Starting from the raw dataset, we:

1. Selected the analysis variables (`range_km`, `battery_capacity_kWh`,
   `drivetrain`, `length_mm`) plus `brand`/`model` as identifiers.
2. Checked for missing values and empty strings. None of the four analysis
   variables had missing values, so no rows were dropped. One vehicle had a blank
   `model` name but complete analysis variables, so it was retained.
3. Recoded drivetrain: `AWD` stays `AWD`; `FWD` and `RWD` are collapsed into
   `2WD`. The original three-level factor is retained for exploratory comparison.
4. Checked for duplicate rows (none found).
5. Reviewed boxplots and summary statistics; all values were physically plausible
   for EVs, so no observations were removed as outliers.

Final cleaned sample: **478 EVs** (2WD: 287, AWD: 191).

### Input validation added in this repository

The refactored scripts add guards that were implicit before:

- required-column checks (`require_columns`),
- an explicit stop if any analysis variable contains missing values,
- a stop if any drivetrain value is outside `{FWD, RWD, AWD}`,
- `assert_positive()` before every log transformation, so a zero/negative/missing
  value can never silently produce `NaN`/`-Inf` in the regression.

These are safety checks only — on the provided data they all pass and change
nothing about the results.

## 3. Exploratory data analysis

- **Ranges observed:** driving range 135–685 km, battery 21.3–118.0 kWh, length
  3620–5908 mm — all plausible.
- **Three-group comparison (FWD / RWD / AWD):** FWD and RWD are *not*
  interchangeable — RWD vehicles have, on average, larger batteries (74.9 vs.
  55.5 kWh), longer bodies (4708 vs. 4453 mm), and longer range (418 vs. 298 km)
  than FWD vehicles. They were still combined into 2WD to keep the analysis
  focused on AWD vs. non-AWD; the limitation this introduces is acknowledged.
- **By binary drivetrain (Table 1):** AWD vehicles have higher mean range
  (454 vs. 353 km), larger mean battery (88.6 vs. 64.4 kWh), and greater mean
  length (4843 vs. 4569 mm) than 2WD vehicles, with less range variability
  (SD 68 vs. 103 km).
- **Scatterplots** show a strong positive battery–range association, a weaker/
  noisier length–range association, and a clear battery–length association
  (motivating length as a control). The battery–range slope differs visibly by
  drivetrain, motivating the interaction term.

## 4. Log transformation

From physical reasoning (*mass ∝ length*, *range ∝ battery / length*), all
continuous variables are placed on the log scale. This:

- turns the multiplicative battery/length relationship into an additive one on
  the log scale,
- yields coefficients interpretable as **elasticities** (percentage change in
  range per 1% change in a predictor), and
- (as the diagnostics confirm) stabilizes the variance relative to the raw scale.

## 5. Model selection

Best-subset selection (`leaps::regsubsets`, exhaustive) on the additive log model
was evaluated with Mallows' Cₚ and adjusted R²:

| | Model 1 | Model 2 | Model 3 |
|---|---|---|---|
| Predictors | log(battery) | + log(length) | + drivetrain |
| Mallows' Cₚ | 152.069 | 6.980 | 4.000 |
| Adjusted R² | 0.793 | 0.841 | 0.843 |

Model 3 (all three predictors) is the full additive model and has the best
adjusted R². The battery × drivetrain **interaction** was then added because it
directly addresses the research question; it raised adjusted R² from 0.843 to
0.844 and was statistically significant (p = 0.041).

## 6. Model specification

```
log(Y) = β0 + β1·log(x1) + β2·x2 + β3·log(x1)·x2 + β4·log(x3) + ε,   ε ~ N(0, σ²)
```

where `Y` = range (km), `x1` = battery capacity (kWh), `x2` = drivetrain
(0 = 2WD, 1 = AWD), `x3` = length (mm). This is equivalent to two regression
lines with different battery slopes:

- **2WD:** `log(Y) = β0 + β1·log(x1) + β4·log(x3)`
- **AWD:** `log(Y) = (β0+β2) + (β1+β3)·log(x1) + β4·log(x3)`

**Hypothesis test** (the inferential core of the project):

> H0: β3 = 0 (battery effect is the same for AWD and 2WD)
> H1: β3 ≠ 0, at α = 0.05.

## 7. Results

Fitted model:

```
log(Y) = 10.93 + 1.12·log(x1) + 0.50·x2 − 0.12·log(x1)·x2 − 1.15·log(x3)
```

- **Interaction** β3 = −0.12, **p = 0.041 < 0.05** → reject H0. Drivetrain
  changes the battery–range relationship even after controlling for length.
- **Battery elasticity:** +1.12% range per +1% battery for 2WD; +1.00% for AWD.
- **Length:** −1.15 (p < 2×10⁻¹⁶). The sign flips from the positive *unadjusted*
  EDA relationship — a classic confounding/reversal: once battery is held fixed,
  extra length reflects added mass and energy use, reducing range.
- **Drivetrain main effect (0.50):** interpreted cautiously — in an interaction
  model it is the group difference at battery = 1 kWh, which is not a meaningful
  configuration.
- **Fit:** Multiple R² = 0.845, Adjusted R² = 0.844 (~84% of the variation in
  log range explained).
- **Practical magnitude:** at 100 kWh and 4800 mm, the model implies ~29 km more
  range for a 2WD vehicle than its AWD equivalent.

## 8. Assumptions and diagnostics

Assessed via the standard four diagnostic plots, GVIF, and Cook's distance:

- **Linearity (residuals vs. fitted):** no strong curvature — reasonable on the
  log scale.
- **Normality (Q-Q):** residuals follow the reference line in the center with
  visible tail deviations — only approximately normal. With n = 478 this is not a
  serious concern but is acknowledged.
- **Constant variance (scale-location):** fairly flat; the log transformation
  reduced the non-constant variance seen on the raw scale, though some remains.
- **Influence (leverage + Cook's distance):** a few points have higher influence
  and one observation stands out, but conclusions are not driven by one or two
  cases.
- **Multicollinearity (GVIF):** 2.11 for all predictors (GVIF^(1/(2·Df)) = 1.13,
  1.13, 1.45) — well below conventional thresholds.

Overall the assumptions are **partially satisfied**. The main-effect pattern
(battery ↑, length ↓) is robust, but the **mild heteroskedasticity and the
influential observation flagged here directly motivate the sensitivity analysis
in Section 9** — and that analysis shows the interaction term is *not* robust.

## 9. Robustness / sensitivity analysis

Because the OLS interaction p-value (0.041) sits just below 0.05 while the
diagnostics flag mild non-constant variance and an influential point,
`R/05_sensitivity.R` re-estimates the interaction four ways. The main effects
stay highly significant throughout; the interaction does not:

| Scenario | Interaction p | Significant at 0.05? |
|---|---|---|
| OLS (as reported) | 0.041 | yes (barely) |
| HC3 heteroskedasticity-consistent SE | 0.057 | no |
| Drop single most influential vehicle (max Cook's D) | 0.146 | no |
| Drop all Cook's D > 4/n (29 points) | 0.005 | yes (stronger) |
| Three-level FWD/RWD/AWD interaction (Type II F-test) | 0.312 | no |

**Interpretation.** The interaction's *sign* is stable (2WD has the steeper
battery slope), but its *statistical significance* is fragile: it disappears
under robust standard errors, under removal of one influential vehicle, and when
drivetrain is not collapsed to a binary. It is therefore reported as
**suggestive, not established**. The removal of 29 moderate-influence points
*strengthens* it, confirming the estimate is sensitive to influential-point
handling in both directions. The core finding that survives every check is that
**battery capacity and vehicle length are strong, robust predictors of range**
(adjusted R² ≈ 0.84); the moderating role of drivetrain is a weaker, secondary
signal.

## 10. Limitations

- The dataset does not specify the range testing standard (WLTP/EPA/CLTC), which
  can introduce inconsistency across brands.
- Vehicle **weight** is unavailable; length is used as a proxy.
- Collapsing **FWD and RWD into 2WD** obscures real differences between them
  (see the three-group EDA).
- The analysis is **cross-sectional**, so results are **associational, not
  causal**.

Future work: standardized range data, including weight, and modeling FWD and RWD
separately.
