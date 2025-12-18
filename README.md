# Tech Portfolio Risk Analysis – VaR, ES, GARCH, Copula & Stress Testing

This project builds a full market risk framework for an equal‑weighted technology equity portfolio versus the NASDAQ benchmark, using monthly data from November 1999 to November 2025.

The goal is to show how a junior risk analyst can combine classical risk metrics (VaR/ES, drawdowns) with more advanced tools (GARCH volatility, copulas, stress testing, risk decomposition).

---

## Project Overview

### Portfolio

Equal‑weighted portfolio of 5 large‑cap US tech stocks (20% each):

- MSFT (Microsoft)  
- INTC (Intel)  
- CSCO (Cisco)  
- ORCL (Oracle)  
- AAPL (Apple)  

### Benchmark

- NASDAQ Composite (symbol: `^IXIC`)

### Data

- Frequency: Monthly  
- Period: 1999‑11 to 2025‑11 (≈ 26 years)

---

## Main Questions

- How does the portfolio’s risk compare to the NASDAQ (volatility, drawdowns, VaR/ES)?  
- How does risk evolve over time (GARCH conditional volatility)?  
- Do the portfolio and NASDAQ tend to crash together (tail dependence via copula)?  
- How would the portfolio behave under simple market stress scenarios (Tech Crash, Rate Shock)?  
- Which stocks contribute most to portfolio risk, and do they earn that risk via Sharpe ratio and performance?

  

  

