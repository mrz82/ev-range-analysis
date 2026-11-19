# ==============================================================================
# run_all.R  --  Reproduce the entire analysis from a clean session
# ==============================================================================
# Usage (from the project root):
#   Rscript R/run_all.R
#
# Runs, in order:
#   00_setup.R      shared setup (packages, paths, helpers)
#   01_clean_data.R raw -> cleaned dataset
#   02_eda.R        summary tables + figures
#   03_model.R      model selection, final model, diagnostics
#   04_verify.R     reproducibility checks against the final report
# ==============================================================================

# Resolve the R/ script directory regardless of the working directory.
.script_dir <- local({
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", args[grep("^--file=", args)])
  if (length(f) == 1) return(dirname(normalizePath(f)))
  for (cand in c("R", ".")) if (file.exists(file.path(cand, "00_setup.R"))) return(cand)
  stop("Cannot locate the R/ script directory.", call. = FALSE)
})

step <- function(f) {
  message("\n", strrep("=", 78), "\n>>> ", f, "\n", strrep("=", 78))
  source(file.path(.script_dir, f))
}

# Tell 00_setup.R exactly where the scripts live, so project-root detection is
# independent of the working directory even when sourced (not run via --file).
.ev_script_dir <- .script_dir
source(file.path(.script_dir, "00_setup.R"))  # defines PROJECT_ROOT, paths, helpers
step("01_clean_data.R")
step("02_eda.R")
step("03_model.R")
step("04_verify.R")       # gate: core results must match the report
step("05_sensitivity.R")  # robustness/sensitivity of the interaction

message("\n", strrep("=", 78),
        "\nAll steps complete. See figures/ and output/tables/ for results.\n",
        strrep("=", 78))
