# ==============================================================================
# 01_clean_data.R  --  Data cleaning and preparation
# ==============================================================================
# Reads the raw Electric Vehicle Specs (2025) dataset, selects the variables
# relevant to the research question, validates them, recodes drivetrain, and
# writes a cleaned dataset to data/processed/ev_clean_data.csv.
#
# The cleaned data keeps BOTH the original 3-level drivetrain (FWD/RWD/AWD) for
# exploratory analysis and the binary recode (2WD/AWD) used in the final model.
# ==============================================================================

# Source shared setup unless it has already been loaded (e.g. by run_all.R).
if (!exists("PROJECT_ROOT")) {
  .cand <- c("R/00_setup.R", "00_setup.R",
             file.path("..", "R", "00_setup.R"))
  .hit  <- .cand[file.exists(.cand)][1]
  if (is.na(.hit)) stop("Cannot find 00_setup.R; run from the project root.",
                        call. = FALSE)
  source(.hit)
}

message("\n=== 01_clean_data.R ===")

# ------------------------------------------------------------------------------
# Load raw data
# ------------------------------------------------------------------------------
if (!file.exists(RAW_DATA)) {
  stop("Raw data not found at: ", RAW_DATA,
       "\nSee data/DATA_SOURCE.md for how to obtain it.", call. = FALSE)
}
raw <- read.csv(RAW_DATA, stringsAsFactors = FALSE)
cat("Raw dataset dimensions:", nrow(raw), "rows x", ncol(raw), "columns\n")

# ------------------------------------------------------------------------------
# Select variables relevant to the research question
#   response : range_km
#   predictor: battery_capacity_kWh
#   category : drivetrain
#   control  : length_mm
#   id       : brand, model (kept to trace back unusual observations)
# ------------------------------------------------------------------------------
key_vars <- c("brand", "model", "range_km", "battery_capacity_kWh",
              "drivetrain", "length_mm")
require_columns(raw, key_vars)

ev_data <- raw %>% select(all_of(key_vars))
cat("Selected subset dimensions:", nrow(ev_data), "rows x",
    ncol(ev_data), "columns\n\n")

# ------------------------------------------------------------------------------
# Missing-value / empty-string audit (reported, not silently dropped)
# ------------------------------------------------------------------------------
analysis_vars <- c("range_km", "battery_capacity_kWh", "drivetrain", "length_mm")
report_missing(ev_data, key_vars)

# One vehicle has a blank model name; all analysis variables are present for it,
# so it is retained (consistent with the final report).
blank_model <- ev_data %>% filter(model == "")
cat("\nRows with a blank model name (retained -- analysis vars present):\n")
print(blank_model)

# The four analysis variables must have no missing values for the model to run.
na_in_analysis <- colSums(is.na(ev_data[analysis_vars]))
if (any(na_in_analysis > 0)) {
  stop("Missing values present in analysis variables: ",
       paste(names(na_in_analysis)[na_in_analysis > 0], collapse = ", "),
       call. = FALSE)
}

# ------------------------------------------------------------------------------
# Recode drivetrain: AWD stays AWD; FWD and RWD collapse into 2WD.
# Keep the original 3-level factor too, for the EDA comparison.
# ------------------------------------------------------------------------------
ev_data <- ev_data %>%
  mutate(
    drivetrain        = factor(drivetrain, levels = c("FWD", "RWD", "AWD")),
    drivetrain_binary = factor(ifelse(drivetrain == "AWD", "AWD", "2WD"),
                               levels = c("2WD", "AWD"))
  )

# Any drivetrain value outside FWD/RWD/AWD becomes NA above -- catch that.
if (any(is.na(ev_data$drivetrain))) {
  stop("Unexpected drivetrain category found (not FWD/RWD/AWD).", call. = FALSE)
}

cat("\nOriginal drivetrain counts (FWD/RWD/AWD):\n")
print(table(ev_data$drivetrain))
cat("\nRecoded drivetrain counts (2WD/AWD):\n")
print(table(ev_data$drivetrain_binary))

# ------------------------------------------------------------------------------
# Duplicate check
# ------------------------------------------------------------------------------
n_duplicate <- sum(duplicated(ev_data))
cat("\nNumber of duplicated rows:", n_duplicate, "\n")

# ------------------------------------------------------------------------------
# Final cleaned dataset
# ------------------------------------------------------------------------------
ev <- ev_data %>%
  select(brand, model, range_km, battery_capacity_kWh,
         drivetrain, drivetrain_binary, length_mm)

cat("\nFinal cleaned dataset:", nrow(ev), "rows x", ncol(ev), "columns\n")
str(ev)

write.csv(ev, CLEAN_DATA, row.names = FALSE)
message("\nWrote cleaned data: ", CLEAN_DATA)
