# ==============================================================================
# 05_sensitivity.R  --  Robustness / sensitivity analysis of the interaction
# ==============================================================================
# The OLS model reports a battery x drivetrain interaction with p = 0.041 -- just
# under 0.05. Because the report's own diagnostics note mild heteroskedasticity
# and an influential observation, this script formally tests how fragile that
# interaction is. The MAIN EFFECTS (battery, length) are expected to stay highly
# significant throughout; the INTERACTION is the term under scrutiny.
#
# Checks:
#   1. Heteroskedasticity-consistent (HC3) robust standard errors
#   2. Refit excluding the single most influential point (max Cook's distance)
#   3. Refit excluding all points with Cook's distance > 4/n
#   4. Three-level drivetrain (FWD/RWD/AWD) interaction, without collapsing to 2WD
#
# Outputs: output/tables/sensitivity_interaction.csv and a summary figure.
# This script makes NO claim beyond what the numbers show, and exits non-zero if
# the reproduced robustness numbers drift from the documented values.
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

message("\n=== 05_sensitivity.R ===")

if (!file.exists(CLEAN_DATA)) stop("Cleaned data not found. Run 01_clean_data.R first.",
                                   call. = FALSE)
ev <- read.csv(CLEAN_DATA, stringsAsFactors = FALSE) %>%
  mutate(
    drivetrain        = factor(drivetrain, levels = c("FWD", "RWD", "AWD")),
    drivetrain_binary = factor(drivetrain_binary, levels = c("2WD", "AWD"))
  )
assert_positive(ev, c("range_km", "battery_capacity_kWh", "length_mm"))
ev <- ev %>% mutate(
  log_range   = log(range_km),
  log_battery = log(battery_capacity_kWh),
  log_length  = log(length_mm)
)

n       <- nrow(ev)
ix      <- "log_battery:drivetrain_binaryAWD"      # the interaction coefficient
reg_log <- lm(log_range ~ log_battery * drivetrain_binary + log_length, data = ev)
ols     <- summary(reg_log)$coefficients
ols_p   <- ols[ix, "Pr(>|t|)"]

# --- Helper: pull the interaction coefficient + p from an lm fit ----------------
int_row <- function(fit, label, p_override = NULL) {
  co <- summary(fit)$coefficients
  data.frame(
    scenario    = label,
    interaction = round(unname(co[ix, "Estimate"]), 4),
    std_error   = round(unname(co[ix, "Std. Error"]), 4),
    p_value     = round(if (is.null(p_override)) co[ix, "Pr(>|t|)"] else p_override, 4),
    adj_r2      = round(summary(fit)$adj.r.squared, 4),
    row.names   = NULL
  )
}

# --- 1. HC3 heteroskedasticity-consistent standard errors -----------------------
V_hc3  <- car::hccm(reg_log, type = "hc3")
se_hc3 <- sqrt(diag(V_hc3))
t_hc3  <- coef(reg_log) / se_hc3
p_hc3  <- 2 * pt(-abs(t_hc3), df.residual(reg_log))
hc3_row <- data.frame(
  scenario    = "HC3 robust SE (same fit)",
  interaction = round(unname(coef(reg_log)[ix]), 4),
  std_error   = round(unname(se_hc3[ix]), 4),
  p_value     = round(unname(p_hc3[ix]), 4),
  adj_r2      = round(summary(reg_log)$adj.r.squared, 4),
  row.names   = NULL
)

# --- 2 & 3. Influential-observation refits --------------------------------------
cooks   <- cooks.distance(reg_log)
drop_1  <- which.max(cooks)
thr     <- 4 / n
drop_k  <- which(cooks > thr)

fit_no1 <- lm(log_range ~ log_battery * drivetrain_binary + log_length,
              data = ev[-drop_1, ])
fit_nok <- lm(log_range ~ log_battery * drivetrain_binary + log_length,
              data = ev[-drop_k, ])

# --- 4. Three-level drivetrain interaction (no FWD/RWD collapse) -----------------
fit_3lvl <- lm(log_range ~ log_battery * drivetrain + log_length, data = ev)
anova_3  <- car::Anova(fit_3lvl, type = 2)
p_3lvl   <- anova_3["log_battery:drivetrain", "Pr(>F)"]

# --- Assemble the sensitivity table ---------------------------------------------
sens <- rbind(
  int_row(reg_log, "OLS (reported)"),
  hc3_row,
  int_row(fit_no1, sprintf("Drop most influential point (1 of %d)", n)),
  int_row(fit_nok, sprintf("Drop Cook's D > 4/n (%d points)", length(drop_k))),
  data.frame(scenario = "3-level drivetrain interaction (Type II F-test)",
             interaction = NA, std_error = NA, p_value = round(p_3lvl, 4),
             adj_r2 = round(summary(fit_3lvl)$adj.r.squared, 4), row.names = NULL)
)
sens$significant_05 <- ifelse(sens$p_value < 0.05, "yes", "no")

cat("\nSensitivity of the battery x drivetrain interaction:\n")
print(sens, row.names = FALSE)
write.csv(sens, file.path(TABLES_DIR, "sensitivity_interaction.csv"),
          row.names = FALSE)

cat(sprintf(
  "\nInterpretation: the interaction is significant under OLS (p=%.3f) but NOT under\nHC3 robust SE (p=%.3f), NOT after dropping the single most influential vehicle\n(p=%.3f), and NOT in the 3-level drivetrain specification (p=%.3f). It is therefore\nSUGGESTIVE, not robust. The main effects remain highly significant throughout.\n",
  ols_p, p_hc3[ix], summary(fit_no1)$coefficients[ix, "Pr(>|t|)"], p_3lvl))

# --- Figure: interaction p-value across scenarios (reference line at 0.05) -------
plot_df <- sens[!is.na(sens$p_value), c("scenario", "p_value")]
plot_df$scenario <- factor(plot_df$scenario, levels = rev(plot_df$scenario))
fig <- ggplot(plot_df, aes(x = p_value, y = scenario)) +
  geom_col(aes(fill = p_value < 0.05), width = 0.6) +
  geom_vline(xintercept = 0.05, linetype = "dashed") +
  scale_fill_manual(values = c(`TRUE` = "#4C9F70", `FALSE` = "#C0504D"),
                    labels = c(`TRUE` = "p < 0.05", `FALSE` = "p >= 0.05"),
                    name = NULL) +
  labs(title = "Interaction p-value is fragile across robustness checks",
       subtitle = "Dashed line = 0.05 significance threshold",
       x = "p-value for battery x drivetrain interaction", y = NULL) +
  theme_minimal()
save_fig(fig, "fig8_sensitivity_interaction.png", width = 8, height = 4)

# --- Reproducibility assertions (documented robustness numbers) -----------------
expect <- function(name, value, target, tol) {
  ok <- abs(value - target) <= tol
  cat(sprintf("  [%s] %-45s actual=%.4f expected=%.4f\n",
              ifelse(ok, "PASS", "FAIL"), name, value, target))
  ok
}
cat("\nRobustness reproducibility checks:\n")
results <- c(
  expect("Interaction OLS p-value",        ols_p,                                 0.0409, 0.001),
  expect("Interaction HC3 robust p-value",  unname(p_hc3[ix]),                     0.0571, 0.002),
  expect("Interaction p (drop top-1)",      summary(fit_no1)$coefficients[ix,"Pr(>|t|)"], 0.1462, 0.002),
  expect("3-level interaction p (Type II)", p_3lvl,                                0.3117, 0.002)
)
if (all(results)) {
  message("\nAll ", length(results), " robustness checks reproduced.")
} else {
  message("\n", sum(!results), " robustness check(s) drifted -- investigate.")
  if (!interactive()) quit(status = 1, save = "no")
}
