################################################################################
# VALUE AT RISK & EXPECTED SHORTFALL ANALYSIS
# Professional Market Risk Analysis Framework
################################################################################
#
# PURPOSE
#   Perform a comprehensive Value at Risk (VaR) and Expected Shortfall (ES)
#   analysis for an equal-weighted technology portfolio versus a NASDAQ benchmark.
#
# PORTFOLIO (EQUAL-WEIGHTED)
#   - MSFT (Microsoft)
#   - INTC (Intel)
#   - CSCO (Cisco)
#   - ORCL (Oracle)
#   - AAPL (Apple)
#
# ANALYSIS HORIZON
#   November 1999 - November 2025 (26 years, monthly data)
#
# CORE METHODS
#   1. Historical VaR/ES (non-parametric, empirical distribution)
#   2. Parametric VaR/ES (normal distribution assumption)
#   3. Monte Carlo VaR/ES (10,000 simulated paths, normal)
#
# ADVANCED EXTENSIONS
#   - GARCH(1,1) conditional volatility (Portfolio & NASDAQ)
#   - Copula-based tail dependence (Clayton copula, Portfolio vs NASDAQ)
#   - Scenario-based stress testing (Tech Crash, Rate Shock)
#   - Drawdown analysis & comparison (20% threshold analysis)
#   - Zero drawdown periods & gap analysis
#   - Individual stocks performance metrics
#
# OUTPUTS
#   Console:
#     - Descriptive statistics (monthly & annualized)
#     - VaR / ES for all three methods (95%, 99%)
#     - GARCH(1,1) parameters & volatility summary
#     - Copula dependence metrics (theta, lower tail dependence)
#     - Stress scenario table (base, tech crash, rate shock)
#     - Drawdown comparison analysis
#     - Individual stock performance & Sharpe ratios
#
#   Files (PNG):
#     - 01_distributions_combined.png
#     - 02_drawdown_comparison.png
#     - 03_garch_portfolio_nasdaq_vol.png
#     - 04_copula_portfolio_nasdaq.png
#
#   Files (CSV):
#     - risk_metrics_summary.csv
#     - wealth_index.csv
#     - individual_stocks_performance.csv
#     - portfolio_vs_nasdaq_comparison.csv
#     - garch_portfolio_nasdaq_summary.csv
#     - copula_portfolio_nasdaq_summary.csv
#     - stress_scenarios_summary.csv
#     - sharpe_ratios_stocks_portfolio_nasdaq.csv
#     - portfolio_risk_decomposition.csv
#     - zero_drawdown_both_portfolio_nasdaq.csv
#     - recovery_max_gap_comparison.csv
#     - drawdown_nasdaq_worse_than_portfolio_20pct.csv
#     - drawdown_portfolio_worse_than_nasdaq_20pct.csv
#     - drawdown_comparison_summary.csv
#
# AUTHOR:   [Your Name]
# DATE:     [Date]
# VERSION:  2.0
#
################################################################################

# ============================================================================
# 1. ENVIRONMENT SETUP
# ============================================================================

# Clear workspace for reproducibility
rm(list = ls())

# Set locale for consistent date formatting (console + plots)
Sys.setlocale("LC_TIME", "en_US.UTF-8")

# ============================================================================
# 2. DEPENDENCIES
# ============================================================================

# Required packages (auto-install if missing)
required_packages <- c(
  "quantmod",              # Financial data retrieval
  "dplyr",                 # Data manipulation
  "tidyr",                 # Data reshaping
  "ggplot2",               # Visualization
  "PerformanceAnalytics",  # Risk metrics
  "gridExtra",             # Multi-panel plots
  "lubridate"              # Date manipulation
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Installing package:", pkg, "\n")
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("=" %+% strrep("=", 78) %+% "=\n")
cat("VALUE AT RISK & EXPECTED SHORTFALL ANALYSIS\n")
cat("Portfolio: MSFT, INTC, CSCO, ORCL, AAPL | Benchmark: NASDAQ Composite\n")
cat("Period: November 1999 - November 2025 (26 Years, Monthly Data)\n")
cat("=" %+% strrep("=", 78) %+% "=\n\n")

# ============================================================================
# 3. CONFIGURATION PARAMETERS
# ============================================================================

# Data window
START_DATE <- "1999-11-01"
END_DATE   <- "2025-11-30"

# Assets
PORTFOLIO_TICKERS <- c("MSFT", "INTC", "CSCO", "ORCL", "AAPL")
BENCHMARK_TICKER  <- "^IXIC"   # NASDAQ Composite

# VaR confidence levels
CONFIDENCE_LEVELS <- c(0.95, 0.99)
Z_SCORES          <- c(1.645, 2.326)  # Normal z-scores for 95% and 99%

# Monte Carlo configuration
MC_SIMULATIONS <- 10000
MC_SEED        <- 42

# ============================================================================
# 4. DATA ACQUISITION & CLEANING
# ============================================================================

cat("STEP 1: DATA ACQUISITION & PREPARATION\n")
cat("-" %+% strrep("-", 76) %+% "-\n")
cat("Downloading monthly adjusted prices for portfolio stocks...\n")

# Download portfolio stocks
stock_list <- list()

for (ticker in PORTFOLIO_TICKERS) {
  tryCatch({
    data <- getSymbols(
      ticker,
      from        = START_DATE,
      to          = END_DATE,
      periodicity = "monthly",
      auto.assign = FALSE
    )
    
    close_prices    <- Ad(data)
    monthly_returns <- ROC(close_prices, type = "discrete") * 100
    
    # Remove first NA (no previous price)
    stock_list[[ticker]] <- monthly_returns[-1, ]
    cat(sprintf("  ✓ %s: %d monthly observations\n",
                ticker, nrow(monthly_returns) - 1))
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error loading %s: %s\n", ticker, e$message))
  })
}

# Merge portfolio returns into a single xts object
returns_matrix <- do.call(merge, stock_list)
colnames(returns_matrix) <- PORTFOLIO_TICKERS

# Download benchmark (NASDAQ Composite)
cat("\nDownloading monthly NASDAQ benchmark data...\n")

nasdaq_data <- getSymbols(
  BENCHMARK_TICKER,
  from        = START_DATE,
  to          = END_DATE,
  periodicity = "monthly",
  auto.assign = FALSE
)

nasdaq_returns <- ROC(Ad(nasdaq_data), type = "discrete") * 100
nasdaq_returns <- nasdaq_returns[-1, ]

cat(sprintf("  ✓ NASDAQ: %d monthly observations\n", nrow(nasdaq_returns)))

# Align portfolio and benchmark by common dates
merged_data      <- merge(returns_matrix, nasdaq_returns, join = "inner")
returns_matrix   <- merged_data[, 1:ncol(returns_matrix)]
nasdaq_returns   <- merged_data[, ncol(merged_data)]

start_date_actual <- as.character(index(returns_matrix)[1])
end_date_actual   <- as.character(tail(index(returns_matrix), 1))

cat("\n✓ Data successfully aligned\n")
cat(sprintf("  Period: %s to %s\n", start_date_actual, end_date_actual))
cat(sprintf("  Observations: %d months (%.2f years)\n\n",
            nrow(returns_matrix), nrow(returns_matrix) / 12))

# ============================================================================
# 5. PORTFOLIO CONSTRUCTION & DESCRIPTIVE STATISTICS
# ============================================================================

cat("STEP 2: PORTFOLIO CONSTRUCTION & DESCRIPTIVE STATISTICS\n")
cat("-" %+% strrep("-", 76) %+% "-\n")

# Equal-weighted portfolio returns
portfolio_returns       <- rowMeans(returns_matrix)
portfolio_returns_clean <- na.omit(portfolio_returns)

# Portfolio statistics
mean_return    <- mean(portfolio_returns_clean, na.rm = TRUE)
std_dev        <- sd(portfolio_returns_clean,   na.rm = TRUE)
skewness_port  <- mean((portfolio_returns_clean - mean_return)^3) / (std_dev^3)
kurtosis_port  <- mean((portfolio_returns_clean - mean_return)^4) / (std_dev^4)

cat("Equal-Weighted Portfolio (20% per stock)\n\n")
cat("DESCRIPTIVE STATISTICS (Monthly)\n")
cat(sprintf("  Mean Return:             %8.4f %%\n", mean_return))
cat(sprintf("  Standard Deviation:      %8.4f %%\n", std_dev))
cat(sprintf("  Skewness:                %8.4f\n", skewness_port))
cat(sprintf("  Excess Kurtosis:         %8.4f\n\n", kurtosis_port - 3))

cat("ANNUALIZED METRICS\n")
cat(sprintf("  Annualized Return:       %8.2f %%\n", mean_return * 12))
cat(sprintf("  Annualized Volatility:   %8.2f %%\n", std_dev * sqrt(12)))
cat(sprintf("  Sharpe Ratio (Rf = 0%%): %8.4f\n\n",
            (mean_return * 12) / (std_dev * sqrt(12))))

# Benchmark statistics
nasdaq_returns_clean <- na.omit(nasdaq_returns)
mean_nasdaq          <- mean(nasdaq_returns_clean, na.rm = TRUE)
std_nasdaq           <- sd(nasdaq_returns_clean,   na.rm = TRUE)
skewness_nas         <- mean((nasdaq_returns_clean - mean_nasdaq)^3) / (std_nasdaq^3)
kurtosis_nas         <- mean((nasdaq_returns_clean - mean_nasdaq)^4) / (std_nasdaq^4)

cat("NASDAQ Benchmark\n\n")
cat("DESCRIPTIVE STATISTICS (Monthly)\n")
cat(sprintf("  Mean Return:             %8.4f %%\n", mean_nasdaq))
cat(sprintf("  Standard Deviation:      %8.4f %%\n", std_nasdaq))
cat(sprintf("  Skewness:                %8.4f\n", skewness_nas))
cat(sprintf("  Excess Kurtosis:         %8.4f\n\n", kurtosis_nas - 3))

cat("ANNUALIZED METRICS\n")
cat(sprintf("  Annualized Return:       %8.2f %%\n", mean_nasdaq * 12))
cat(sprintf("  Annualized Volatility:   %8.2f %%\n", std_nasdaq * sqrt(12)))
cat(sprintf("  Sharpe Ratio (Rf = 0%%): %8.4f\n\n",
            (mean_nasdaq * 12) / (std_nasdaq * sqrt(12))))


# ============================================================================
# 5.BIS GARCH(1,1) VOLATILITY MODEL – PORTFOLIO & NASDAQ
# ============================================================================

cat("STEP 2 BIS: GARCH(1,1) VOLATILITY MODEL – PORTFOLIO & NASDAQ\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

if (!require("rugarch", character.only = TRUE)) {
  cat("Installing package: rugarch\n")
  install.packages("rugarch", dependencies = TRUE)
  library("rugarch", character.only = TRUE)
}

# ============ PORTFOLIO ============
# Portfolio returns (numeric vector, in %)
port_ret <- as.numeric(portfolio_returns_clean)

# 1) GARCH(1,1) specification with constant mean
spec_garch_port <- ugarchspec(
  variance.model = list(
    model      = "sGARCH",   # standard GARCH
    garchOrder = c(1, 1)
  ),
  mean.model = list(
    armaOrder    = c(0, 0),  # no ARMA, constant mean mu
    include.mean = TRUE
  ),
  distribution.model = "norm"  # Gaussian innovations
)

# 2) Fit model
fit_garch_port <- ugarchfit(
  spec = spec_garch_port,
  data = port_ret
)

# 3) Extract GARCH parameters
garch_coef <- coef(fit_garch_port)
omega_hat  <- garch_coef["omega"]
alpha_hat  <- garch_coef["alpha1"]
beta_hat   <- garch_coef["beta1"]

cat("GARCH(1,1) estimated parameters (PORTFOLIO):\n")
cat(sprintf("  omega  = %.6f\n", omega_hat))
cat(sprintf("  alpha1 = %.6f\n", alpha_hat))
cat(sprintf("  beta1  = %.6f\n", beta_hat))
cat(sprintf("  alpha1 + beta1 = %.6f (volatility persistence)\n\n",
            alpha_hat + beta_hat))

# 4) Conditional volatility sigma_t (monthly) + annualized
sigma_t_port <- sigma(fit_garch_port)

# ============ NASDAQ ============
# NASDAQ returns (numeric vector, in %)
nasdaq_ret <- as.numeric(nasdaq_returns_clean)

# Same spec for NASDAQ
spec_garch_nasdaq <- ugarchspec(
  variance.model = list(
    model      = "sGARCH",
    garchOrder = c(1, 1)
  ),
  mean.model = list(
    armaOrder    = c(0, 0),
    include.mean = TRUE
  ),
  distribution.model = "norm"
)

# Fit NASDAQ model
fit_garch_nasdaq <- ugarchfit(
  spec = spec_garch_nasdaq,
  data = nasdaq_ret
)

# Extract NASDAQ GARCH parameters
garch_coef_nasdaq <- coef(fit_garch_nasdaq)
omega_nasdaq      <- garch_coef_nasdaq["omega"]
alpha_nasdaq      <- garch_coef_nasdaq["alpha1"]
beta_nasdaq       <- garch_coef_nasdaq["beta1"]

cat("GARCH(1,1) estimated parameters (NASDAQ):\n")
cat(sprintf("  omega  = %.6f\n", omega_nasdaq))
cat(sprintf("  alpha1 = %.6f\n", alpha_nasdaq))
cat(sprintf("  beta1  = %.6f\n", beta_nasdaq))
cat(sprintf("  alpha1 + beta1 = %.6f (volatility persistence)\n\n",
            alpha_nasdaq + beta_nasdaq))

# Conditional volatility for NASDAQ
sigma_t_nasdaq <- sigma(fit_garch_nasdaq)

# ============ COMBINE DATA ============
dates_garch <- index(returns_matrix)
stopifnot(length(dates_garch) == length(sigma_t_port))
stopifnot(length(dates_garch) == length(sigma_t_nasdaq))

garch_df <- data.frame(
  Date                    = as.Date(dates_garch),
  Portfolio_Sigma_monthly = as.numeric(sigma_t_port),
  NASDAQ_Sigma_monthly    = as.numeric(sigma_t_nasdaq),
  Portfolio_Sigma_annual  = as.numeric(sigma_t_port) * sqrt(12),
  NASDAQ_Sigma_annual     = as.numeric(sigma_t_nasdaq) * sqrt(12)
)

# ============ ALIGN DATES (REMOVE MISMATCHES) ============
# Keep only rows where both Portfolio and NASDAQ have valid data
garch_df <- garch_df[!is.na(garch_df$Portfolio_Sigma_monthly) & 
                       !is.na(garch_df$NASDAQ_Sigma_monthly), ]

cat("GARCH data alignment:\n")
cat(sprintf("  Rows with complete data: %d\n", nrow(garch_df)))
cat(sprintf("  Date range: %s to %s\n\n", 
            min(garch_df$Date), max(garch_df$Date)))

# ============ GARCH VOLATILITY SUMMARY ============
garch_summary <- data.frame(
  Metric = c(
    "Mean Sigma (monthly)",
    "Mean Sigma (annualized)",
    "Max Sigma (annualized)",
    "Min Sigma (annualized)"
  ),
  Portfolio = c(
    mean(garch_df$Portfolio_Sigma_monthly,    na.rm = TRUE),
    mean(garch_df$Portfolio_Sigma_annual,     na.rm = TRUE),
    max(garch_df$Portfolio_Sigma_annual,      na.rm = TRUE),
    min(garch_df$Portfolio_Sigma_annual,      na.rm = TRUE)
  ),
  NASDAQ = c(
    mean(garch_df$NASDAQ_Sigma_monthly,       na.rm = TRUE),
    mean(garch_df$NASDAQ_Sigma_annual,        na.rm = TRUE),
    max(garch_df$NASDAQ_Sigma_annual,         na.rm = TRUE),
    min(garch_df$NASDAQ_Sigma_annual,         na.rm = TRUE)
  )
)
garch_summary[, 2:3] <- round(garch_summary[, 2:3], 4)

cat("GARCH VOLATILITY SUMMARY – PORTFOLIO vs NASDAQ\n")
print(garch_summary)
cat("\n")

write.csv(garch_summary, "garch_portfolio_nasdaq_summary.csv", row.names = FALSE)

# ============ PLOT: BOTH ON SAME GRAPH ============
p_garch_combined <- ggplot(garch_df, aes(x = Date)) +
  geom_line(aes(y = Portfolio_Sigma_annual, color = "Portfolio"), 
            linewidth = 1.2, alpha = 0.9) +
  geom_line(aes(y = NASDAQ_Sigma_annual, color = "NASDAQ"), 
            linewidth = 1.2, alpha = 0.9) +
  scale_color_manual(
    name   = "Asset",
    values = c("Portfolio" = "#3498db", "NASDAQ" = "#e74c3c")
  ) +
  scale_x_date(
    date_breaks = "2 years",
    date_labels = "%Y"
  ) +
  labs(
    title    = "GARCH(1,1) Conditional Volatility – Portfolio vs NASDAQ",
    subtitle = "Annualized (Dec 1999 – Nov 2025)",
    x        = "Year",
    y        = "Volatility (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, margin = margin(b = 10)),
    plot.subtitle   = element_text(size = 12, margin = margin(b = 15)),
    legend.position = "top",
    panel.grid.major.y = element_line(color = "white", linewidth = 0.8)
  )

ggsave("03_garch_portfolio_nasdaq_vol.png", p_garch_combined,
       width = 14, height = 7, dpi = 300)
cat("  ✓ Saved: 03_garch_portfolio_nasdaq_vol.png\n\n")
print(p_garch_combined)

# ============================================================================
# 5.TER COPULA ANALYSIS: PORTFOLIO vs NASDAQ (TAIL DEPENDENCE)
# ============================================================================

cat("STEP 2 TER: COPULA ANALYSIS – PORTFOLIO vs NASDAQ\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# 0) Monthly returns (in %) for portfolio and NASDAQ
port_copula_ret <- as.numeric(portfolio_returns_clean)
nas_copula_ret  <- as.numeric(nasdaq_returns_clean)

valid_idx  <- complete.cases(port_copula_ret, nas_copula_ret)
port_clean <- port_copula_ret[valid_idx]
nas_clean  <- nas_copula_ret[valid_idx]
n_copula   <- length(port_clean)

# 1) Transform to U(0,1) using empirical CDF (ranks)
u_port <- rank(port_clean) / (n_copula + 1)
u_nas  <- rank(nas_clean)  / (n_copula + 1)

# 2) Copula package
if (!require("copula", character.only = TRUE)) {
  cat("Installing package: copula\n")
  install.packages("copula", dependencies = TRUE)
  library("copula", character.only = TRUE)
}

# 3) Clayton copula (focus on lower tail dependence)
clayton_init <- claytonCopula(param = 1, dim = 2)

# 4) Fit copula using Kendall's tau (robust)
fit_clayton <- fitCopula(
  clayton_init,
  cbind(u_port, u_nas),
  method = "itau"
)

theta_hat <- fit_clayton@estimate

cat(sprintf("Clayton copula fitted (Portfolio vs NASDAQ): theta = %.4f\n",
            theta_hat))

# 5) Lower tail dependence coefficient
lambda_L <- 2^(-1 / theta_hat)
cat(sprintf("Lower tail dependence (lambda_L): %.4f\n", lambda_L))
cat("Interpretation: probability that the portfolio is also in a very bad month\n")
cat("conditional on the NASDAQ being in its worst months.\n\n")

# 6) Linear correlation vs copula tail dependence
corr_port_nas <- cor(port_clean, nas_clean, use = "complete.obs")
cat(sprintf("Linear correlation (Portfolio, NASDAQ): %.4f\n", corr_port_nas))
cat("Difference: correlation measures average co-movement,\n")
cat("while the copula focuses on joint extreme downside moves.\n\n")

# 7) Copula summary table
copula_summary <- data.frame(
  Metric = c(
    "Linear correlation",
    "Clayton theta",
    "Lower tail dependence (lambda_L)"
  ),
  Value = c(corr_port_nas, theta_hat, lambda_L)
)
copula_summary$Value <- round(copula_summary$Value, 4)

cat("PORTFOLIO vs NASDAQ – DEPENDENCE SUMMARY\n")
print(copula_summary)
cat("\n")

write.csv(copula_summary, "copula_portfolio_nasdaq_summary.csv", row.names = FALSE)

# 8) Copula scatter plot
copula_df <- data.frame(
  U_Portfolio = u_port,
  U_NASDAQ    = u_nas
)

p_copula <- ggplot(copula_df, aes(x = U_Portfolio, y = U_NASDAQ)) +
  geom_point(alpha = 0.4, size = 1.2, color = "#3498db") +
  labs(
    title = "Copula Scatter – Portfolio vs NASDAQ (Empirical U(0,1))",
    x     = "U(Portfolio) – Rank-based CDF",
    y     = "U(NASDAQ) – Rank-based CDF"
  ) +
  theme_minimal()

ggsave("04_copula_portfolio_nasdaq.png", p_copula,
       width = 7, height = 6, dpi = 300)
cat("  ✓ Saved: 04_copula_portfolio_nasdaq.png\n\n")

# ============================================================================
# 6. VALUE AT RISK – METHOD 1: HISTORICAL SIMULATION
# ============================================================================

cat("STEP 3: VALUE AT RISK ESTIMATION\n")
cat("-" %+% strrep("-", 76) %+% "-\n")
cat("Method 1: Historical Simulation (Non-Parametric)\n")
cat("Using empirical quantiles of the observed return distribution.\n\n")

# Portfolio historical VaR / ES
var_95_histo <- quantile(portfolio_returns_clean, probs = 0.05, na.rm = TRUE)
var_99_histo <- quantile(portfolio_returns_clean, probs = 0.01, na.rm = TRUE)

es_95_histo <- mean(
  portfolio_returns_clean[portfolio_returns_clean <= var_95_histo],
  na.rm = TRUE
)
es_99_histo <- mean(
  portfolio_returns_clean[portfolio_returns_clean <= var_99_histo],
  na.rm = TRUE
)

cat("PORTFOLIO – HISTORICAL VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_histo))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_histo))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_histo))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_histo))

# NASDAQ historical VaR / ES
var_95_nasdaq <- quantile(nasdaq_returns_clean, probs = 0.05, na.rm = TRUE)
var_99_nasdaq <- quantile(nasdaq_returns_clean, probs = 0.01, na.rm = TRUE)

es_95_nasdaq <- mean(
  nasdaq_returns_clean[nasdaq_returns_clean <= var_95_nasdaq],
  na.rm = TRUE
)
es_99_nasdaq <- mean(
  nasdaq_returns_clean[nasdaq_returns_clean <= var_99_nasdaq],
  na.rm = TRUE
)

cat("NASDAQ – HISTORICAL VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_nasdaq))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_nasdaq))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_nasdaq))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_nasdaq))

# ============================================================================
# 7. VALUE AT RISK – METHOD 2: PARAMETRIC (NORMAL)
# ============================================================================

cat("Method 2: Parametric (Normal Distribution Assumption)\n")
cat("Assumes returns follow a normal distribution.\n\n")

# Z-scores for 95% and 99%
z_95 <- 1.645
z_99 <- 2.326

# Portfolio parametric VaR
var_95_param <- mean_return - z_95 * std_dev
var_99_param <- mean_return - z_99 * std_dev

# ES formula under normality: ES = μ - σ * φ(z) / α
phi_95 <- dnorm(z_95)
phi_99 <- dnorm(z_99)

es_95_param <- mean_return - std_dev * phi_95 / 0.05
es_99_param <- mean_return - std_dev * phi_99 / 0.01

cat("PORTFOLIO – PARAMETRIC VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_param))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_param))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_param))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_param))

# NASDAQ parametric VaR / ES
var_95_param_nasdaq <- mean_nasdaq - z_95 * std_nasdaq
var_99_param_nasdaq <- mean_nasdaq - z_99 * std_nasdaq

es_95_param_nasdaq <- mean_nasdaq - std_nasdaq * phi_95 / 0.05
es_99_param_nasdaq <- mean_nasdaq - std_nasdaq * phi_99 / 0.01

cat("NASDAQ – PARAMETRIC VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_param_nasdaq))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_param_nasdaq))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_param_nasdaq))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_param_nasdaq))

# ============================================================================
# 8. VALUE AT RISK – METHOD 3: MONTE CARLO SIMULATION
# ============================================================================

cat("Method 3: Monte Carlo Simulation\n")
cat(sprintf("Simulating %d one-month returns from the parametric model.\n\n",
            MC_SIMULATIONS))

set.seed(MC_SEED)

# Portfolio MC simulation
simulated_returns <- rnorm(MC_SIMULATIONS,
                           mean = mean_return,
                           sd   = std_dev)

var_95_mc <- quantile(simulated_returns, probs = 0.05)
var_99_mc <- quantile(simulated_returns, probs = 0.01)

es_95_mc <- mean(simulated_returns[simulated_returns <= var_95_mc])
es_99_mc <- mean(simulated_returns[simulated_returns <= var_99_mc])

cat("PORTFOLIO – MONTE CARLO VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_mc))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_mc))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_mc))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_mc))

# NASDAQ MC simulation
simulated_nasdaq <- rnorm(MC_SIMULATIONS,
                          mean = mean_nasdaq,
                          sd   = std_nasdaq)

var_95_mc_nasdaq <- quantile(simulated_nasdaq, probs = 0.05)
var_99_mc_nasdaq <- quantile(simulated_nasdaq, probs = 0.01)

es_95_mc_nasdaq <- mean(simulated_nasdaq[simulated_nasdaq <= var_95_mc_nasdaq])
es_99_mc_nasdaq <- mean(simulated_nasdaq[simulated_nasdaq <= var_99_mc_nasdaq])

cat("NASDAQ – MONTE CARLO VaR / ES\n")
cat(sprintf("  VaR(95%%, 1-month):  %8.4f %%\n", var_95_mc_nasdaq))
cat(sprintf("  VaR(99%%, 1-month):  %8.4f %%\n", var_99_mc_nasdaq))
cat(sprintf("  ES(95%%, 1-month):   %8.4f %%\n", es_95_mc_nasdaq))
cat(sprintf("  ES(99%%, 1-month):   %8.4f %%\n\n", es_99_mc_nasdaq))

# ============================================================================
# 9. DRAWDOWN ANALYSIS
# ============================================================================

cat("STEP 4: MAXIMUM DRAWDOWN ANALYSIS\n")
cat("-" %+% strrep("-", 76) %+% "-\n")

# Portfolio drawdown
cumulative_wealth <- cumprod(1 + portfolio_returns / 100)
running_max       <- cummax(cumulative_wealth)
drawdown          <- (cumulative_wealth - running_max) / running_max * 100
max_dd            <- min(drawdown, na.rm = TRUE)

max_dd_idx  <- which.min(drawdown)
max_dd_date <- as.character(index(returns_matrix)[max_dd_idx])

cat("PORTFOLIO DRAWDOWN METRICS\n")
cat(sprintf("  Maximum Drawdown:       %8.2f %%\n", max_dd))
cat(sprintf("  Date of Max Drawdown:   %s\n\n", max_dd_date))

# NASDAQ drawdown
cumulative_nasdaq <- cumprod(1 + nasdaq_returns / 100)
running_max_nasdaq <- cummax(cumulative_nasdaq)
drawdown_nasdaq    <- (cumulative_nasdaq - running_max_nasdaq) / running_max_nasdaq * 100
max_dd_nasdaq      <- min(drawdown_nasdaq, na.rm = TRUE)

max_dd_idx_nas  <- which.min(drawdown_nasdaq)
max_dd_date_nas <- as.character(index(returns_matrix)[max_dd_idx_nas])

cat("NASDAQ DRAWDOWN METRICS\n")
cat(sprintf("  Maximum Drawdown:       %8.2f %%\n", max_dd_nasdaq))
cat(sprintf("  Date of Max Drawdown:   %s\n\n", max_dd_date_nas))


# ============================================================================
# DRAWDOWN COMPARISON: NASDAQ vs PORTFOLIO (20% THRESHOLD)
# ============================================================================

cat("STEP X: DRAWDOWN COMPARISON ANALYSIS\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# ============ CREATE ALIGNED DRAWDOWN DATA ============
drawdown_comparison_df <- data.frame(
  Date                  = index(returns_matrix),  
  Portfolio_Drawdown    = as.numeric(drawdown),
  NASDAQ_Drawdown       = as.numeric(drawdown_nasdaq)
)

# Keep only rows with complete data (inner join)
drawdown_comparison_df <- drawdown_comparison_df[
  !is.na(drawdown_comparison_df$Portfolio_Drawdown) & 
    !is.na(drawdown_comparison_df$NASDAQ_Drawdown), 
]

cat("Drawdown data alignment:\n")
cat(sprintf("  Total valid date pairs: %d\n", nrow(drawdown_comparison_df)))
cat(sprintf("  Date range: %s to %s\n\n", 
            min(drawdown_comparison_df$Date), 
            max(drawdown_comparison_df$Date)))

# ============ CASE 1: NASDAQ Drawdown > Portfolio Drawdown + 20% ============
drawdown_nasdaq_worse <- drawdown_comparison_df[
  (drawdown_comparison_df$NASDAQ_Drawdown - 
     drawdown_comparison_df$Portfolio_Drawdown) >= 20,
]

drawdown_nasdaq_worse <- drawdown_nasdaq_worse %>%
  mutate(
    Difference = round(NASDAQ_Drawdown - Portfolio_Drawdown, 2),
    Portfolio_Drawdown = round(Portfolio_Drawdown, 2),
    NASDAQ_Drawdown = round(NASDAQ_Drawdown, 2)
  ) %>%
  select(Date, Portfolio_Drawdown, NASDAQ_Drawdown, Difference)

write.csv(drawdown_nasdaq_worse, 
          "drawdown_nasdaq_worse_than_portfolio_20pct.csv", 
          row.names = FALSE)

cat("CASE 1: NASDAQ Drawdown ≥ Portfolio Drawdown + 20%\n")
cat(sprintf("  Months found: %d\n", nrow(drawdown_nasdaq_worse)))
if (nrow(drawdown_nasdaq_worse) > 0) {
  cat("  Sample:\n")
  print(head(drawdown_nasdaq_worse, 10))
} else {
  cat("  (No observations)\n")
}
cat("  ✓ Exported: drawdown_nasdaq_worse_than_portfolio_20pct.csv\n\n")

# ============ CASE 2: PORTFOLIO Drawdown > NASDAQ Drawdown + 20% ============
drawdown_portfolio_worse <- drawdown_comparison_df[
  (drawdown_comparison_df$Portfolio_Drawdown - 
     drawdown_comparison_df$NASDAQ_Drawdown) >= 20,
]

drawdown_portfolio_worse <- drawdown_portfolio_worse %>%
  mutate(
    Difference = round(Portfolio_Drawdown - NASDAQ_Drawdown, 2),
    Portfolio_Drawdown = round(Portfolio_Drawdown, 2),
    NASDAQ_Drawdown = round(NASDAQ_Drawdown, 2)
  ) %>%
  select(Date, Portfolio_Drawdown, NASDAQ_Drawdown, Difference)

write.csv(drawdown_portfolio_worse, 
          "drawdown_portfolio_worse_than_nasdaq_20pct.csv", 
          row.names = FALSE)

cat("CASE 2: Portfolio Drawdown ≥ NASDAQ Drawdown + 20%\n")
cat(sprintf("  Months found: %d\n", nrow(drawdown_portfolio_worse)))
if (nrow(drawdown_portfolio_worse) > 0) {
  cat("  Sample:\n")
  print(head(drawdown_portfolio_worse, 10))
} else {
  cat("  (No observations)\n")
}
cat("  ✓ Exported: drawdown_portfolio_worse_than_nasdaq_20pct.csv\n\n")

# ============ SUMMARY TABLE ============
drawdown_summary <- data.frame(
  Comparison = c(
    "NASDAQ Drawdown > Portfolio + 20%",
    "Portfolio Drawdown > NASDAQ + 20%"
  ),
  Months_Count = c(
    nrow(drawdown_nasdaq_worse),
    nrow(drawdown_portfolio_worse)
  )
)

write.csv(drawdown_summary, 
          "drawdown_comparison_summary.csv", 
          row.names = FALSE)

cat("SUMMARY: DRAWDOWN COMPARISON (20% THRESHOLD)\n")
print(drawdown_summary)
cat("\n  ✓ Exported: drawdown_comparison_summary.csv\n\n")

# ============================================================================
# ZERO DRAWDOWN PERIODS: RECOVERY ANALYSIS
# ============================================================================

cat("STEP X: ZERO DRAWDOWN PERIODS ANALYSIS\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# ============ FIND DATES WHERE BOTH DRAWDOWNS = 0 ============
zero_drawdown_both <- drawdown_comparison_df[
  drawdown_comparison_df$Portfolio_Drawdown == 0 &
    drawdown_comparison_df$NASDAQ_Drawdown == 0,
]

zero_drawdown_both_sorted <- zero_drawdown_both %>%
  arrange(Date) %>%
  mutate(
    Portfolio_Drawdown = round(Portfolio_Drawdown, 2),
    NASDAQ_Drawdown = round(NASDAQ_Drawdown, 2)
  )

write.csv(zero_drawdown_both_sorted, 
          "zero_drawdown_both_portfolio_nasdaq.csv", 
          row.names = FALSE)

cat("Dates where BOTH Portfolio & NASDAQ Drawdown = 0:\n")
cat(sprintf("  Total months found: %d\n", nrow(zero_drawdown_both_sorted)))
if (nrow(zero_drawdown_both_sorted) > 0) {
  cat("  Complete list:\n")
  print(zero_drawdown_both_sorted)
} else {
  cat("  (No observations)\n")
}
cat("  ✓ Exported: zero_drawdown_both_portfolio_nasdaq.csv\n\n")


# ============================================================================
# RECOVERY ANALYSIS: MAX GAP BETWEEN ZERO DRAWDOWN PERIODS
# ============================================================================

cat("STEP X BIS: MAXIMUM RECOVERY TIME ANALYSIS\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# FUNCTION to find max gap for one series
find_max_gap <- function(zero_dates_series, asset_name) {
  
  if (length(zero_dates_series) <= 1) {
    cat(sprintf("%s: Only %d zero drawdown period(s) – gap analysis N/A\n\n", 
                asset_name, length(zero_dates_series)))
    return(NULL)
  }
  
  # Calculate gaps in MONTHS (exact, not approximate)
  n <- length(zero_dates_series)
  gaps_months <- rep(NA, n - 1)
  
  for (i in 1:(n - 1)) {
    date1 <- zero_dates_series[i]
    date2 <- zero_dates_series[i + 1]
    
    months_diff <- (year(date2) - year(date1)) * 12 + 
      (month(date2) - month(date1))
    gaps_months[i] <- months_diff
  }
  
  # Find max gap
  max_gap_months <- max(gaps_months, na.rm = TRUE)
  max_gap_idx <- which.max(gaps_months)
  
  date_start <- zero_dates_series[max_gap_idx]
  date_end <- zero_dates_series[max_gap_idx + 1]
  
  result <- data.frame(
    Asset = asset_name,
    Max_Gap_Months = max_gap_months,
    Date_Start = as.character(date_start),
    Date_End = as.character(date_end),
    stringsAsFactors = FALSE
  )
  
  return(result)
}

# Get zero drawdown dates for each asset separately
# Portfolio: dates where PORTFOLIO drawdown = 0
portfolio_zero_idx <- drawdown_comparison_df$Portfolio_Drawdown == 0
portfolio_zero_dates <- drawdown_comparison_df$Date[portfolio_zero_idx]

# NASDAQ: dates where NASDAQ drawdown = 0
nasdaq_zero_idx <- drawdown_comparison_df$NASDAQ_Drawdown == 0
nasdaq_zero_dates <- drawdown_comparison_df$Date[nasdaq_zero_idx]

# Find max gaps
portfolio_result <- find_max_gap(portfolio_zero_dates, "Portfolio")
nasdaq_result <- find_max_gap(nasdaq_zero_dates, "NASDAQ")

# Combine results
if (!is.null(portfolio_result) && !is.null(nasdaq_result)) {
  recovery_comparison <- rbind(portfolio_result, nasdaq_result)
  
  cat("MAXIMUM RECOVERY TIME: Longest period between zero drawdown dates\n")
  print(recovery_comparison)
  cat("\n")
  
  write.csv(recovery_comparison, 
            "recovery_max_gap_comparison.csv", 
            row.names = FALSE)
  
  cat("  ✓ Exported: recovery_max_gap_comparison.csv\n\n")
}

# ============================================================================
# 10. SUMMARY TABLES: RISK METRICS & PERFORMANCE
# ============================================================================

cat("STEP 5: COMPREHENSIVE RISK & PERFORMANCE SUMMARY\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# Portfolio risk metrics summary
summary_table_port <- data.frame(
  Metric      = c("VaR (95%)", "VaR (99%)", "ES (95%)", "ES (99%)", "Max Drawdown"),
  Historical  = c(var_95_histo, var_99_histo, es_95_histo, es_99_histo, max_dd),
  Parametric  = c(var_95_param, var_99_param, es_95_param, es_99_param, max_dd),
  Monte_Carlo = c(var_95_mc,    var_99_mc,    es_95_mc,    es_99_mc,    max_dd)
)

cat("PORTFOLIO – RISK METRICS SUMMARY\n")
summary_table_port_rounded <- summary_table_port
summary_table_port_rounded[, -1] <- round(summary_table_port[, -1], 4)
print(summary_table_port_rounded)
cat("\n")

# NASDAQ risk metrics summary
summary_table_nasdaq <- data.frame(
  Metric      = c("VaR (95%)", "VaR (99%)", "ES (95%)", "ES (99%)", "Max Drawdown"),
  Historical  = c(var_95_nasdaq, var_99_nasdaq, es_95_nasdaq, es_99_nasdaq, max_dd_nasdaq),
  Parametric  = c(var_95_param_nasdaq, var_99_param_nasdaq,
                  es_95_param_nasdaq, es_99_param_nasdaq, max_dd_nasdaq),
  Monte_Carlo = c(var_95_mc_nasdaq, var_99_mc_nasdaq,
                  es_95_mc_nasdaq, es_99_mc_nasdaq, max_dd_nasdaq)
)

cat("NASDAQ – RISK METRICS SUMMARY (% Monthly)\n\n")
summary_table_nasdaq_rounded <- summary_table_nasdaq
summary_table_nasdaq_rounded[, -1] <- round(summary_table_nasdaq[, -1], 4)
print(summary_table_nasdaq_rounded)
cat("\n")

# Performance comparison
portfolio_cumulative <- (prod(1 + portfolio_returns / 100, na.rm = TRUE) - 1) * 100
nasdaq_cumulative    <- (prod(1 + nasdaq_returns   / 100, na.rm = TRUE) - 1) * 100

# Compute Sortino ratio (need downside deviation)
downside_dev_port <- sqrt(mean(pmin(portfolio_returns_clean, 0)^2, na.rm = TRUE))
downside_dev_nas  <- sqrt(mean(pmin(nasdaq_returns_clean, 0)^2, na.rm = TRUE))

sortino_port <- ifelse(downside_dev_port > 0, (mean_return * 12) / downside_dev_port, NA)
sortino_nas  <- ifelse(downside_dev_nas > 0,  (mean_nasdaq * 12) / downside_dev_nas,  NA)

performance_comparison <- data.frame(
  Metric = c(
    "Cumulative Return (%)",
    "Annualized Return (%)",
    "Annualized Volatility (%)",
    "Skewness",
    "Excess Kurtosis",
    "Max Drawdown (%)",
    "Sharpe Ratio (Rf = 0%)",
    "Sortino Ratio (Rf = 0%)"
  ),
  Portfolio = c(
    round(portfolio_cumulative,                           2),
    round(mean_return * 12,                               2),
    round(std_dev * sqrt(12),                             2),
    round(skewness_port,                                  4),
    round(kurtosis_port - 3,                              4),
    round(max_dd,                                         2),
    round((mean_return * 12) / (std_dev * sqrt(12)),      4),
    round(sortino_port,                                   4)
  ),
  NASDAQ = c(
    round(nasdaq_cumulative,                              2),
    round(mean_nasdaq * 12,                               2),
    round(std_nasdaq * sqrt(12),                          2),
    round(skewness_nas,                                   4),
    round(kurtosis_nas - 3,                               4),
    round(max_dd_nasdaq,                                  2),
    round((mean_nasdaq * 12) / (std_nasdaq * sqrt(12)),   4),
    round(sortino_nas,                                    4)
  )
)

cat("PORTFOLIO vs NASDAQ – PERFORMANCE COMPARISON\n\n")
print(performance_comparison)
cat("\n")

# ============================================================================
# 11.BIS STRESS TESTING: TECH CRASH & RATE SHOCK
# ============================================================================

cat("STEP 6 BIS: STRESS TESTING – TECH CRASH & RATE SHOCK\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# Base case (historical)
base_returns <- as.numeric(portfolio_returns_clean)

base_var_95 <- quantile(base_returns, 0.05, na.rm = TRUE)
base_es_95  <- mean(base_returns[base_returns <= base_var_95], na.rm = TRUE)
base_var_99 <- quantile(base_returns, 0.01, na.rm = TRUE)
base_es_99  <- mean(base_returns[base_returns <= base_var_99], na.rm = TRUE)

cat("BASE CASE – Historical Portfolio Returns\n")
cat(sprintf("  VaR(95%%): %.2f %% | ES(95%%): %.2f %%\n", base_var_95, base_es_95))
cat(sprintf("  VaR(99%%): %.2f %% | ES(99%%): %.2f %%\n\n", base_var_99, base_es_99))

mu_base <- mean(base_returns, na.rm = TRUE)
sd_base <- sd(base_returns,   na.rm = TRUE)
n_base  <- length(base_returns)

cat(sprintf("Base mean (monthly): %.2f %% | Base vol (monthly): %.2f %%\n\n",
            mu_base, sd_base))

set.seed(123)

# Scenario 1: Tech Crash (amplified moves)
cat("SCENARIO 1: TECH CRASH (amplified moves)\n")
cat("  Hypothesis: all moves are 50% more extreme (especially drawdowns).\n\n")

stress_tech <- base_returns * 1.5

var95_tech <- quantile(stress_tech, 0.05, na.rm = TRUE)
es95_tech  <- mean(stress_tech[stress_tech <= var95_tech], na.rm = TRUE)
var99_tech <- quantile(stress_tech, 0.01, na.rm = TRUE)
es99_tech  <- mean(stress_tech[stress_tech <= var99_tech], na.rm = TRUE)

cat(sprintf("  VaR(95%%): %.2f %% | ES(95%%): %.2f %%\n", var95_tech, es95_tech))
cat(sprintf("  VaR(99%%): %.2f %% | ES(99%%): %.2f %%\n\n", var99_tech, es99_tech))

# Scenario 2: Rate Shock (moderate but persistent tightening)
cat("SCENARIO 2: RATE SHOCK (moderate but persistent tightening)\n")
cat("  Hypothesis: monthly mean -0.5 point, volatility x1.3.\n\n")

stress_rate <- rnorm(
  n    = n_base,
  mean = mu_base - 0.5,      # lower mean (valuation pressure)
  sd   = sd_base * 1.3       # moderately higher volatility
)

var95_rate <- quantile(stress_rate, 0.05, na.rm = TRUE)
es95_rate  <- mean(stress_rate[stress_rate <= var95_rate], na.rm = TRUE)
var99_rate <- quantile(stress_rate, 0.01, na.rm = TRUE)
es99_rate  <- mean(stress_rate[stress_rate <= var99_rate], na.rm = TRUE)

cat(sprintf("  VaR(95%%): %.2f %% | ES(95%%): %.2f %%\n", var95_rate, es95_rate))
cat(sprintf("  VaR(99%%): %.2f %% | ES(99%%): %.2f %%\n\n", var99_rate, es99_rate))

# Stress scenario summary
stress_summary <- data.frame(
  Scenario = c(
    "Base (historical)",
    "Tech Crash (x1.5)",
    "Rate Shock (mean-0.5, vol x1.3)"
  ),
  VaR_95 = c(base_var_95, var95_tech, var95_rate),
  ES_95  = c(base_es_95,  es95_tech,  es95_rate),
  VaR_99 = c(base_var_99, var99_tech, var99_rate),
  ES_99  = c(base_es_99,  es99_tech,  es99_rate)
)

stress_summary_round <- stress_summary
stress_summary_round[, -1] <- round(stress_summary[, -1], 2)

cat("STRESS SCENARIOS – RISK METRICS SUMMARY (% Monthly)\n")
print(stress_summary_round)
cat("\n")

write.csv(stress_summary_round, "stress_scenarios_summary.csv",
          row.names = FALSE)
cat("  ✓ Exported: stress_scenarios_summary.csv\n\n")

# ============================================================================
# 11.BIS SHARPE RATIOS & RISK DECOMPOSITION
# ============================================================================

cat("STEP 8: SHARPE RATIOS & RISK DECOMPOSITION\n")
cat("-" %+% strrep("-", 76) %+% "-\n\n")

# ---------- Sharpe ratios (annualized, Rf = 0%) ----------
# Assumption: risk-free rate set to 0%.
# Justification: annualized returns of the portfolio and NASDAQ (~10–16% p.a.)
# are much higher than typical risk-free levels over the period. The goal is
# relative comparison of risk/return profiles, for which Rf ≈ 0 does not
# materially change the ranking of assets.

cat("SHARPE RATIOS (Annualized, Rf = 0%)\n")
cat("Assumption: risk-free rate = 0% (for simplicity and comparability).\n\n")

compute_stats <- function(x) {
  x    <- as.numeric(x)
  mu_m <- mean(x, na.rm = TRUE)
  sd_m <- sd(x,   na.rm = TRUE)
  mu_a <- mu_m * 12
  sd_a <- sd_m * sqrt(12)
  sharpe <- ifelse(sd_a > 0, mu_a / sd_a, NA)
  c(Monthly_Mean = mu_m, Monthly_SD = sd_m,
    Annual_Return = mu_a, Annual_Vol = sd_a, Sharpe = sharpe)
}

# Per-stock stats
stock_stats    <- t(apply(returns_matrix, 2, compute_stats))
stock_stats_df <- data.frame(
  Ticker = rownames(stock_stats),
  round(stock_stats, 4)
)
rownames(stock_stats_df) <- NULL

# Portfolio stats
port_stats    <- compute_stats(portfolio_returns_clean)
port_stats_df <- data.frame(
  Ticker = "Portfolio",
  t(round(port_stats, 4))
)

# NASDAQ stats
nas_stats    <- compute_stats(nasdaq_returns_clean)
nas_stats_df <- data.frame(
  Ticker = "NASDAQ",
  t(round(nas_stats, 4))
)

sharpe_table <- rbind(stock_stats_df, port_stats_df, nas_stats_df)

cat("ANNUALIZED RETURN / VOLATILITY / SHARPE\n")
print(sharpe_table)
cat("\n")

write.csv(sharpe_table,
          "sharpe_ratios_stocks_portfolio_nasdaq.csv",
          row.names = FALSE)
cat("  ✓ Exported: sharpe_ratios_stocks_portfolio_nasdaq.csv\n\n")

# ---------- Risk decomposition: contribution to portfolio volatility ----------

cat("RISK DECOMPOSITION – CONTRIBUTION TO PORTFOLIO VOLATILITY\n\n")

# Equal weights
w <- rep(1 / length(PORTFOLIO_TICKERS), length(PORTFOLIO_TICKERS))
names(w) <- PORTFOLIO_TICKERS

# Monthly covariance matrix between stocks
cov_mat <- cov(returns_matrix, use = "complete.obs")

# Portfolio volatility (monthly)
port_var <- var(portfolio_returns_clean, na.rm = TRUE)
port_sd  <- sqrt(port_var)

# Covariance of each stock with portfolio: Cov(i, P) = (Cov * w)_i
cov_with_port <- as.numeric(cov_mat %*% w)
names(cov_with_port) <- PORTFOLIO_TICKERS

# Marginal contribution to risk (per unit of weight)
marginal_contrib <- cov_with_port / port_sd

# Total contribution to portfolio risk (in volatility points)
total_contrib <- w * marginal_contrib

# Percentage of total portfolio volatility
percent_contrib <- (total_contrib / port_sd) * 100

risk_decomp_df <- data.frame(
  Ticker                    = PORTFOLIO_TICKERS,
  Weight                    = round(w, 4),
  Risk_Contribution_Percent = round(percent_contrib, 2)
)

cat("PORTFOLIO RISK CONTRIBUTION BY STOCK (% of total volatility)\n")
print(risk_decomp_df)
cat("\n")

write.csv(risk_decomp_df,
          "portfolio_risk_decomposition.csv",
          row.names = FALSE)
cat("  ✓ Exported: portfolio_risk_decomposition.csv\n\n")

# ============================================================================
# 12. DATA VISUALIZATION
# ============================================================================

cat("STEP 6: GENERATING VISUALIZATIONS\n")
cat("-" %+% strrep("-", 76) %+% "-\n")

# Chart 1: Return distributions with VaR/ES overlays
cat("Creating Chart 1: Return Distributions...\n")

p1 <- ggplot(
  data.frame(returns = as.numeric(portfolio_returns_clean)),
  aes(x = returns)
) +
  geom_histogram(bins = 50, fill = "#3498db", alpha = 0.7, color = "white") +
  geom_vline(aes(xintercept = var_95_histo, color = "VaR 95%"), linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = var_99_histo, color = "VaR 99%"), linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = es_95_histo, color = "ES 95%"),  linetype = "solid",  size = 1) +
  geom_vline(aes(xintercept = es_99_histo, color = "ES 99%"),  linetype = "solid",  size = 1) +
  scale_color_manual(
    values = c(
      "VaR 95%" = "#e74c3c",
      "VaR 99%" = "#c0392b",
      "ES 95%"  = "#f39c12",
      "ES 99%"  = "#d68910"
    )
  ) +
  labs(
    title = "Portfolio – Monthly Returns Distribution",
    x     = "Monthly Return (%)",
    y     = "Frequency",
    color = "Risk Metrics"
  ) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 11),
    legend.position = "right"
  )

p2 <- ggplot(
  data.frame(returns = as.numeric(nasdaq_returns_clean)),
  aes(x = returns)
) +
  geom_histogram(bins = 50, fill = "#e74c3c", alpha = 0.7, color = "white") +
  geom_vline(aes(xintercept = var_95_nasdaq, color = "VaR 95%"),
             linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = var_99_nasdaq, color = "VaR 99%"),
             linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = es_95_nasdaq, color = "ES 95%"),
             linetype = "solid",  size = 1) +
  geom_vline(aes(xintercept = es_99_nasdaq, color = "ES 99%"),
             linetype = "solid",  size = 1) +
  scale_color_manual(
    values = c(
      "VaR 95%" = "#3498db",
      "VaR 99%" = "#2874a6",
      "ES 95%"  = "#f39c12",
      "ES 99%"  = "#d68910"
    )
  ) +
  labs(
    title = "NASDAQ – Monthly Returns Distribution",
    x     = "Monthly Return (%)",
    y     = "Frequency",
    color = "Risk Metrics"
  ) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 11),
    legend.position = "right"
  )

print(p1)
print(p2)

combined_dist <- gridExtra::grid.arrange(
  p1, p2, ncol = 2,
  top = "Returns Distribution Comparison (Dec 1999 – Nov 2025)"
)

ggsave("01_distributions_combined.png", combined_dist,
       width = 16, height = 6, dpi = 300)
cat("  ✓ Saved: 01_distributions_combined.png\n")

# Chart 2: Drawdown comparison
cat("Creating Chart 2: Drawdown Comparison...\n")

drawdown_df <- data.frame(
  Date              = as.Date(index(returns_matrix)),
  Portfolio_Drawdown = as.numeric(drawdown),
  NASDAQ_Drawdown    = as.numeric(drawdown_nasdaq)
)

p_drawdown_combined <- ggplot(drawdown_df, aes(x = Date)) +
  geom_area(aes(y = Portfolio_Drawdown, fill = "Portfolio"),
            alpha = 0.25, color = NA) +
  geom_area(aes(y = NASDAQ_Drawdown,    fill = "NASDAQ"),
            alpha = 0.25, color = NA) +
  geom_line(aes(y = Portfolio_Drawdown, color = "Portfolio"),
            linewidth = 1.4, alpha = 0.95) +
  geom_line(aes(y = NASDAQ_Drawdown,    color = "NASDAQ"),
            linewidth = 1.4, alpha = 0.95) +
  scale_color_manual(
    name   = "Asset",
    values = c("Portfolio" = "#3498db", "NASDAQ" = "#e74c3c")
  ) +
  scale_fill_manual(
    name   = "Asset",
    values = c("Portfolio" = "#3498db", "NASDAQ" = "#e74c3c"),
    guide  = "none"
  ) +
  scale_x_date(
    date_labels = "%b %Y",
    date_breaks = "2 years",
    minor_breaks = "6 months"
  ) +
  scale_y_continuous(
    breaks = seq(-100, 0, by = 10),
    labels = paste0(seq(-100, 0, by = 10), "%")
  ) +
  labs(
    title    = "Drawdown Comparison – Portfolio vs NASDAQ",
    subtitle = "Cumulative Loss from Peak (Dec 1999 – Nov 2025)",
    x        = "Year",
    y        = "Drawdown (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title        = element_text(face = "bold", size = 16, margin = margin(b = 10)),
    plot.subtitle     = element_text(size = 12, margin = margin(b = 15)),
    panel.background  = element_rect(fill = "#f5f5f5", color = NA),
    plot.background   = element_rect(fill = "white", color = NA),
    panel.grid.major.y = element_line(color = "white", linewidth = 0.8),
    panel.grid.major.x = element_line(color = "white", linewidth = 0.5),
    legend.position   = "top",
    axis.text.x       = element_text(angle = 45, hjust = 1, vjust = 1,
                                     size = 12, face = "bold")
  )

print(p_drawdown_combined)

ggsave("02_drawdown_comparison.png", p_drawdown_combined,
       width = 16, height = 9, dpi = 300)
cat("  ✓ Saved: 02_drawdown_comparison.png\n\n")

# ============================================================================
# 13. DATA EXPORT TO CSV
# ============================================================================

cat("STEP 7: EXPORTING DATA TO CSV\n")
cat("-" %+% strrep("-", 76) %+% "-\n")

# Export 1: Risk metrics summary
portfolio_risk_metrics <- data.frame(
  Metric = c(
    "Mean Return (%)", "Std Dev (%)",
    "Annualized Return (%)", "Annualized Volatility (%)",
    "VaR 95% Hist", "VaR 99% Hist",
    "VaR 95% Param", "VaR 99% Param",
    "VaR 95% MC", "VaR 99% MC",
    "ES 95% Hist", "ES 99% Hist",
    "ES 95% Param", "ES 99% Param",
    "ES 95% MC", "ES 99% MC",
    "Max Drawdown"
  ),
  Portfolio = c(
    round(mean_return,              4),
    round(std_dev,                  4),
    round(mean_return * 12,         4),
    round(std_dev * sqrt(12),       2),
    round(var_95_histo,             4),
    round(var_99_histo,             4),
    round(var_95_param,             4),
    round(var_99_param,             4),
    round(var_95_mc,                4),
    round(var_99_mc,                4),
    round(es_95_histo,              4),
    round(es_99_histo,              4),
    round(es_95_param,              4),
    round(es_99_param,              4),
    round(es_95_mc,                 4),
    round(es_99_mc,                 4),
    round(max_dd,                   2)
  ),
  NASDAQ = c(
    round(mean_nasdaq,              4),
    round(std_nasdaq,               4),
    round(mean_nasdaq * 12,         4),
    round(std_nasdaq * sqrt(12),    2),
    round(var_95_nasdaq,            4),
    round(var_99_nasdaq,            4),
    round(var_95_param_nasdaq,      4),
    round(var_99_param_nasdaq,      4),
    round(var_95_mc_nasdaq,         4),
    round(var_99_mc_nasdaq,         4),
    round(es_95_nasdaq,             4),
    round(es_99_nasdaq,             4),
    round(es_95_param_nasdaq,       4),
    round(es_99_param_nasdaq,       4),
    round(es_95_mc_nasdaq,          4),
    round(es_99_mc_nasdaq,          4),
    round(max_dd_nasdaq,            2)
  )
)
write.csv(portfolio_risk_metrics, "risk_metrics_summary.csv", row.names = FALSE)
cat("  ✓ Exported: risk_metrics_summary.csv\n")

# Export 2: Monthly returns (portfolio + NASDAQ)
monthly_returns_export <- data.frame(
  Date             = index(returns_matrix),
  Portfolio_Return = round(as.numeric(portfolio_returns_clean), 4),
  NASDAQ_Return    = round(as.numeric(nasdaq_returns_clean),    4)
)
write.csv(monthly_returns_export, "monthly_returns.csv", row.names = FALSE)
cat("  ✓ Exported: monthly_returns.csv\n")

# Export 3: Drawdown over time
drawdown_export <- data.frame(
  Date              = index(returns_matrix),
  Portfolio_Drawdown = round(as.numeric(drawdown),        2),
  NASDAQ_Drawdown    = round(as.numeric(drawdown_nasdaq), 2)
)
write.csv(drawdown_export, "drawdown_over_time.csv", row.names = FALSE)
cat("  ✓ Exported: drawdown_over_time.csv\n")

# Export 4: Wealth index
wealth_export <- data.frame(
  Date                   = index(returns_matrix),
  Portfolio_Wealth_Index = round(as.numeric(cumulative_wealth), 4),
  NASDAQ_Wealth_Index    = round(as.numeric(cumulative_nasdaq),  4)
)
write.csv(wealth_export, "wealth_index.csv", row.names = FALSE)
cat("  ✓ Exported: wealth_index.csv\n")

# Export 5: Individual stock performance (cumulative)
individual_stocks <- data.frame(
  Ticker                    = PORTFOLIO_TICKERS,
  Cumulative_Return_Percent = NA,
  Wealth_Multiple           = NA
)

for (i in seq_along(PORTFOLIO_TICKERS)) {
  stock_returns    <- returns_matrix[, PORTFOLIO_TICKERS[i]]
  cumulative_return <- (prod(1 + stock_returns / 100, na.rm = TRUE) - 1) * 100
  wealth_multiple   <- prod(1 + stock_returns / 100, na.rm = TRUE)
  individual_stocks$Cumulative_Return_Percent[i] <- round(cumulative_return, 2)
  individual_stocks$Wealth_Multiple[i]           <- round(wealth_multiple,   2)
}

write.csv(individual_stocks, "individual_stocks_performance.csv",
          row.names = FALSE)
cat("  ✓ Exported: individual_stocks_performance.csv\n")

# Export 6: Portfolio vs NASDAQ comparison
portfolio_vs_nasdaq <- data.frame(
  Metric = c(
    "Cumulative Return (%)",
    "Wealth Multiple",
    "Annualized Return (%)",
    "Annualized Volatility (%)",
    "Max Drawdown (%)"
  ),
  Portfolio = c(
    round((prod(1 + portfolio_returns / 100, na.rm = TRUE) - 1) * 100, 2),
    round(prod(1 + portfolio_returns / 100, na.rm = TRUE), 2),
    round(mean_return * 12, 2),
    round(std_dev * sqrt(12), 2),
    round(max_dd, 2)
  ),
  NASDAQ = c(
    round((prod(1 + nasdaq_returns / 100, na.rm = TRUE) - 1) * 100, 2),
    round(prod(1 + nasdaq_returns / 100, na.rm = TRUE), 2),
    round(mean_nasdaq * 12, 2),
    round(std_nasdaq * sqrt(12), 2),
    round(max_dd_nasdaq, 2)
  )
)
write.csv(portfolio_vs_nasdaq, "portfolio_vs_nasdaq_comparison.csv",
          row.names = FALSE)
cat("  ✓ Exported: portfolio_vs_nasdaq_comparison.csv\n\n")

# ============================================================================
# 14. EXECUTION SUMMARY
# ============================================================================

cat("=" %+% strrep("=", 78) %+% "=\n")
cat("ANALYSIS COMPLETE\n")
cat("=" %+% strrep("=", 78) %+% "=\n")
cat("\nExecution Summary:\n")
cat(sprintf("  Period Analyzed:    %d months (%.2f years)\n",
            nrow(returns_matrix), nrow(returns_matrix) / 12))
cat(sprintf("  Portfolio Stocks:   %s\n",
            paste(PORTFOLIO_TICKERS, collapse = ", ")))
cat(sprintf("  Benchmark:          %s\n", BENCHMARK_TICKER))
cat("  VaR Methods:        3 (Historical, Parametric, Monte Carlo)\n")
cat("  Advanced:           GARCH(1,1), Copula tail dependence,\n")
cat("                      Stress testing (Tech Crash, Rate Shock),\n")
cat("                      Risk decomposition, Sharpe ratios\n")
cat("  Output Files:       Multiple CSV + 4 PNG charts\n\n")
cat("All results have been exported to the working directory.\n\n")
  
