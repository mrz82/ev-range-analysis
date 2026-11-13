# ==============================================================================
# 04_verify.R  --  Lightweight reproducibility checks
# ==============================================================================
# Compares the values computed by 03_model.R against the figures reported in the
# final PDF report (report/Final-Report.pdf). The "expected" column below is
# transcribed from the report -- these are NOT re-derived here, they are the
# published targets the reproduction must hit. Small tolerances absorb rounding.
#
# Exit status is non-zero if any check fails, so this doubles as a CI-style gate.
# ==============================================================================

if (!exists("PROJECT_ROOT")) {
  .cand <- c("R/00_setup.R", "00_setup.R", file.path("..", "R", "00_setup.R"))
  .hit  <- .cand[file.exists(.cand)][1]
  if (is.na(.hit)) stop("Cannot find 00_setup.R; run from the project root.",
                        call. = FALSE)
  source(.hit)
}

message("\n=== 04_verify.R : reproducibility checks vs. the final report ===")

rds <- file.path(TABLES_DIR, "model_results.rds")
if (!file.exists(rds)) stop("model_results.rds not found. Run 03_model.R first.",
                            call. = FALSE)
r <- readRDS(rds)

cf <- r$coefficients
checks <- tibble::tribble(
  ~check,                               ~expected, ~actual,                                          ~tol,
  "N observations",                     478,       r$n,                                              0,
  "N 2WD",                              287,       r$n_2wd,                                          0,
  "N AWD",                              191,       r$n_awd,                                          0,
  "Intercept",                          10.93,     unname(cf["(Intercept)"]),                        0.01,
  "log(battery) coef",                  1.12,      unname(cf["log_battery"]),                        0.01,
  "drivetrain AWD coef",                0.50,      unname(cf["drivetrain_binaryAWD"]),               0.01,
  "log(length) coef",                   -1.15,     unname(cf["log_length"]),                         0.01,
  "interaction coef",                   -0.12,     unname(cf["log_battery:drivetrain_binaryAWD"]),   0.01,
  "interaction p-value",                0.041,     r$interaction_p,                                  0.001,
  "Adjusted R-squared",                 0.844,     r$adj_r2,                                         0.001,
  "Multiple R-squared",                 0.845,     r$mult_r2,                                        0.001,
  "Best-subset Cp (model 1)",           152.069,   r$selection_cp[1],                                0.01,
  "Best-subset Cp (model 2)",           6.980,     r$selection_cp[2],                                0.01,
  "Best-subset Cp (model 3)",           4.000,     r$selection_cp[3],                                0.01,
  "Best-subset adjR2 (model 3)",        0.843,     r$selection_adjr2[3],                             0.001
)

checks <- checks %>%
  mutate(
    actual = round(actual, 4),
    status = ifelse(abs(actual - expected) <= tol, "PASS", "FAIL")
  )

cat("\n")
print(as.data.frame(checks[c("check", "expected", "actual", "status")]),
      row.names = FALSE)

n_fail <- sum(checks$status == "FAIL")
cat("\n")
if (n_fail == 0) {
  message("ALL ", nrow(checks), " CHECKS PASSED -- results match the final report.")
} else {
  message(n_fail, " CHECK(S) FAILED -- investigate before trusting the output.")
  # Non-zero exit so automated runs surface the failure.
  if (!interactive()) quit(status = 1, save = "no")
}
