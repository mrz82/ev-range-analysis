# ==============================================================================
# 03_model.R  --  Statistical analysis (log-transformed multiple regression)
# ==============================================================================
# Reproduces the model selection, final model, and diagnostics from the report.
#
# Physical reasoning (from the report): mass is proportional to length and range
# is proportional to battery / length, so all continuous variables are placed on
# a log scale. Coefficients are then read as elasticities (percentage change in
# range per 1% change in a predictor).
#
# Final model:
#   log(range) ~ log(battery) * drivetrain_binary + log(length)
# ==============================================================================

if (!exists("PROJECT_ROOT")) {
  .args  <- commandArgs(trailingOnly = FALSE)
  .f     <- sub("^--file=", "", .args[grepl("^--file=", .args)])
  .dir   <- if (length(.f) == 1 && nzchar(.f)) dirname(normalizePath(.f)) else getwd()
  .setup <- file.path(.dir, "00_setup.R")
  if (!file.exists(.setup)) stop("Cannot find 00_setup.R next to this script.",
                                 call. = FALSE)
  source(.setup)
}

message("\n=== 03_model.R ===")

if (!file.exists(CLEAN_DATA)) stop("Cleaned data not found. Run 01_clean_data.R first.",
                                   call. = FALSE)
ev <- read.csv(CLEAN_DATA, stringsAsFactors = FALSE) %>%
  mutate(drivetrain_binary = factor(drivetrain_binary, levels = c("2WD", "AWD")))

# ------------------------------------------------------------------------------
# Log transformation (guarded: logs require positive, non-missing values)
# ------------------------------------------------------------------------------
assert_positive(ev, c("range_km", "battery_capacity_kWh", "length_mm"))

ev_log <- ev %>%
  mutate(
    log_range   = log(range_km),
    log_battery = log(battery_capacity_kWh),
    log_length  = log(length_mm)
  )

# ------------------------------------------------------------------------------
# Model selection: best-subset on the additive log model
#   (Mallows' Cp and adjusted R^2)  -> Table 2 in the report
# ------------------------------------------------------------------------------
ev_log_additive <- ev_log %>%
  select(log_range, log_battery, drivetrain_binary, log_length)

subset_fit <- regsubsets(log_range ~ ., data = ev_log_additive,
                         method = "exhaustive")
subset_sum <- summary(subset_fit)

selection_table <- data.frame(
  model   = seq_len(nrow(subset_sum$which)),
  cp      = round(subset_sum$cp, 3),
  adj_r2  = round(subset_sum$adjr2, 4)
)
cat("\nTable 2 -- Best-subset selection (additive log model):\n")
print(subset_sum$which)
cat("\n")
print(selection_table)
write.csv(
  cbind(selection_table, as.data.frame(subset_sum$which)),
  file.path(TABLES_DIR, "table2_best_subset_selection.csv"), row.names = FALSE)

# ------------------------------------------------------------------------------
# Final fitted model (adds the battery x drivetrain interaction)
# ------------------------------------------------------------------------------
reg_log <- lm(log_range ~ log_battery * drivetrain_binary + log_length,
              data = ev_log)

model_sum <- summary(reg_log)
cat("\nFinal model summary:\n")
print(model_sum)

adj_r2  <- model_sum$adj.r.squared
mult_r2 <- model_sum$r.squared
cat(sprintf("\nMultiple R-squared: %.4f   Adjusted R-squared: %.4f\n",
            mult_r2, adj_r2))

# Tidy coefficient table -> CSV
coef_table <- as.data.frame(model_sum$coefficients)
coef_table <- cbind(term = rownames(coef_table), coef_table)
rownames(coef_table) <- NULL
write.csv(coef_table, file.path(TABLES_DIR, "model_coefficients.csv"),
          row.names = FALSE)

# ------------------------------------------------------------------------------
# Diagnostics: residuals, Q-Q, scale-location, residuals-vs-leverage
# ------------------------------------------------------------------------------
png(file.path(FIGURES_DIR, "fig6_diagnostics.png"),
    width = 900, height = 800, res = 120)
par(mfrow = c(2, 2))
plot(reg_log)
par(mfrow = c(1, 1))
dev.off()
message("Saved figure: ", file.path(FIGURES_DIR, "fig6_diagnostics.png"))

# ------------------------------------------------------------------------------
# Multicollinearity: predictor-based generalized VIF
# ------------------------------------------------------------------------------
vif_out <- vif(reg_log, type = "predictor")
cat("\nVariance Inflation Factors (GVIF, type = 'predictor'):\n")
print(vif_out)
write.csv(as.data.frame(vif_out),
          file.path(TABLES_DIR, "vif.csv"), row.names = TRUE)

# ------------------------------------------------------------------------------
# Influence: Cook's distance
# ------------------------------------------------------------------------------
png(file.path(FIGURES_DIR, "fig7_cooks_distance.png"),
    width = 900, height = 450, res = 120)
cooks <- cooks.distance(reg_log)
plot(cooks, type = "h", main = "Cook's Distance", ylab = "Cook's distance")
abline(h = 4 / nrow(ev_log), col = "red", lty = 2)
dev.off()
message("Saved figure: ", file.path(FIGURES_DIR, "fig7_cooks_distance.png"))

# ------------------------------------------------------------------------------
# Persist key results for the reproducibility checks in 04_verify.R
# ------------------------------------------------------------------------------
model_results <- list(
  n               = nrow(ev_log),
  n_2wd           = sum(ev_log$drivetrain_binary == "2WD"),
  n_awd           = sum(ev_log$drivetrain_binary == "AWD"),
  coefficients    = coef(reg_log),
  interaction_p   = model_sum$coefficients["log_battery:drivetrain_binaryAWD",
                                           "Pr(>|t|)"],
  adj_r2          = adj_r2,
  mult_r2         = mult_r2,
  selection_cp    = subset_sum$cp,
  selection_adjr2 = subset_sum$adjr2
)
saveRDS(model_results, file.path(TABLES_DIR, "model_results.rds"))

message("Modeling complete.")
