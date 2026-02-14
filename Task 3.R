#install Packages
install.packages(c("readxl", "dplyr", "janitor","ggplot2", "forecast", "tseries"))

library(readxl)   # reading Excel files
library(dplyr)    # data wrangling
library(janitor)  # clean_names()
library(ggplot2)  # plotting
library(forecast) # time series models (ETS, ARIMA, etc.)
library(tseries)  # ADF test for stationarity



# 1. LOAD RAW DATA

# Load data
births_raw <- read_excel("Vital statistics in the UK.xlsx", sheet = "Birth")

# Quick look
str(births_raw)
names(births_raw)
head(births_raw)

# Ignore the top 5 metadata rows
births_raw <- read_excel(
  "Vital statistics in the UK.xlsx",
  sheet = "Birth",
  skip  = 5      # skip note rows so row 6 becomes header
)

# Inspect structure
str(births_raw)
head(births_raw)



# 2. CLEAN COLUMN NAMES

# Turn long, messy names into snake_case
births <- births_raw %>%janitor::clean_names()

# Look at the new names
names(births)



# 3. REMOVE JUNK COLUMNS

# Remove any column whose name starts with "x"

births <- births %>%select(-starts_with("x"))

str(births)



# 4. FIX DATA TYPES (NUMERIC VS TEXT)

# For each character column:
#  1. Remove everything that is not a digit or decimal point.
#  2. Convert the cleaned string to numeric.

births <- births %>%
  mutate(
    across(
      where(is.character),
      ~ gsub("[^0-9\\.]", "", .)   # keep only digits and decimal points
    )
  ) %>%
  mutate(
    across(
      where(is.character),
      ~ as.numeric(.)
    )
  )

# Check structure again
str(births)

# Check how many NAs are present in each column
sapply(births, function(x) sum(is.na(x)))



# 5. BUILD A CLEAN WORKING DATAFRAME

# Select the focused columns

births_clean <- births %>%
  select(
    year,
    uk_births    = number_of_live_births_united_kingdom,
    uk_fertility = total_fertility_rate_united_kingdom
  ) %>%
  arrange(year)

# Show the first and last few rows
head(births_clean)
tail(births_clean)
summary(births_clean)

# If the very early years have missing UK births, drop those
births_clean <- births_clean %>%filter(!is.na(uk_births))

summary(births_clean)



# 6. CREATE TIME-SERIES OBJECT


# The data are annual, so frequency = 1
freq <- 1
start_year <- min(births_clean$year)

uk_births_ts <- ts(
  births_clean$uk_births,
  start     = c(start_year),
  frequency = freq
)

uk_births_ts



# 7. EXPLORATORY DATA ANALYSIS (EDA)


# 7.1 Time-series plot of UK births
autoplot(uk_births_ts) +
  labs(
    title = "UK Number of Live Births (Annual)",
    x = "Year",
    y = "Number of live births"
  )

# 7.2 Autocorrelation and partial autocorrelation
Acf(uk_births_ts, main = "ACF of UK Births")
Pacf(uk_births_ts, main = "PACF of UK Births")

# 7.3 Stationarity Check (ADF Test)

# ADF test on the original series
adf_original <- adf.test(uk_births_ts)
adf_original

# Difference the series once
uk_births_diff <- diff(uk_births_ts)

# ADF test on the differenced series
adf_diff <- adf.test(uk_births_diff)
adf_diff


# 7.4 Plot fertility rate to see the trend
ggplot(births_clean, aes(x = year, y = uk_fertility)) +
  geom_line() +
  geom_point(size = 0.7) +
  labs(
    title = "Total Fertility Rate in the UK",
    x = "Year",
    y = "Total fertility rate"
  )



# 8. TRAIN–TEST SPLIT


# We keep the last 10 years as a test set
h <- 10
n <- length(uk_births_ts)

train_ts <- window(
  uk_births_ts,
  end = c(start_year + (n - h - 1))
)

test_ts <- window(
  uk_births_ts,
  start = c(start_year + (n - h))
)

length(train_ts)  # training length
length(test_ts)   # test length


# 9. MODEL 1 – NAÏVE FORECAST


# Naïve model: forecast each future value as the last observed value
fit_naive <- naive(train_ts, h = h)

autoplot(fit_naive) +
  autolayer(test_ts, series = "Test") +
  labs(
    title = "Naïve Forecasts for UK Births",
    x = "Year",
    y = "Number of live births"
  )

# Accuracy on the test set
acc_naive <- accuracy(fit_naive, test_ts)
acc_naive



# 10. MODEL 2 – ETS (EXPONENTIAL SMOOTHING)


# Fit an ETS model (will choose between simple, Holt, damped, etc.)
fit_ets <- ets(train_ts)
summary(fit_ets)

# Forecast for the next h years
fc_ets <- forecast(fit_ets, h = h)

autoplot(fc_ets) +
  autolayer(test_ts, series = "Test") +
  labs(
    title = "ETS Forecasts for UK Births",
    x = "Year",
    y = "Number of live births"
  )

# Accuracy
acc_ets <- accuracy(fc_ets, test_ts)
acc_ets

# Residual diagnostics for ETS model
checkresiduals(fit_ets)



# 11. MODEL 3 – ARIMA (WITH LOG TRANSFORM)


# Optionally log-transform the training data if variance changes over time
train_log <- log(train_ts)

# auto.arima chooses (p, d, q) based on AICc
fit_arima <- auto.arima(train_log, seasonal = FALSE)
summary(fit_arima)

# Forecast on the log scale
fc_arima_log <- forecast(fit_arima, h = h)

# Back-transform forecasts to the original scale
fc_arima_vals <- exp(fc_arima_log$mean)

# Create a ts object aligned with test period
fc_arima_ts <- ts(
  fc_arima_vals,
  start     = time(test_ts)[1],
  frequency = freq
)

# Plot ARIMA forecasts vs. actual test data
autoplot(train_ts) +
  autolayer(test_ts,      series = "Test") +
  autolayer(fc_arima_ts, series = "ARIMA forecasts") +
  labs(
    title = "ARIMA Forecasts for UK Births",
    x = "Year",
    y = "Number of live births"
  )

# Accuracy
acc_arima <- accuracy(fc_arima_ts, test_ts)
acc_arima

# Residual diagnostics
checkresiduals(fit_arima)



# 12. MODEL COMPARISON


# Compare Naïve, ETS and ARIMA on RMSE, MAE, MAPE
comparison <- rbind(
  Naive = acc_naive["Test set", c("RMSE", "MAE", "MAPE")],
  ETS   = acc_ets["Test set",   c("RMSE", "MAE", "MAPE")],
  ARIMA = acc_arima["Test set", c("RMSE", "MAE", "MAPE")]
)


comparison



# 13. FINAL MODEL ON FULL DATA

# Final model: ETS performed best on the test set
fit_final <- ets(uk_births_ts)
summary(fit_final)

fc_final  <- forecast(fit_final, h = 10)  # 10-year forecast

autoplot(uk_births_ts) +
  autolayer(fc_final$mean, series = "Forecast") +
  labs(
    title = "Final 10-Year Forecast of UK Live Births",
    x = "Year",
    y = "Number of live births"
  )



# 14. HYPOTHESIS TEST (FERTILITY RATE CHANGE)



# Define early and late periods
mid_year <- 2000     # split at year 2000

early_period <- births_clean %>%
  filter(year <= mid_year, !is.na(uk_fertility)) %>%
  pull(uk_fertility)

late_period <- births_clean %>%
  filter(year > mid_year, !is.na(uk_fertility)) %>%
  pull(uk_fertility)

length(early_period)
length(late_period)

# Two-sample t-test (unequal variances by default)
fertility_ttest <- t.test(early_period, late_period)

fertility_ttest
