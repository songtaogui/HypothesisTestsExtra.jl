# Post-Hoc Analysis Guide

Post-hoc tests are performed after a significant omnibus test (like ANOVA or Chi-Square) to determine *which* specific groups or categories differ. 

## 1. Parametric Post-Hoc Tests
**Function:** `PostHocTest`

These methods assume normality. Choice depends on variance assumptions and the desired balance between Type I errors (False Positives) and Type II errors (False Negatives).

| Method | Variance Assumption | Conservatism | Description |
| :--- | :--- | :--- | :--- |
| **:tukey** | Equal | Balanced | **Recommended default.** Controls FWER (Family-Wise Error Rate) exactly for all pairwise comparisons. Best for balanced designs. |
| **:bonferroni**| Equal | Very High | Simple $\alpha / m$ correction. Can be overly conservative if the number of pairs is large. |
| **:lsd** | Equal | Low | Fisher's Least Significant Difference. No correction applied. High power but high Type I error risk. Only use if ANOVA F-test is very strong. |
| **:scheffe** | Equal | High | Designed for *any* linear contrast, not just pairwise. Very conservative for simple pairwise tests. |
| **:sidak** | Equal | High | Slightly more powerful version of Bonferroni. |
| **:tamhane** | **Unequal** | Balanced | **Use after Welch ANOVA.** Uses the T2 statistic and approximates degrees of freedom for every pair. Robust to heteroscedasticity. |

### Example
```julia
# If Levene's test failed, use Tamhane:
PostHocTest(groups; method=:tamhane)
```

## 2. Non-Parametric Post-Hoc Tests
**Function:** `PostHocNonPar`

Used when data is ordinal or normality is violated (e.g., after Kruskal-Wallis).

### Methods
*   **:dunn_bonferroni** (Default): Uses rank sums (Z-scores) and adjusts p-values using Bonferroni.
*   **:nemenyi**: The non-parametric equivalent of Tukey's HSD. Tests the difference in rank sums against a critical range from the Studentized Range distribution.

## 3. Contingency Table Post-Hoc
**Functions:** `PostHocContingencyRow`, `PostHocContingencyCell`

When a Chi-Square test is significant, you need to know which rows or specific cells are driving the association.

### A. Row-wise Comparisons (`PostHocContingencyRow`)
Compares distributions between pairs of rows (groups).
*   **Method `:chisq`**: Performs a $2 \times C$ Chi-square test for every pair of rows.
*   **Method `:fisher`**: Performs a $2 \times C$ Fisher test for every pair.
*   **Adjustment**: P-values are adjusted (e.g., Bonferroni, FDR) to account for multiple testing.

### B. Cell-wise Residuals (`PostHocContingencyCell`)
Identifies specific cells that are over- or under-represented.
*   **Method `:asr` (Adjusted Standardized Residuals)**: Calculates the residual $r_{ij} = (O - E) / \sqrt{E(1-row\%)(1-col\%)}$.
    *   If $|r_{ij}| > Z_{\alpha/2}$ (approx 1.96 for $\alpha=0.05$), the cell is significant.
    *   Provides a detailed breakdown of which specific intersection (Row $\times$ Col) deviates from independence.

## Compact Letter Display (CLD)
All group-level post-hoc tests support `cld=true`. This generates a string representation where groups sharing the same letter are **not** significantly different.

```julia
res = PostHocTest(df, :Group, :Value; cld=true)
# Output might look like:
# Group A: "a"
# Group B: "a"
# Group C: "b"  (C is different from A and B)
```