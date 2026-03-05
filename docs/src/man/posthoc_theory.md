# Post-Hoc Analysis Guide

Post-hoc tests (Multiple Comparison Procedures) are performed after a significant omnibus test (e.g., ANOVA, Kruskal-Wallis, or Chi-Square) to identify exactly which groups or cells differ significantly while controlling the overall Type I error rate.

## 1. Parametric Post-Hoc Tests
**Function:** `PostHocPar(groups; ...)`

Used when data is continuous and approximately normally distributed. These tests operate on group means.

### Key Arguments
- `method::Symbol`: The specific algorithm (see table below).
- `alpha_levene::Float64`: Threshold for Levene's test. If $p < \alpha_{levene}$, a warning suggests switching to `:tamhane` due to heteroscedasticity.
- `pairs::Vector{Tuple{Int, Int}}`: Optional. Define specific pairs to test (e.g., `[(1,2), (1,3)]`) instead of all-pairs.
- `row_labels::AbstractVector{<:AbstractString}`: Custom names for groups in the output.

### Supported Methods

| Method | Variance Assumption | Conservatism | Description |
| :--- | :--- | :--- | :--- |
| **:tukey** | Equal | Balanced | **Recommended default.** Tukey's HSD (Honest Significant Difference). Controls FWER for all-pairs. |
| **:bonferroni**| Equal | Very High | Simple $\alpha / m$ adjustment. Very robust but loses power as the number of groups increases. |
| **:lsd** | Equal | Very Low | Fisher's Least Significant Difference. No FWER correction. High power, high Type I error risk. |
| **:scheffe** | Equal | Extreme | Controls FWER for *all possible* linear contrasts. Overly conservative for just pairwise tests. |
| **:sidak** | Equal | High | Slightly more powerful than Bonferroni for independent comparisons. |
| **:snk** | Equal | Moderate | Student-Newman-Keuls. A stepwise procedure. Less conservative than Tukey; does not strictly control FWER. |
| **:duncan** | Equal | Low | Duncan's New Multiple Range Test. Higher power than SNK but higher false positive risk. |
| **:tamhane** | **Unequal** | Balanced | **Use if Levene's test is significant.** Based on Welch's t-test with Sidak-like p-value adjustment. |

---

## 2. Non-Parametric Post-Hoc Tests
**Function:** `PostHocNonPar(groups; ...)`

Used for ordinal data or when normality is violated. These tests operate on the **ranks** of the pooled data. Ties in the data are automatically corrected.

### Supported Methods
- **Dunn's Test Family** (Based on Z-scores of mean rank differences):
    - `:dunn`: Unadjusted p-values (high power, no FWER control).
    - `:dunn_bonferroni` (Default): Robust and standard for non-parametric post-hoc.
    - `:dunn_sidak`: Slightly less conservative than Bonferroni.
- **Nemenyi Test**:
    - `:nemenyi`: The non-parametric analogue to Tukey’s HSD. Uses the Studentized Range distribution. Better for large, equal-sized samples.

---

## 3. Contingency Table Post-Hoc
Designed for categorical data after a significant Pearson's Chi-Square test.

### A. Row-wise Comparison (`PostHocContingencyRow`)
Compares the distribution of columns between pairs of rows (groups). 
- **Methods**:
    - `:chisq` (Default): Pearson's Chi-square test. Fast and standard for large samples.
    - `:fisher`: Fisher's Exact Test. (see also `FisherExactTestRxC`).
        - For **2x2** sub-tables, it computes the exact p-value;
        - For **2xC** sub-tables (where C > 2), it estimates the p-value via Monte Carlo simulation.
    - `:[chisq|fisher]_[bonferroni|bh|fdr]`: posthoc methods with Pvalue adjustment. e.g.:
            `:chisq_bonferroni` means Chi-square test with Bonferroni correction.
            `:fisher_bh` and `:fisher_fdr` are the same, means FDR P-value correction.
- **CLD Support**: If `cld=true`, groups are ordered and labeled based on the proportions in the first column of the table.

### B. Cell-wise Analysis (`PostHocContingencyCell`)
Identifies which specific cells (intersections) are significant drivers of the association.
- **Methods**:
    - `:asr`: (Default) Adjusted Standardized Residuals. Tests if a cell deviates from independence.
    - `:fisher`: Fisher's Exact Test for each cell (One vs Rest).
    - `:[asr|fisher]_[bonferroni|bh|fdr]`: posthoc methods with Pvalue adjustment. e.g.:
             `:asr_bonferroni` means Adjusted Standardized Residuals with Bonferroni correction.
             `:asr_bh` and `:asr_fdr` are the same, means FDR P-value correction.
- **P-Value Adjustments**: Supports `:bonferroni`, `:bh` (Benjamini-Hochberg for FDR), and `:none`.

---

## 4. Compact Letter Display (CLD)
The `cld=true` argument simplifies complex pairwise results. Groups assigned the **same letter** are **not** significantly different.

### Example: Non-Parametric with CLD
```julia
using HypothesisTestsExtra

# 3 groups of observations
g1, g2, g3 = [rand(10), rand(10) .+ 2, rand(10) .+ 0.5]

# Perform test
result = PostHocNonPar([g1, g2, g3]; 
                       method=:dunn_bonferroni, 
                       cld=true, 
                       row_labels=["Control", "High_Dose", "Low_Dose"])

# Extract as DataFrame
df_letters = GroupTestToDataframe(result)
println(df_letters)
```

**Interpretation of Output:**
- If "Control" is `b` and "High_Dose" is `a`, they are significantly different.
- If "Low_Dose" is `ab`, it is not significantly different from either "Control" or "High_Dose".

---

### Accessing Results

::: tip

Starting from **HypothesisTestsExtra.jl v0.3.0**, support for `DataFrame` and `GroupedDataFrame` is provided via a **package extension** (`HypothesisTestsExtraDataFramesExt`), not core loading.

to use the function below, make sure you also loaded the weak dependencies:

```julia
using DataFrames, CategoricalArrays
```

:::


You can convert any `PostHocTestResult` object to a standard Julia DataFrame for further analysis or export:

```julia
using DataFrames, CategoricalArrays

full_table = DataFrame(result)      # Detailed pairwise statistics
cld_table = GroupTestToDataframe(result) # Only group labels and letters
```



