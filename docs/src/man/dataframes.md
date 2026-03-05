# DataFrame & GroupedDataFrame Integration

`HypothesisTestsExtra.jl` provides seamless integration with `DataFrames.jl`. It extends `HypothesisTests.jl` by allowing users to pass `DataFrame` and `GroupedDataFrame` objects directly into test functions, automatically handling data cleaning (removing `missing`/`NaN`) and group extraction.


## Loading `DataFrame` / `GroupedDataFrame` Support (Extension-Based)

::: tip

Starting from **HypothesisTestsExtra.jl v0.3.0**, support for `DataFrame` and `GroupedDataFrame` is provided via a **package extension** (`HypothesisTestsExtraDataFramesExt`), not core loading.

This means DataFrame-related methods are only available when the extension is activated by loading its weak dependencies.

:::

### How to enable it

```julia
using HypothesisTestsExtra
using DataFrames, CategoricalArrays
```

> **Recommendation:** Load `DataFrames` and `CategoricalArrays` **before** running any DF/GDF-based tests.

---

### Required packages for extension activation

The extension is configured as:

- **Extension name:** `HypothesisTestsExtraDataFramesExt`
- **Weak dependencies:** `DataFrames`, `CategoricalArrays`

So to use APIs like:

- `TestName(df::DataFrame, ...)`
- `TestName(gdf::GroupedDataFrame, ...)`
- DF/GDF post-hoc helpers

you should ensure both are installed and loaded in the session.

---

### If methods are missing

If you see `MethodError` for `DataFrame`/`GroupedDataFrame` signatures, check:

1. `DataFrames` and `CategoricalArrays` are installed in the active environment.
2. Both are imported in the current session.
3. `HypothesisTestsExtra` is loaded in the same environment.

A safe startup pattern is:

```julia
using DataFrames
using CategoricalArrays
using HypothesisTestsExtra
```

(or equivalent ordering in the same session).

---

## 1. Type Safety and Column Validation

The library enforces strict type requirements to ensure statistical validity. Before running a test, columns are validated based on their roles:

*   **`:numeric`**: Standard continuous data (e.g., `Float64`, `Int`).
*   **`:categorical`**: Groups or categories (Strings, Symbols, or `CategoricalArrays`).
*   **`:ordered`**: Required for trend tests. Must be an **ordered** `CategoricalArray`.
*   **`:binary`**: Required for 2-sample tests or specific trend tests. Must contain exactly 2 unique valid levels.

---

## 2. DataFrame Integration

### Standard Hypothesis Tests
You can perform tests by specifying the DataFrame, the grouping column (Independent Variable), and the data column (Dependent Variable).

**Syntax Pattern:**
```julia
TestName(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
```

| Test Category | Supported Tests | Requirements |
| :--- | :--- | :--- |
| **T-Tests** | `EqualVarianceTTest`, `UnequalVarianceTTest` | `group`: Binary, `data`: Numeric |
| **Variance** | `LeveneTest`, `BrownForsytheTest`, `FlignerKilleenTest` | `group`: Categorical, `data`: Numeric |
| **K-Sample** | `OneWayANOVATest`, `WelchANOVATest` | `group`: Categorical, `data`: Numeric |
| **Non-Parametric** | `KruskalWallisTest`, `MannWhitneyUTest` | `data`: Numeric OR Ordered |

**Example:**
```julia
using DataFrames, CategoricalArrays
df = DataFrame(
    Group = categorical(["A", "A", "B", "B", "C"], ordered=true),
    Score = [10, 12, 15, 18, 22]
)

# Kruskal-Wallis supports ordered categorical data automatically
KruskalWallisTest(df, :Group, :Score)
```

### Contingency Table Tests
Categorical tests support both raw observation data and pre-aggregated frequency data.

*   **Raw Data**: `TestName(df, row_col, col_col)`
*   **Frequency Data**: `TestName(df, row_col, col_col, freq_col)`

**Example:**
```julia
# Frequency (Long) Format
df_freq = DataFrame(
    Design = ["Modern", "Modern", "Classic", "Classic"],
    Click  = ["Yes", "No", "Yes", "No"],
    Count  = [50, 10, 30, 40]
)
ChisqTest(df_freq, :Design, :Click, :Count)
```

---

## 3. GroupedDataFrame Integration

When using a `GroupedDataFrame` (from `groupby`), the grouping structure is inferred automatically. You no longer need to specify a `group_col`.

### Numerical & Distributional Tests
The groups defined in the `GroupedDataFrame` are treated as the levels of the independent variable.

**Syntax Pattern:**
```julia
TestName(gdf::GroupedDataFrame, data_col::Symbol)
```

**Example:**
```julia
gdf = groupby(df, :Region)
# Performs Welch's ANOVA across all regions defined in gdf
WelchANOVATest(gdf, :Revenue)
```

### Categorical Tests (Rows from Groups)
The `GroupedDataFrame` keys become the **rows** of the contingency table, and the specified `col_col` becomes the **columns**.

```julia
# Frequency data is also supported with GDF
gdf = groupby(df, :EducationLevel)
FisherExactTestRxC(gdf, :EmploymentStatus, :Weights)
```

---

## 4. Trend and Association Tests

The library introduces specialized tests for ordinal data. These tests require specific column types (usually `ordered` CategoricalArrays).

### Cochran-Armitage Trend Test
Tests for a linear trend in proportions across levels of an ordinal variable.
*   **IV (`group_col`)**: Must be Ordered.
*   **DV (`data_col`)**: Must be Binary.

```julia
df_ca = DataFrame(
    dose = categorical(["Low", "Low", "Med", "Med", "High", "High"], ordered=true),
    success = categorical([0, 0, 1, 0, 1, 1])
)
ca = CochranArmitageTest(df_ca, :dose, :success)
```

### Jonckheere-Terpstra Test
A non-parametric test for a monotonic trend in medians across ordered groups.
*   **IV (`group_col`)**: Must be Ordered.
*   **DV (`data_col`)**: Numeric or Ordered.

```julia
df_jt = DataFrame(
    dose = categorical(["Low", "Low", "Med", "Med", "High", "High"], ordered=true),
    resp = [1.2, 1.4, NaN, 2.5, 3.1, missing]
)
jt = JonckheereTerpstraTest(df_jt, :dose, :resp)
```

### Linear-by-Linear Association
Tests for linear association in an RxC table where both dimensions are ordinal.
*   **Row & Column**: Both must be Ordered.

```julia
df_lbl = DataFrame(
    row = categorical(["L1", "L1", "L2", "L2", "L3", "L3"], ordered=true),
    col = categorical(["C1", "C2", "C1", "C2", "C1", "C2"], ordered=true),
    freq = [10, 5, 2, 8, 1, 15]
)
lbl = LinearByLinearTest(df_lbl, :row, :col, :freq)
```

---

## 5. Post-Hoc Analysis

Post-hoc tests are updated to support the same `DataFrame` and `GroupedDataFrame` dispatch logic.

### Pairwise Comparisons
```julia
# Non-parametric (Dunn's) via GDF
PostHocNonPar(gdf, :Value; method=:bonferroni)

# Parametric (Tukey/Scheffe) via DF
PostHocPar(df, :Group, :Value; method=:tukey)
```

### Contingency Table Post-Hoc
*   `PostHocContingencyRow`: Pairwise comparisons between rows (proportions).
*   `PostHocContingencyCell`: Adjusted Standardized Residuals (ASR) for each cell.

```julia
# ASR analysis on categorical raw data
PostHocContingencyCell(df, :Industry, :Sentiment)
```
