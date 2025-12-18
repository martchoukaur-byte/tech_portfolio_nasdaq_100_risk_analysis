# Equal-Weight Technology Portfolio vs. NASDAQ: A 26-Year Risk and Performance Analysis

## Problematic and Motivation

The conventional assumption in portfolio management is that diversification reduces risk. This analysis examines a straightforward question: what if you had taken the five largest technology stocks as of November 1999 (MSFT, INTC, CSCO, ORCL, AAPL)—just before the dot-com bubble burst—equal-weighted them at 20% each, and rebalanced monthly for 26 years? How would this compare to simply holding the NASDAQ-100 index in terms of returns and risk?

This natural experiment tests whether mechanical equal-weighting within mega-cap tech delivers excess returns and how portfolio risk characteristics compare to a diversified benchmark across multiple market regimes (dot-com crash, financial crisis, recovery periods).

## Research Question

**Does an equal-weighted portfolio of the five largest technology stocks (as of November 1999) with monthly rebalancing outperform the NASDAQ-100 benchmark over 26 years? What are the risk and performance characteristics of each?**

---

## Methodology

- **Portfolio Construction:** Equal-weight allocation (20% each) to MSFT, INTC, CSCO, ORCL, AAPL as of November 1999
- **Rebalancing:** Monthly to maintain equal weights
- **Assumptions:** No transaction costs; no slippage; no inflation adjustment
- **Sample Period:** November 1999 – November 2025 (312 months, 26 years)
- **Benchmark:** NASDAQ-100 index
- **Risk Metrics:** VaR/ES via three independent methodologies (historical, parametric, Monte Carlo); GARCH(1,1) volatility dynamics; Clayton copula for tail dependence

---

## Results

### Portfolio Wealth and Returns

**Context:** This section tracks the cumulative growth of $1 invested in the equal-weighted portfolio versus the NASDAQ benchmark over 26 years. Portfolio rebalancing is every month and does not take into account for transaction costs. The wealth index normalizes both series to facilitate direct comparison.

#### Wealth Index Summary Table

The table below presents select snapshots across the 312-month observation period to illustrate relative growth dynamics. The full time series is available in `output/data/wealth_index.csv`.

| Date | Portfolio_Wealth_Index | NASDAQ_Wealth_Index |
|------|------------------------|---------------------|
| 104  | 1.6683                 | 0.6971              |
| 160  | 2.5818                 | 0.9794              |
| 200  | 4.5696                 | 1.5473              |
| 240  | 9.5580                 | 2.5974              |
| 280  | 14.9362                | 3.6635              |
| 312  | 27.4905                | 7.0038              |

**Key Points:**
- The Wealth Index does not account for inflation or transaction costs; it reflects only the nominal evolution of wealth
- The portfolio wealth index grows to 27.49× by month 312, compared to 7.00× for the NASDAQ-100, representing a significant outperformance over the 26-year period

#### Monthly Returns Summary Table

This table shows sample monthly return observations spanning the analysis period. The full time series is available in `output/data/monthly_returns.csv`.

| Date | Portfolio_Return | NASDAQ_Return |
|------|------------------|----------------|
| 104  | -2.2416          | 1.4204         |
| 160  | 0.9942           | 3.3963         |
| 200  | 6.5474           | 6.5968         |
| 240  | 3.0576           | 4.4994         |
| 280  | 14.9690          | 6.6900         |
| 312  | -3.5024          | -1.5143        |

Monthly returns vary substantially across the period, with both portfolio and NASDAQ experiencing positive and negative returns

---

### Performance of Individual Assets

**Context:** Understanding individual asset contributions reveals which stocks drove the most portfolio returns

#### Individual Stock Performance Summary

This table ranks each holding by cumulative return and wealth multiple over the 26-year period. Full details available in `output/data/individual_stocks_performance.csv`.

| Ticker | Cumulative Return (%) | Wealth Multiple |
|--------|----------------------|-----------------|
| MSFT   | 1665.99              | 17.66           |
| INTC   | 86.28                | 1.86            |
| CSCO   | 165.23               | 2.65            |
| ORCL   | 1385.96              | 14.86           |
| AAPL   | 37861.77             | 379.62          |

**Key Insight:** Extreme return heterogeneity across the five stocks. AAPL dominates with a wealth multiple of 379.62× while MSFT (17.66×) and ORCL (14.86×) also contribute substantially. INTC (1.86×) and CSCO (2.65×) represent significant drags. Equal-weighting captures exposure to top performers while also holding laggards. 

---

### Portfolio vs NASDAQ Benchmark

**Context:** This section compares the equal-weighted portfolio against the NASDAQ-100 index using risk and return metrics. The NASDAQ-100 index serves as the benchmark for technology-heavy portfolios.

#### Figure 1: Portfolio and NASDAQ Wealth Index Evolution

![Portfolio vs NASDAQ Wealth Index](https://github.com/user-attachments/assets/7ca0a79e-6eec-4f8d-bc9b-14761c72521d)

#### Portfolio vs NASDAQ Performance Metrics

Full comparison metrics are available in `output/data/portfolio_vs_nasdaq_comparison.csv` and `output/data/sharpe_ratios_stocks_portfolio_nasdaq.csv`.

| Metric                    | Portfolio | NASDAQ |
|---------------------------|-----------|--------|
| Cumulative Return (%)     | 2649.05   | 600.38 |
| Wealth Multiple           | 27.49     | 7.00   |
| Annualized Return (%)     | 16.04     | 9.95   |
| Annualized Volatility (%) | 25.29     | 21.95  |
| Max Drawdown (%)          | -72.24    | -75.04 |

**Finding:** The portfolio delivers 16.04% annualized returns versus 9.95% for the NASDAQ, a 6.09% advantage. Over 26 year-period, this gives Wealth Multiple of 27.49 for Portfolio versus 7.00 for NASDAQ. However, Annualized Volatility stands as higher for Portfolio compared to NASDAQ volatility. Max Drawdown value is close for both Portfolio and NASDAQ.

#### Risk-Adjusted Performance by Asset

Detailed monthly and annualized statistics for individual holdings, portfolio, and benchmark:

| Ticker    | Monthly Mean | Monthly SD | Annual Return | Annual Vol | Sharpe  |
|-----------|-------------:|-----------:|--------------:|-----------:|--------:|
| MSFT      | 1.2518       | 8.1459     | 15.0216       | 28.2183    | 0.5323  |
| INTC      | 0.7536       | 10.3545    | 9.0431        | 35.8689    | 0.2521  |
| CSCO      | 0.7526       | 9.2768     | 9.0312        | 32.1357    | 0.2810  |
| ORCL      | 1.3737       | 10.2744    | 16.4846       | 35.5915    | 0.4632  |
| AAPL      | 2.5497       | 10.8765    | 30.5963       | 37.6772    | 0.8121  |
| Portfolio | 1.3363       | 7.3016     | 16.0354       | 25.2934    | 0.6340  |
| NASDAQ    | 0.8289       | 6.3359     | 9.9473        | 21.9481    | 0.4532  |

**Analytical Insights:**
- The portfolio's Sharpe ratio (0.634) exceeds the NASDAQ benchmark (0.453), indicating superior risk-adjusted returns
- Despite higher monthly volatility (7.3% vs. 6.3%), the portfolio achieves better risk-adjusted performance
- Individual stock Sharpe ratios range from 0.2521 (INTC) to 0.8121 (AAPL), reflecting disparate risk-return profiles
- Porfolio's annuel volatility stands as lower as the volatility of each of its individual stocks. This is thanks to diversification. Nevertheless, the annual volatility of the Portfolio stands as higher compared to NASDAQ (because NADSAQ-100 is more diversified and less concentrated) 
---

### Risk and Drawdowns

**Context:** Drawdown analysis captures the peak-to-trough loss experience during market dislocations. This section examines portfolio behavior across multiple market cycles.

#### Figure 2: Portfolio and NASDAQ Drawdowns Over Time

![Drawdown Comparison Chart](https://github.com/user-attachments/assets/4bf7d781-3bba-440a-9ef6-752ba4e79c7b)

This visualization displays cumulative drawdowns from peak wealth for both the portfolio and NASDAQ index across all 312 months. In the chart, this is very clear that the Portfolio's wealth recovers more quickly after 2000 and 2008 drawdowns compared to NASDAQ.

#### Drawdown Sample Observations

Representative drawdown snapshots illustrating portfolio behavior across periods. Full time series available in `output/data/drawdown_over_time.csv`.

| Date | Portfolio_Drawdown (%) | NASDAQ_Drawdown (%) |
|------|------------------------|---------------------|
| 1    | 0.00                   | 0.00                |
| 10   | -33.02                 | -21.80              |
| 22   | -66.88                 | -68.09              |
| 34   | -72.24                 | -75.04              |
| 96   | -8.01                  | -43.34              |
| 150  | -10.60                 | -39.80              |
| 274  | -33.27                 | -32.40              |
| 312  | -3.50                  | -1.51               |

**Key Observations:**
- At date 34, the portfolio reaches maximum drawdown of -72.24% versus NASDAQ's -75.04%, a difference of 2.80 percentage points
- At date 22, the portfolio drawdown is -66.88% versus NASDAQ's -68.09%, showing near-parity during crisis stress
- At date 96 and 150, the portfolio drawdown is less severe (-8.01% and -10.60%) compared to NASDAQ (-43.34% and -39.80%), indicating faster recovery after crisis timing

#### Risk Metrics Summary

The following table consolidates risk statistics computed using three methodologies: historical simulation, parametric (normal distribution), and Monte Carlo simulation.

| Metric                  | Portfolio | NASDAQ   |
|-------------------------|-----------|----------|
| Mean Return (%)         | 1.3363    | 0.8289   |
| Std Dev (%)             | 7.3016    | 6.3359   |
| Annualized Return (%)   | 16.0354   | 9.9473   |
| Annualized Volatility (%)| 25.29     | 21.95    |
| VaR 95% Hist            | -10.996   | -9.9971  |
| VaR 99% Hist            | -15.6616  | -16.8287 |
| VaR 95% Param           | -10.6748  | -9.5936  |
| VaR 99% Param           | -15.6472  | -13.9083 |
| VaR 95% MC              | -10.9537  | -9.7358  |
| VaR 99% MC              | -15.8156  | -13.8265 |
| ES 95% Hist             | -15.3165  | -13.9514 |
| ES 99% Hist             | -21.0015  | -20.0026 |
| ES 95% Param            | -13.7211  | -12.237  |
| ES 99% Param            | -18.1397  | -16.0712 |
| ES 95% MC               | -13.8581  | -12.3535 |
| ES 99% MC               | -18.0703  | -16.1596 |
| Max Drawdown            | -72.24    | -75.04   |

**Risk Metric Interpretation:**
- At 95% confidence, portfolio VaR ranges from -10.996% (historical) to -10.675% (parametric) versus NASDAQ's -9.997% to -9.594%, indicating ~1% higher downside risk for the portfolio
 - At 99% confidence, portfolio VaR ranges from --21.002% (historical) to -13.721% (parametric) versus NASDAQ's -20.003% to -12.237%, indicating ~1,5% parametric higher downside risk for the portfolio and none based upon historic value 
- Expected Shortfall (ES) is consistently more severe than VaR, averaging losses beyond the VaR threshold
- Historical ES and VaR are more severe than parametric/Monte Carlo ES and VaR, indicating empirical returns exhibit fatter tails than normal distribution assumptions
---

### Volatility Modelling and Risk Decomposition

**Context:** Static volatility estimates mask the time-varying nature of market risk. GARCH (Generalized Autoregressive Conditional Heteroskedasticity) models capture volatility clustering—the empirical observation that large price movements tend to be followed by additional large movements.

#### Figure 3: Time-Varying Portfolio Volatility (GARCH)

![GARCH Volatility Dynamics](https://github.com/user-attachments/assets/0a374a1b-c208-4fa8-90a3-18d384d366c0)

This chart displays the estimated conditional volatility (annualized) from the GARCH(1,1) model across all 312 months. Spikes correspond to known market stress events.

#### GARCH Model Summary Statistics

Aggregate statistics from the GARCH(1,1) estimation for the portfolio. Detailed time series available in `output/data/garch_portfolio_summary.csv`.

| Metric                      | Value   |
|-----------------------------|---------|
| Mean Sigma (monthly)        | 6.6478  |
| Mean Sigma (annualized)     | 23.0287 |
| Max Sigma (annualized)      | 56.7443 |
| Min Sigma (annualized)      | 12.6894 |

**GARCH Insights:**
- Mean annualized GARCH volatility (23.03%) is slightly below unconditional volatility (25.29%), reflecting that extreme events occur during brief periods relative to calmer regimes
- Peak volatility (56.74% annualized) corresponds to major market stress; minimum volatility (12.69% annualized) represents calm regimes
- Volatility range of 44.05 percentage points demonstrates substantial regime shifts, with critical implications for static risk models

#### Portfolio Risk Decomposition by Asset

This table breaks down the contribution of each holding to overall portfolio risk, accounting for weights and correlations.

| Ticker | Weight | Risk Contribution (%) |
|--------|--------|----------------------|
| MSFT   | 0.2    | 16.16                |
| INTC   | 0.2    | 22.31                |
| CSCO   | 0.2    | 19.40                |
| ORCL   | 0.2    | 20.30                |
| AAPL   | 0.2    | 21.83                |

**Risk Decomposition Analysis:**
- INTC contributes 22.31% of portfolio risk despite 20% weight
- MSFT contributes least (16.16%) in regards to the rest of the portfolio
- AAPL carries a 21.83% risk contribution but it ranks as the highest Sharpe ratio (0.8121) among all the stocks
- In fact, the risk contribution of each stock to the portfolio should be taken into account in regards to its sharpe ratio. A stock may contribute more or less to the overall risk of the portfolio but the risk-returns ratio is different for each stock
- Equal-weight capital allocation does not yield equal risk-efficient allocation

---

### Copula-Based Dependence and Joint Risk

**Context:** Linear correlation alone is insufficient to capture tail dependence—the tendency for assets to move together during extreme market events.  Linear correlation measures the correlation in general concepts but not during specifically during extreme situations. Copula models reveal non-linear joint behavior, particularly useful during market crashes when diversification benefits sometimes disappear.

#### Figure 4: Copula Analysis of Portfolio-NASDAQ Joint Distribution

![Copula Scatter Plot](https://github.com/user-attachments/assets/34e281c8-3371-4436-852f-dfc6ce26b510)

This scatter plot shows the empirical copula of portfolio and NASDAQ returns, revealing non-linear dependence structure.

#### Copula Summary Statistics

Dependence metrics from Clayton copula estimation. Full analysis available in `output/data/copula_portfolio_nasdaq_summary.csv`.

| Metric                            | Value  |
|-----------------------------------|--------|
| Linear Correlation                | 0.8805 |
| Clayton Theta                      | 4.4499 |
| Lower Tail Dependence (Lambda_L)   | 0.8558 |

**Copula Interpretation:**
- Linear correlation (0.8805) between Portfolio and NAASDAQ index is very high, indicating portfolio and NASDAQ track closely in normal market conditions
- Clayton theta (4.4499) captures strong left-tail dependence, which is not reflected in Pearson correlation
- Lambda_L (0.8558) indicates an 85.58% probability of joint extreme loss during 1-in-100-day events
- This high tail dependence reveals that portfolio and NASDAQ decline together during systematic stress periods, providing limited diversification benefit during crises
- The comparison between portfolio and NASDAQ is therefore primarily about relative risk-return efficiency rather than hedging benefit

---

### Stress Scenarios

**Context:** While historical risk metrics describe past volatility and returns, stress scenarios examine how the portfolio's risk profile would evolve if historical market regimes became more severe. These scenarios extend the historical data by introducing plausible but heightened stress conditions—such as amplified volatility or reduced returns—calibrated to past crisis episodes (dot-com crash, 2008 financial crisis). This approach bridges historical backtesting and forward-looking risk assessment.

#### Key Points:
- Each stress scenario modifies historical return and volatility parameters by a scaling factor, creating more adverse versions of observed market conditions
- Three scenarios tested:
  - Baseline (historical): Observed 26-year data
  - Tech Crash (volatility × 1.5): Dot-com-like regime
  - Rate Shock (volatility × 1.3, return −0.5%): Rising-rate regime

#### Stress Test Results

Projected portfolio risk metrics under three scenarios. Full details available in `output/data/stress_scenarios_summary.csv`.

| Scenario                           | VaR 95 | ES 95   | VaR 99 | ES 99  |
|------------------------------------|---------|---------|---------|---------| 
| Base (historical)                  | -11.00  | -15.32  | -15.66  | -21.00  |
| Tech Crash (x1.5 volatility)       | -16.49  | -22.97  | -23.49  | -31.50  |
| Rate Shock (mean -0.5%, vol x1.3)  | -12.94  | -15.44  | -17.61  | -18.96  |

**Scenario Analysis Interpretation:**
- Tech Crash scenario: A 50% volatility increase produces VaR 95% of -16.49% (vs. -11.00% baseline) and ES 95% of -22.97% (vs. -15.32% baseline), illustrating how volatility spikes amplify tail risk
- Rate Shock scenario: Combined return reduction (-0.5%) and volatility increase (×1.3) produces VaR 95% of -12.94%, demonstrating duration risk for long-duration assets
- Under stress conditions, portfolio tail risk substantially exceeds historical averages, with ES 95% potentially reaching -23%
-Among our scenarios, Tech Crash is more volatile than Rate Shock which is more volatile than Base historical scenario
---

## Summary of Key Findings

This results section demonstrates:

✓ Robust performance measurement across 26 years and multiple market regimes  
✓ Comprehensive risk quantification using three independent VaR methodologies  
✓ Dynamic volatility modeling capturing time-varying market conditions  
✓ Tail risk characterization through copula analysis and stress testing  
✓ Risk decomposition identifying individual asset contributions to portfolio volatility
