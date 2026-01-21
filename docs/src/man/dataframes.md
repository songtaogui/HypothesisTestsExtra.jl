# DataFrame & GroupedDataFrame Integration

`HypothesisTestsExtra.jl` extends the dispatch of `HypothesisTests.jl` to allow direct usage of `DataFrames.DataFrame` and `DataFrames.GroupedDataFrame`. This eliminates the need to manually extract vectors or pivot tables before testing.

## 1. DataFrame Integration

### Standard Hypothesis Tests
The library adds DataFrame support to existing tests in `HypothesisTests.jl`:

*   **T-Tests**: `EqualVarianceTTest`, `UnequalVarianceTTest`
*   **Variance**: `LeveneTest`, `BrownForsytheTest`, `FlignerKilleenTest`
*   **Distribution**: `KruskalWallisTest`, `MannWhitneyUTest`
*   **Categorical**: `ChisqTest`, `FisherExactTest`

**Syntax Pattern:**
```julia
TestName(df::DataFrame, group_col::Symbol, data_col::Symbol)
```

**Example:**
```julia
using DataFrames
df = DataFrame(
    Gender = ["M", "F", "M", "F", "M"],
    Score  = [90, 92, 88, 95, 85]
)

# Test if Score differs by Gender
UnequalVarianceTTest(df, :Gender, :Score)
```

### Contingency Tables from DataFrames
You can perform categorical tests on DataFrames in two formats:

**A. Raw Data (Long Format)**
One row per observation.
```julia
df_raw = DataFrame(Treatment=["A", "A", "B"], Outcome=["Success", "Fail", "Success"])
ChisqTest(df_raw, :Treatment, :Outcome)
```

**B. Frequency Data (Aggregated)**
One row per combination, with a count column.
```julia
df_freq = DataFrame(Treatment=["A", "B"], Outcome=["Win", "Win"], Count=[10, 20])
# Pass the frequency column as the 3rd argument
ChisqTest(df_freq, :Treatment, :Outcome, :Count)
```

---

## 2. GroupedDataFrame Integration

You can now pass the result of a `groupby` operation directly to hypothesis tests. This is particularly useful if your data pipeline already involves grouped operations.

### Numerical Tests (ANOVA, T-Tests, etc.)
When passing a `GroupedDataFrame`, the groups defined in the object are used as the factor levels.

**Syntax Pattern:**
```julia
# Uses the existing groups in gdf
TestName(gdf::GroupedDataFrame, data_col::Symbol)
```

**Example:**
```julia
using DataFrames
df = DataFrame(Group = ["A", "A", "B", "B", "C"], Value = 1:5)
gdf = groupby(df, :Group)

# Performs ANOVA using the groups defined in 'gdf' on the 'Value' column
OneWayANOVATest(gdf, :Value)
```
```plain
One-way analysis of variance (ANOVA) test
-----------------------------------------
Population details:
    parameter of interest:   Means
    value under h_0:         "all equal"
    point estimate:          NaN

Test summary:
    outcome with 95% confidence: fail to reject h_0
    p-value:                     0.1000

Details:
    number of observations: [2, 2, 1]
    F statistic:            9.0
    degrees of freedom:     (2, 2)
```


### Categorical Tests (Chisq, Fisher, etc.)
When using categorical tests, the keys of the `GroupedDataFrame` form the **rows** of the contingency table, and the specified column forms the **columns**.

**Syntax Pattern:**
```julia
# Rows = Groups in gdf, Columns = col_col
TestName(gdf::GroupedDataFrame, col_col::Symbol)
```

**Example:**
```julia
df = DataFrame(Dept=["Sales", "Sales", "IT", "IT"], Status=["Active", "Left", "Active", "Active"])
gdf = groupby(df, :Dept)

# Tests association between Dept (Groups) and Status
ChisqTest(gdf, :Status) 
```
```plain
Pearson's Chi-square Test
-------------------------
Population details:
    parameter of interest:   Multinomial Probabilities
    value under h_0:         [0.375, 0.375, 0.125, 0.125]
    point estimate:          [0.25, 0.5, 0.25, 0.0]
    95% confidence interval: [(0.0, 0.8837), (0.25, 1.0), (0.0, 0.8837), (0.0, 0.6337)]

Test summary:
    outcome with 95% confidence: fail to reject h_0
    one-sided p-value:           0.2482

Details:
    Sample size:        4
    statistic:          1.333333333333333
    degrees of freedom: 1
    residuals:          [-0.408248, 0.408248, 0.707107, -0.707107]
    std. residuals:     [-1.1547, 1.1547, 1.1547, -1.1547]
```

### Post-Hoc Analysis
Post-hoc tests also support `GroupedDataFrame` inputs directly.

```julia
gdf = groupby(df, :Treatment)

# Non-Parametric Pairwise
PostHocNonPar(gdf, :Response)

# Parametric Pairwise
PostHocTest(gdf, :Response; method=:tukey)

# Contingency Row-wise (Rows are groups)
PostHocContingencyRow(gdf, :Outcome)
```

### Convenience Overload
If you have a `GroupedDataFrame` but wish to ignore the current grouping and test different columns, you can provide the `group_col` argument explicitly. This is equivalent to calling the function on `parent(gdf)`.

```julia
# Ignores the grouping in gdf, groups by :OtherCol instead
OneWayANOVATest(gdf, :OtherCol, :Value) 
```