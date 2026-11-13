# STAT 306 Final Project R Script
# Authors: Mahour Rezvani, Markus Rosario, Desiree Ng, Doa Binte Rashid

# Research question:
# Does drivetrain configuration (AWD vs 2WD) moderate the relationship
# between battery capacity and driving range, after controlling for vehicle length?
  
# Load packages and raw data

library(tidyverse)
library(car)
library(leaps)

raw <- read.csv("electric_vehicles_spec_2025.csv.csv", stringsAsFactors = FALSE)
#raw <- read.csv("electric_vehicles_spec_2025.csv.csv", stringsAsFactors = FALSE)

cat("Raw dataset dimensions:", nrow(raw), "rows x", ncol(raw), "columns\n")

# Data Cleaning

ev_data <- raw %>%
  select(brand, model, range_km, battery_capacity_kWh, drivetrain, length_mm)

cat("Selected subset dimensions:", nrow(ev_data), "rows x", ncol(ev_data), "columns\n")

# Check for missing values in the selected columns

cat("Missing values per column:\n")
colSums(is.na(ev_data))

# Check for any empty strings

cat("\nEmpty strings per column:\n")
colSums(ev_data == "", na.rm = TRUE)

# Shows the row with missing model name for transparency

ev_data %>% filter(model == "")

# Recode: AWD stays AWD; FWD and RWD become 2WD

ev_data <- ev_data %>%
  mutate(
    drivetrain_binary = ifelse(drivetrain == "AWD", "AWD", "2WD"),
    drivetrain_binary = factor(drivetrain_binary, levels = c("2WD", "AWD"))
  )

# New distribution

cat("\nRecoded drivetrain counts:\n")
table(ev_data$drivetrain_binary)

# Check for Duplicates

n_duplicate <- sum(duplicated(ev_data))
cat("Number of duplicated rows:", n_duplicate, "\n")

# Summary statistics

ev_data %>%
  summarise(
    across(c(range_km, battery_capacity_kWh, length_mm),  # I
           list(min = min, median = median, mean = mean, max = max, sd = sd),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(everything(), names_to = "stat", values_to = "value") %>%
  print(n = 15)  # because we have 15 stats(R only shows 10 rows by default )

# Visual check with boxplots

par(mfrow = c(1, 3)) #side by side box plot 
boxplot(ev_data$range_km, main = "Range (km)", col = "lightpink")
boxplot(ev_data$battery_capacity_kWh, main = "Battery Capacity (kWh)", col = "lightblue")
boxplot(ev_data$length_mm, main = "Vehicle Length (mm)", col = "yellow")

# Final cleaned dataset

ev <- ev_data %>%
  select(brand, model, range_km, battery_capacity_kWh, drivetrain_binary, length_mm)

cat("Final cleaned dataset:", nrow(ev), "rows x", ncol(ev), "columns\n")
str(ev)
head(ev, 10)

# Export cleaned data

write.csv(ev, "ev_clean_data.csv", row.names = FALSE)

# Exploratory Data Analysis

glimpse(ev)
colSums(is.na(ev))
sum(duplicated(ev))
table(ev$drivetrain_binary)

ev %>%
  summarise(
    n = n(),
    range_mean = round(mean(range_km), 2),
    range_sd = round(sd(range_km), 2),
    range_median = round(median(range_km), 2),
    range_min = min(range_km),
    range_max = max(range_km),
    battery_mean = round(mean(battery_capacity_kWh), 2),
    battery_sd = round(sd(battery_capacity_kWh), 2),
    battery_median = round(median(battery_capacity_kWh), 2),
    battery_min = min(battery_capacity_kWh),
    battery_max = max(battery_capacity_kWh),
    length_mean = round(mean(length_mm), 2),
    length_sd = round(sd(length_mm), 2),
    length_median = round(median(length_mm), 2),
    length_min = min(length_mm),
    length_max = max(length_mm)
  )

# Grouped Summary by Drivetrain

ev %>%
  group_by(drivetrain_binary) %>%
  summarise(
    n = n(),
    range_mean = round(mean(range_km), 2),
    range_sd = round(sd(range_km), 2),
    battery_mean = round(mean(battery_capacity_kWh), 2),
    battery_sd = round(sd(battery_capacity_kWh), 2),
    length_mean = round(mean(length_mm), 2),
    length_sd = round(sd(length_mm), 2)
  )

# Figure 1: Driving Range vs. Battery Capacity

ggplot(ev,
       aes(x = battery_capacity_kWh,
           y = range_km)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Driving Range vs Battery Capacity",
    x = "Battery Capacity (kWh)",
    y = "Driving Range (km)"
  ) +
  theme_minimal()

# Figure 2: Driving Range vs. Battery Capacity by Drivetrain

ggplot(ev,
       aes(x = battery_capacity_kWh,
           y = range_km,
           color = drivetrain_binary)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Driving Range vs Battery Capacity by Drivetrain",
    x = "Battery Capacity (kWh)",
    y = "Driving Range (km)",
    color = "Drivetrain"
  ) +
  theme_minimal()

# Figure 3: Driving Range vs. Vehicle Length

ggplot(ev, aes(x = length_mm, y = range_km)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Driving Range vs Vehicle Length",
    x = "Vehicle Length (mm)",
    y = "Driving Range (km)"
  ) +
  theme_minimal()

# Figure 4: Battery Capacity vs. Vehicle Length

ggplot(ev, aes(x = length_mm, y = battery_capacity_kWh)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Battery Capacity vs Vehicle Length",
    x = "Vehicle Length (mm)",
    y = "Battery Capacity (kWh)"
  ) +
  theme_minimal()


## Statistical Analysis

# create log-transformed dataset
ev_log <- ev %>%
  mutate(
    log_range = log(range_km),
    log_battery = log(battery_capacity_kWh),
    log_length = log(length_mm)
  )

# Model selection on log-transformed additive model
ev_log_final <- ev_log %>% select(log_range, log_battery, drivetrain_binary, log_length)
s <- regsubsets(log_range ~ ., data = ev_log_final, method = "exhaustive")
ss <- summary(s)
ss$which
ss$cp
ss$adjr2

# fitted Log model
reg_log <- lm(log_range ~ log_battery * drivetrain_binary + log_length, data = ev_log)
summary(reg_log)
summary(reg_log)$adj.r.squared

# model diagnostics on log model
par(mfrow = c(2, 2))
plot(reg_log)
par(mfrow = c(1, 1))

# VIF on log model
cat("\nVariance Inflation Factors (VIF):\n")
print(vif(reg_log, type = "predictor"))

# cook's distance on log model
plot(cooks.distance(reg_log), type = "h",
     main = "Cook's Distance",
     ylab = "Cook's distance")
abline(h = 4 / nrow(ev_log), col = "red", lty = 2)