# Additional Test methods

## Welch's ANOVA

Standard One-Way ANOVA assumes that all groups share a common variance (homoscedasticity). When this assumption is violated, the Type I error rate can inflate significantly.

**HypothesisTestsExtra** implements **Welch's ANOVA**, which weights observations by the inverse of their group variance. The test statistic $F$ follows an approximate F-distribution with degrees of freedom $df_1$ and $df_2$ calculated via the Welch-Satterthwaite equation.

### Usage

```julia
# Vector of vectors
WelchANOVATest(group_a, group_b, group_c)

# DataFrame
WelchANOVATest(df, :GroupCol, :ValueCol)
```

## Fisher's Exact Test ($R \times C$)

The standard `FisherExactTest` is typically limited to $2 \times 2$ contingency tables due to the computational complexity of calculating exact factorials for larger matrices.

**HypothesisTestsExtra** introduces `FisherExactTestRxC`, which automatically selects the best strategy:
1.  **2x2 Tables**: Dispatches to the exact method.
2.  **RxC Tables**: Uses a **Monte Carlo (MC)** simulation strategy.

### Algorithm
For tables larger than $2 \times 2$, we estimate the p-value by sampling random tables with the same marginal totals as the observed table.
*   **Statistic**: Log-probability of the table configuration.
*   **P-Value**: Proportion of simulated tables with a probability less than or equal to the observed table's probability.
*   **Smoothing**: Applies the $(k+1)/(N+1)$ rule to prevent zero p-values.

### Usage

```julia
using HypothesisTestsExtra

# 3x3 Contingency Table
tbl = [10 5 2; 2 15 8; 1 4 20]

# Automatically detects size and uses Monte Carlo
test = FisherExactTestRxC(tbl)

Fisher's Exact Test for RxC Tables (Monte Carlo)
------------------------------------------------
Population details:
    parameter of interest:   P-value
    value under h_0:         0.0
    point estimate:          NaN
    95% confidence interval: (0.3181, 0.3238)

Test summary:
    outcome with 95% confidence: fail to reject h_0
    one-sided p-value:           0.3226

Details:
    contingency table (size (3, 3)):
        10   5   2
         2  15   8
         1   4  20

# Get p-value and Confidence Interval of the simulation
pvalue(test; n_sim=100_000)
confint(test) 
```
