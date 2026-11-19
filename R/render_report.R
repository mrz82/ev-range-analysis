# ==============================================================================
# render_report.R  --  Render the self-contained HTML report
# ==============================================================================
# Usage: Rscript R/render_report.R
# Produces report/ev_range_report.html (standalone; embeds all figures).
# Requires: rmarkdown, knitr, and a pandoc installation.
# ==============================================================================

.args <- commandArgs(trailingOnly = FALSE)
.f    <- sub("^--file=", "", .args[grepl("^--file=", .args)])
.dir  <- if (length(.f) == 1 && nzchar(.f)) dirname(normalizePath(.f)) else getwd()
root  <- normalizePath(file.path(.dir, ".."))   # R/ -> project root

rmd <- file.path(root, "report", "ev_range_report.Rmd")
if (!file.exists(rmd)) stop("Report source not found: ", rmd, call. = FALSE)
if (!requireNamespace("rmarkdown", quietly = TRUE))
  stop("Package 'rmarkdown' is required to render the report.", call. = FALSE)

rmarkdown::render(
  rmd,
  output_file = "ev_range_report.html",
  output_dir  = file.path(root, "report"),
  params      = list(project_root = root),
  quiet       = TRUE
)
cat("Rendered:", file.path(root, "report", "ev_range_report.html"), "\n")
