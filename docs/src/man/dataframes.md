# DataFrame Integration

`HypothesisTestsExtra.jl` extends the dispatch of `HypothesisTests.jl` to allow direct usage of `DataFrames.DataFrame`. This eliminates the need to manually extract vectors or pivot tables before testing.

## Supported Functions

### 1. Standard Hypothesis Tests
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

You will get:
```plain
Two sample t-test (unequal variance)
------------------------------------
Population details:
    parameter of interest:   Mean difference
    value under h_0:         0
    point estimate:          5.83333
    95% confidence interval: (-1.414, 13.08)

Test summary:
    outcome with 95% confidence: fail to reject h_0
    two-sided p-value:           0.0800

Details:
    number of observations:   [2,3]
    t-statistic:              2.7933040956366755
    degrees of freedom:       2.6086358344798386
    empirical standard error: 2.088327347690278
```

### 2. Contingency Tables from DataFrames
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

### 3. Post-Hoc on DataFrames
The new Post-Hoc methods fully support the DataFrame interface.

```julia
# Parametric
PostHocTest(df, :Group, :Value; method=:tukey, cld=true)

# Contingency Row-wise
PostHocContingencyRow(df, :RowCat, :ColCat; method=:chisq)
```