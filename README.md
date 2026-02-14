# 📈 UK Births Time Series Forecasting  
### ARIMA vs ETS Modelling in R

This project presents a complete time series analysis of annual UK live births, comparing classical forecasting approaches including Naïve, ETS (Exponential Smoothing), and ARIMA models.

The objective was to evaluate long-term demographic trends and determine the most reliable statistical forecasting method.

---

## 📁 Repository Structure

├── Task 3.R

├── Time Series Analysis of UK Live Births.pdf

└── README.md

- **Task 3.R** – Full R script for data cleaning, modelling, and forecasting  
- **Report (PDF)** – Detailed methodology, diagnostics, and interpretation  

---

## 🎯 Objective

- Analyse historical UK live birth data  
- Test for stationarity  
- Compare forecasting models:
  - Naïve benchmark
  - ETS
  - ARIMA (log-transformed)  
- Evaluate out-of-sample forecast performance  

---

## 📊 Dataset

- Annual UK live births  
- Over 100 years of historical data  
- Includes Total Fertility Rate (TFR)  

---

## 🔍 Methodology

### 1️⃣ Exploratory Analysis
- Long-term trend visualisation  
- 5-year moving average smoothing  
- Identification of structural shifts (baby boom, post-2000 decline)

### 2️⃣ Stationarity Testing
- ACF & PACF analysis  
- Augmented Dickey–Fuller (ADF) test  
- Differencing applied to achieve stationarity  

### 3️⃣ Train–Test Split
- Final 10 observations reserved for testing  
- Remaining data used for model fitting  

---

## 📉 Models Implemented

### Naïve Model
- Benchmark forecast  
- Assumes next value equals last observed value  

### ETS Model
- Automatically selected: ETS(M, N, N)  
- Multiplicative errors  
- No trend or seasonality  
- Best residual diagnostics  

### ARIMA Model
- Log transformation applied  
- auto.arima selected ARIMA(0,1,0)  
- Equivalent to differenced random walk  

---

## 📊 Model Comparison

| Model | Strength | Limitation |
|--------|----------|------------|
| Naïve | Strong baseline | No structural insight |
| ETS | Best residual diagnostics | Limited structural modelling |
| ARIMA | Statistically principled | Reduced to random walk |

### ✅ Final Conclusion
ETS provided the most stable and reliable forecast performance.

---

## 📈 Key Insights

- UK births show strong long-term decline post-1970s  
- Series is non-stationary and requires differencing  
- Simple models perform competitively in demographic forecasting  
- Fertility trends align with declining birth rates  

---

## 🛠 Tools Used

- R  
- forecast  
- tseries  
- ggplot2  
- dplyr  

---

## 📄 Full Report

See the detailed statistical explanation in:

`Time Series Analysis of UK Live Births.pdf`

---

## 👤 Author

Muhammed Fahim Englampurath  
MSc Data Science — University of Salford  

GitHub: https://github.com/MUHAMMEDFAHIM-2  
LinkedIn: https://www.linkedin.com/in/muhammed-fahim-03209b1bb/
