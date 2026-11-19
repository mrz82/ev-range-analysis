# ==============================================================================
# 02_eda.R  --  Exploratory Data Analysis
# ==============================================================================
# Produces the summary statistics, comparison tables, and figures reported in
# the final report. Figures are written to figures/ and tables to output/tables/.
#
# Reproduces, in report order:
#   - Overall + grouped summary statistics (Table 1)
#   - FWD/RWD/AWD three-group comparison (pre-recode EDA)
#   - Boxplots of the three quantitative variables (outlier check)
#   - Figure 1: distribution of driving range by drivetrain (histogram)
#   - Figure 2: range vs battery capacity
#   - Figure 3: range vs battery capacity by drivetrain
#   - Figure 4: range vs vehicle length
#   - Figure 5: battery capacity vs vehicle length
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

message("\n=== 02_eda.R ===")

if (!file.exists(CLEAN_DATA)) stop("Cleaned data not found. Run 01_clean_data.R first.",
                                   call. = FALSE)
ev <- read.csv(CLEAN_DATA, stringsAsFactors = FALSE) %>%
  mutate(
    drivetrain        = factor(drivetrain, levels = c("FWD", "RWD", "AWD")),
    drivetrain_binary = factor(drivetrain_binary, levels = c("2WD", "AWD"))
  )

quant_vars <- c("range_km", "battery_capacity_kWh", "length_mm")

# ------------------------------------------------------------------------------
# Helper: compact summary (n, mean, sd, median, min, max) for the 3 quant vars
# ------------------------------------------------------------------------------
summarise_quant <- function(df) {
  df %>% summarise(
    n            = n(),
    range_mean   = round(mean(range_km), 2),
    range_sd     = round(sd(range_km), 2),
    range_min    = min(range_km),
    range_max    = max(range_km),
    battery_mean = round(mean(battery_capacity_kWh), 2),
    battery_sd   = round(sd(battery_capacity_kWh), 2),
    length_mean  = round(mean(length_mm), 2),
    length_sd    = round(sd(length_mm), 2)
  )
}

# ------------------------------------------------------------------------------
# Table 1: overall + by binary drivetrain (as reported)
# ------------------------------------------------------------------------------
table1 <- bind_rows(
  summarise_quant(ev) %>% mutate(group = "Overall", .before = 1),
  ev %>% group_by(drivetrain_binary) %>% summarise_quant() %>%
    rename(group = drivetrain_binary) %>% mutate(group = as.character(group))
)
cat("\nTable 1 -- Summary statistics by drivetrain configuration:\n")
print(as.data.frame(table1))
write.csv(table1, file.path(TABLES_DIR, "table1_summary_by_drivetrain.csv"),
          row.names = FALSE)

# ------------------------------------------------------------------------------
# Pre-recode EDA: compare the original FWD / RWD / AWD groups.
# Motivates (and documents the cost of) collapsing FWD + RWD into 2WD.
# ------------------------------------------------------------------------------
eda_3group <- ev %>% group_by(drivetrain) %>% summarise_quant() %>%
  rename(group = drivetrain)
cat("\nThree-group drivetrain comparison (FWD / RWD / AWD):\n")
print(as.data.frame(eda_3group))
write.csv(eda_3group, file.path(TABLES_DIR, "eda_drivetrain_3group.csv"),
          row.names = FALSE)

# ------------------------------------------------------------------------------
# Boxplots of the three quantitative variables (implausible-value check)
# ------------------------------------------------------------------------------
png(file.path(FIGURES_DIR, "fig0_boxplots_quant.png"),
    width = 1050, height = 400, res = 130)
par(mfrow = c(1, 3))
boxplot(ev$range_km,             main = "Range (km)",           col = "lightpink")
boxplot(ev$battery_capacity_kWh, main = "Battery Capacity (kWh)", col = "lightblue")
boxplot(ev$length_mm,            main = "Vehicle Length (mm)",   col = "yellow")
par(mfrow = c(1, 1))
dev.off()
message("Saved figure: ", file.path(FIGURES_DIR, "fig0_boxplots_quant.png"))

# ------------------------------------------------------------------------------
# Figure 1: distribution of driving range by drivetrain (histogram)
# ------------------------------------------------------------------------------
fig1 <- ggplot(ev, aes(x = range_km, fill = drivetrain_binary)) +
  geom_histogram(position = "identity", alpha = 0.55, bins = 30) +
  labs(title = "Distribution of Driving Range by Drivetrain Type",
       x = "Driving Range (km)", y = "Count", fill = "Drivetrain") +
  theme_minimal()
save_fig(fig1, "fig1_range_hist_by_drivetrain.png")

# ------------------------------------------------------------------------------
# Figure 2: driving range vs battery capacity
# ------------------------------------------------------------------------------
fig2 <- ggplot(ev, aes(x = battery_capacity_kWh, y = range_km)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x) +
  labs(title = "Driving Range vs Battery Capacity",
       x = "Battery Capacity (kWh)", y = "Driving Range (km)") +
  theme_minimal()
save_fig(fig2, "fig2_range_vs_battery.png")

# ------------------------------------------------------------------------------
# Figure 3: driving range vs battery capacity by drivetrain
# ------------------------------------------------------------------------------
fig3 <- ggplot(ev, aes(x = battery_capacity_kWh, y = range_km,
                       color = drivetrain_binary)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x) +
  labs(title = "Driving Range vs Battery Capacity by Drivetrain",
       x = "Battery Capacity (kWh)", y = "Driving Range (km)",
       color = "Drivetrain") +
  theme_minimal()
save_fig(fig3, "fig3_range_vs_battery_by_drivetrain.png")

# ------------------------------------------------------------------------------
# Figure 4: driving range vs vehicle length
# ------------------------------------------------------------------------------
fig4 <- ggplot(ev, aes(x = length_mm, y = range_km)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x) +
  labs(title = "Driving Range vs Vehicle Length",
       x = "Vehicle Length (mm)", y = "Driving Range (km)") +
  theme_minimal()
save_fig(fig4, "fig4_range_vs_length.png")

# ------------------------------------------------------------------------------
# Figure 5: battery capacity vs vehicle length
# ------------------------------------------------------------------------------
fig5 <- ggplot(ev, aes(x = length_mm, y = battery_capacity_kWh)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x) +
  labs(title = "Battery Capacity vs Vehicle Length",
       x = "Vehicle Length (mm)", y = "Battery Capacity (kWh)") +
  theme_minimal()
save_fig(fig5, "fig5_battery_vs_length.png")

message("EDA complete.")
