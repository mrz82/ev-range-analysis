# ==============================================================================
# 00_setup.R  --  Shared setup: packages, project paths, and validation helpers
# ==============================================================================
# Sourced by every analysis script. Loads the required packages, locates the
# project root (so scripts work regardless of the current working directory),
# and defines small helper functions used for input validation.
#
# STAT 306 Final Project -- Electric Vehicle Range Analysis
# Authors: Mahour Rezvani, Markus Rosario, Desiree Ng, Doa Binte Rashid
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)   # dplyr, ggplot2, readr, tidyr, ...
  library(car)         # vif()
  library(leaps)       # regsubsets()  -- best-subset selection
})

# ------------------------------------------------------------------------------
# Locate the project root by walking up from the working directory until the
# raw data file is found. This lets the scripts be run from the project root,
# from R/, or sourced from run_all.R without editing any hard-coded paths.
# ------------------------------------------------------------------------------
find_project_root <- function(start  = getwd(),
                              marker = file.path("data", "raw",
                                                 "electric_vehicles_spec_2025.csv")) {
  dir <- normalizePath(start, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(dir, marker))) return(dir)
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      stop("Could not locate the project root (looked for '", marker, "').\n",
           "Run the scripts from inside the project directory.", call. = FALSE)
    }
    dir <- parent
  }
}

PROJECT_ROOT  <- find_project_root()

# Standard project paths (all relative to the located root -- no machine paths)
RAW_DATA      <- file.path(PROJECT_ROOT, "data", "raw",
                           "electric_vehicles_spec_2025.csv")
PROCESSED_DIR <- file.path(PROJECT_ROOT, "data", "processed")
CLEAN_DATA    <- file.path(PROCESSED_DIR, "ev_clean_data.csv")
FIGURES_DIR   <- file.path(PROJECT_ROOT, "figures")
TABLES_DIR    <- file.path(PROJECT_ROOT, "output", "tables")

for (d in c(PROCESSED_DIR, FIGURES_DIR, TABLES_DIR)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# ------------------------------------------------------------------------------
# Validation helpers
# ------------------------------------------------------------------------------

# Stop early with a clear message if any expected column is missing.
require_columns <- function(df, cols) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    stop("Missing required column(s): ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  invisible(df)
}

# Report (do not silently drop) missing values and empty strings per column.
report_missing <- function(df, cols = names(df)) {
  na_counts    <- colSums(is.na(df[cols]))
  empty_counts <- sapply(df[cols], function(x)
    if (is.character(x)) sum(x == "", na.rm = TRUE) else 0L)
  cat("Missing values (NA) per column:\n");  print(na_counts)
  cat("\nEmpty strings per column:\n");        print(empty_counts)
  invisible(list(na = na_counts, empty = empty_counts))
}

# Guard the log transformation: logarithms are only defined for positive,
# non-missing values. Stop before transforming if that is violated, so we never
# silently produce NaN/-Inf that would corrupt the regression.
assert_positive <- function(df, cols) {
  for (col in cols) {
    x <- df[[col]]
    n_na  <- sum(is.na(x))
    n_bad <- sum(x <= 0, na.rm = TRUE)
    if (n_na > 0 || n_bad > 0) {
      stop(sprintf(
        "Column '%s' is not safe for log transformation: %d missing and %d non-positive value(s).",
        col, n_na, n_bad), call. = FALSE)
    }
  }
  invisible(TRUE)
}

# Save a ggplot to figures/ with consistent dimensions.
save_fig <- function(plot, file, width = 7, height = 5, dpi = 150) {
  path <- file.path(FIGURES_DIR, file)
  ggsave(path, plot = plot, width = width, height = height, dpi = dpi)
  message("Saved figure: ", path)
  invisible(path)
}
