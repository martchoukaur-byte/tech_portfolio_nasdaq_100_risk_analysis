## Methodology

### Data & Portfolio Construction

Historical monthly adjusted close prices are downloaded for each of the five stocks (MSFT, INTC, CSCO, ORCL, AAPL) and the NASDAQ-100 index from November 1999 to November 2025. Discrete monthly returns are computed as percentage changes. The equal-weighted portfolio return at each month is calculated as the simple average of the five individual stock returns. Monthly rebalancing ensures that each stock maintains a 20% weight.

### Descriptive Statistics

For both the portfolio and the NASDAQ benchmark, we compute standard summary statistics:
- **Monthly mean return and standard deviation:** Basic measures of central tendency and dispersion
- **Annualized return and volatility:** Monthly figures scaled by √12 (volatility) and 12 (return)
- **Sharpe ratio:** Annualized return divided by annualized volatility, with risk-free rate set to 0% for simplicity (equity returns of 10–16% per year are much larger than typical risk-free rates, so this choice does not materially affect rankings)
- **Skewness and kurtosis:** Measures of return distribution asymmetry and tail thickness

These metrics provide a first-order comparison of risk-adjusted performance between the portfolio and benchmark.

### Value-at-Risk (VaR) and Expected Shortfall (ES)

VaR and ES quantify tail risk by estimating potential losses under adverse market conditions. Both metrics are computed at 95% and 99% confidence levels for a one-month horizon.

**VaR (Value-at-Risk):** The maximum loss expected with a given confidence level. VaR 95% means there is a 95% probability that losses will not exceed this threshold (or equivalently, a 5% probability of worse losses).

**ES (Expected Shortfall):** The average loss conditional on exceeding the VaR threshold. ES is more conservative than VaR because it accounts for the severity of losses beyond the VaR cutoff, rather than just the cutoff itself.

Three independent methodologies are employed:

**1. Historical Simulation**
- Non-parametric approach using empirical quantiles of historical returns
- VaR 95% is the 5th percentile; VaR 99% is the 1st percentile of the observed return distribution
- ES is computed as the average of all returns worse than (i.e., below) the VaR threshold
- Advantage: Makes no distributional assumptions; captures actual market behavior
- Disadvantage: Relies on historical data; assumes the past distribution represents future risk

**2. Parametric (Normal Distribution)**
- Assumes returns follow a normal distribution with mean μ and standard deviation σ
- VaR 95% = μ − 1.645·σ; VaR 99% = μ − 2.326·σ (where 1.645 and 2.326 are standard normal quantiles)
- ES is computed using the closed-form formula under normality
- Advantage: Simple, requires only mean and volatility; computationally efficient
- Disadvantage: Assumes normality, which often fails in practice (equity returns exhibit fatter tails)

**3. Monte Carlo Simulation**
- Generate 10,000 simulated monthly returns from Normal(μ, σ)
- Compute empirical VaR/ES directly from the simulated distribution
- Advantage: Flexible; can incorporate complex distributions or correlations
- Disadvantage: Computationally intensive; results depend on the assumed distribution

These three approaches provide complementary perspectives: historical simulation is data-driven, parametric is theoretically tractable, and Monte Carlo bridges both. Divergence between them signals that distributional assumptions may be inadequate.

### Drawdown Analysis

Drawdowns measure the percentage loss from the previous peak wealth to the current value, capturing the depth and timing of large losses during market dislocations.

For each month, the cumulative wealth index is computed as the compounded product of 1 + monthly returns. The running maximum is then tracked, and drawdown at each date is defined as:

Drawdown = (Current Wealth − Running Maximum) / Running Maximum × 100%

Maximum drawdown over the entire period represents the worst peak-to-trough loss experienced. Drawdown analysis is valuable because it captures duration and severity of losses that point estimates of VaR/ES alone cannot fully convey.

### GARCH(1,1) Conditional Volatility

A GARCH(1,1) model is fit to portfolio monthly returns to capture time-varying volatility (volatility clustering). Unlike static volatility, which assumes constant risk, GARCH recognizes that large price movements tend to be followed by additional large movements, creating regimes of high and low volatility.

The model is specified as:
- **Return equation:** r_t = μ + ε_t
- **Volatility equation:** σ²_t = ω + α₁·ε²_{t-1} + β₁·σ²_{t-1}

Key parameters:
- **ω (omega):** Baseline volatility floor (structural level)
- **α₁ (alpha):** Sensitivity to past shocks (immediate market reaction)
- **β₁ (beta):** Volatility persistence (how quickly the market "forgets" past shocks)

The sum α₁ + β₁ indicates volatility persistence; values close to 1 indicate long-lasting volatility clusters.

From the fitted model, we extract:
- **Monthly conditional volatility σ_t** for each observation, then annualize it by multiplying by √12
- **Average annualized volatility:** Mean of all conditional volatility estimates
- **Peak and trough volatility:** Maximum and minimum annualized volatility over the period

Plotting σ_t over time reveals high-volatility regimes (corresponding to crises: dot-com crash, 2008 financial crisis) and low-volatility regimes (calm markets). This demonstrates that static VaR models, which assume constant volatility, fundamentally misestimate risk during regime transitions.

### Copula-Based Tail Dependence

Copula analysis studies how two asset returns move together during extreme events, particularly focusing on joint downside risk (tail dependence). Linear correlation alone is insufficient because it measures average co-movement but masks extreme tail behavior.

**Method:**
- Transform portfolio and NASDAQ monthly returns into uniform U(0,1) pseudo-observations using empirical ranks (probability integral transform)
- Fit a Clayton copula to these pseudo-observations using Kendall's tau
- The Clayton copula is well-suited for equity markets because it exhibits lower-tail dependence (focus on joint downside events)

**Key metrics:**
- **Linear Correlation:** Pearson correlation between portfolio and NASDAQ returns (measures average co-movement in normal times)
- **Clayton Theta (θ):** The copula parameter; higher values indicate stronger lower-tail dependence
- **Lower Tail Dependence (λ_L):** Computed as λ_L = 2^{−1/θ}; ranges from 0 to 1
  - λ_L = 0: Assets are independent in the lower tail (no joint extreme losses)
  - λ_L = 1: Assets are perfectly dependent in the lower tail (always crash together)
  - λ_L close to correlation: Tail and average dependence are similar
  - λ_L > correlation: Tail dependence exceeds average correlation (diversification fails in crises)

**Interpretation:** A high λ_L (e.g., 0.8558) means there is an 85.58% probability that both the portfolio and NASDAQ will be in their worst months simultaneously during 1-in-100-day events. This reveals that equal-weighting within mega-cap tech provides limited hedging benefit during the crises when diversification matters most.

### Stress Scenarios

Stress testing extends historical risk analysis by examining portfolio resilience under plausible but heightened adverse conditions. Rather than assuming the worst-case scenario is a historical extreme, stress scenarios simulate how VaR and ES would evolve if market regimes became more severe than observed.

**Base Case (Historical):**
- VaR/ES computed directly from the 312-month empirical distribution of portfolio returns

**Scenario 1 – Tech Crash (Volatility × 1.5):**
- Scale all monthly portfolio returns by 1.5, simulating a 50% increase in volatility
- Calibrated to the volatility levels observed during the dot-com crash nadir (peak GARCH volatility ≈ 56.74%)
- Recompute VaR/ES on this amplified distribution
- Economic story: Pure tech sector panic, rapid deleveraging, sentiment collapse

**Scenario 2 – Rate Shock (Volatility × 1.3, Mean Return − 0.5%)**
- Simulate new returns with reduced expected return (−0.5 percentage points per month) and elevated volatility (×1.3)
- Captures the joint effect of higher interest rates (reducing the present value of future cash flows for growth stocks) and elevated market uncertainty
- Economic story: Monetary tightening cycle, sustained pressure on valuations

These scenarios illustrate how tail risk metrics respond to deteriorating market conditions beyond historical experience, revealing capital adequacy requirements for risk management.

### Sharpe Ratios & Risk Decomposition

**Sharpe Ratio Analysis:**
For each of the five stocks, the portfolio, and the NASDAQ benchmark, we compute:
- Monthly mean return and standard deviation
- Annualized return (monthly mean × 12) and volatility (monthly std dev × √12)
- Sharpe ratio = Annualized Return / Annualized Volatility (with risk-free rate = 0%)

The Sharpe ratio ranks assets by return per unit of risk, allowing comparison of risk-adjusted performance across holdings.

**Risk Decomposition:**
Using the covariance matrix of the five stocks and equal weights (20% each):
- Compute portfolio volatility: σ_p = √(w^T · Cov · w), where w is the weight vector and Cov is the covariance matrix
- For each stock i, compute its covariance with the portfolio: Cov(r_i, r_p)
- Compute the marginal contribution to risk: β_i = Cov(r_i, r_p) / σ_p
- Compute the risk contribution: RC_i = w_i · β_i
- Express as a percentage of total portfolio volatility: RC_i / σ_p × 100%

**Interpretation:** Risk contribution reveals which stocks drive portfolio volatility relative to their weights. If a stock has a 20% weight but contributes 25% of portfolio risk, it has a +5 percentage point risk premium. This analysis identifies whether high-risk holdings are justified by superior Sharpe ratios or represent uncompensated risk drag.
