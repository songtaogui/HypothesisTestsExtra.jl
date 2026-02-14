# Additional Test Methods

This section describes the statistical tests provided by **HypothesisTestsExtra** that extend the functionality of the base `HypothesisTests.jl` package.

## 1. Welch's ANOVA

Standard One-Way ANOVA assumes that all groups share a common variance (homoscedasticity). When this assumption is violated, the Type I error rate can inflate significantly.

**Welch's ANOVA** weights observations by the inverse of their group variance. The test statistic $F$ follows an approximate F-distribution with degrees of freedom $df_1$ and $df_2$ calculated via the Welch-Satterthwaite equation.

### Applicability
*   **Independent Variable (IV)**: Categorical (2 or more groups).
*   **Dependent Variable (DV)**: Numeric (continuous).
*   **Assumption**: Normality within groups is preferred, but homoscedasticity is **not** required.

### Usage
```julia
# 1. Using Raw Vectors
WelchANOVATest(group_a, group_b, group_c)

# 2. Using DataFrame
# group_col must be categorical; data_col must be numeric.
WelchANOVATest(df, :GroupCol, :ValueCol)

# 3. Using GroupedDataFrame
gd = groupby(df, :GroupCol)
WelchANOVATest(gd, :ValueCol)
```

---

## 2. Fisher's Exact Test ($R \times C$)

The standard `FisherExactTest` is typically limited to $2 \times 2$ contingency tables. **HypothesisTestsExtra** introduces `FisherExactTestRxC`, which provides an automated strategy for larger tables.

### Principles
1.  **2x2 Tables**: Dispatches to the exact hypergeometric method.
2.  **RxC Tables**: Uses a **Monte Carlo (MC)** simulation strategy. Since calculating all possible permutations for large tables is computationally prohibitive, this method estimates the p-value by sampling random tables with the same marginal totals.

### Usage
```julia
# 3x3 Contingency Table
tbl = [10 5 2; 2 15 8; 1 4 20]
test = FisherExactTestRxC(tbl)

# Specify number of simulations for higher precision
p_val = pvalue(test; n_sim=100_000)
```

---

## 3. Cochran-Armitage Trend Test

The **Cochran-Armitage** test is used to assess whether there is a linear trend in proportions across levels of an ordered factor. It is more powerful than a standard Chi-square test when the categories have a natural ordering.

### Principles
The test calculates a standardized statistic $Z$ based on the slope of proportions across levels. 
*   **Null Hypothesis ($H_0$)**: The proportions are the same across all levels (slope = 0).
*   **Alternative Hypothesis ($H_a$)**: There is a linear trend in proportions.

### Applicability
*   **IV**: Ordered Categorical (e.g., Dosage: Low < Med < High).
*   **DV**: Binary (e.g., Success/Failure, 0/1).

### Parameters
*   `scores`: Determines the spacing between levels.
    *   `:equidistant` (default): Assigns scores 1, 2, 3...
    *   `:midrank`: Assigns scores based on the average rank of observations.
    *   `Vector{Float64}`: Provide custom scores (e.g., actual dosage amounts `[0.5, 1.0, 5.0]`).

### Usage
```julia
# Using a Long DataFrame (Raw Data)
# dose must be an Ordered Categorical column
CochranArmitageTest(df, :dose, :outcome; scores=:equidistant)

# Using a Frequency DataFrame (Aggregated)
# freq_col contains the counts
CochranArmitageTest(df, :dose, :outcome, :freq_col)
```

---

## 4. Jonckheere-Terpstra Trend Test

The **Jonckheere-Terpstra** test is a non-parametric test for more than two independent samples where the groups have a specific a priori ordering. It is a more powerful alternative to the Kruskal-Wallis test when a monotonic trend is expected.

### Principles
It computes a $J$ statistic, which is the sum of Mann-Whitney $U$ statistics for all pairs $(i, j)$ where group $i <$ group $j$. **HypothesisTestsExtra** implements a tie-corrected version of the variance calculation to ensure accuracy in the presence of tied data.

### Applicability
*   **IV**: Ordered Categorical.
*   **DV**: Numeric or Ordered Categorical (Ranked).

### Usage
```julia
# Using a GroupedDataFrame
# The grouping column of 'gd' must be an Ordered Categorical array.
gd = groupby(df, :ordered_dose)
test = JonckheereTerpstraTest(gd, :response_score)

# Standard result access
p_val = pvalue(test)
z_stat = test.Z
```

---

## 5. Linear-by-Linear Association Test

The **Linear-by-Linear Association** test (also known as the Mantel-Haenszel trend test) measures the linear association between two ordinal variables.

### Principles
The test is based on the Pearson correlation coefficient $r$ computed using scores assigned to the categories. The test statistic $M^2 = (N-1)r^2$ follows a Chi-square distribution with 1 degree of freedom.

### Applicability
*   **Row Variable**: Ordered Categorical.
*   **Column Variable**: Ordered Categorical.

### Parameters
*   `row_scores` / `col_scores`: Can be `:equidistant` (default) or `:midrank`.

### Usage
```julia
# From a raw Matrix
tbl = [10 5 2; 3 8 12; 1 2 15]
test = LinearByLinearTest(tbl; row_scores=:midrank, col_scores=:equidistant)

# From a DataFrame
LinearByLinearTest(df, :ordered_row, :ordered_col)
```

