# API Reference

## Extra Hypothesis Tests
Common statistical tests not present in the base `HypothesisTests.jl` package.

### Welch's ANOVA
```@docs
WelchANOVATest
```

### RxC Contingency Table Tests
Tests for independence in tables larger than 2x2.
```@docs
FisherExactTestRxC
FisherExactTestMC
```

### Trend and Association Tests
Tests designed for ordinal or linear relationships between categories.
```@docs
CochranArmitageTest
JonckheereTerpstraTest
LinearByLinearTest
```

## Post-Hoc Analysis
Tools for following up on significant ANOVA or Chi-square results.

### Parametric & Non-Parametric
Pairwise comparisons for K-sample tests (e.g., Tukey, Dunn).
```@docs
PostHocPar
PostHocNonPar
```

### Contingency Tables
Post-hoc analysis for Chi-square or Fisher tests (e.g., row-wise comparisons or adjusted standardized residuals).
```@docs
PostHocContingencyRow
PostHocContingencyCell
```

### Structures & Results
Helper structures for storing and exporting results.
```@docs
PostHocTestResult
PostHocComparison
ContingencyCellTestResult
GroupTestToDataframe
CellTestToDataframe
```

## DataFrames Extensions
This package extends `HypothesisTests.jl` and internal methods to support `DataFrame` and `GroupedDataFrame` inputs. 

**Note on GroupedDataFrame Dispatch:**
For all `GroupedDataFrame` (GDF) methods, the grouping is determined by the GDF's keys. You do not need to specify a group column; the first grouping column in the GDF is used as the Independent Variable (IV).

### Categorical Tests (Independence)
Supports raw data (two columns) or aggregated frequency data (three columns).

```@docs
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.ChisqTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::GroupedDataFrame, ::Symbol)
HypothesisTests.FisherExactTest(::GroupedDataFrame, ::Symbol, ::Symbol)

HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::GroupedDataFrame, ::Symbol)

FisherExactTestRxC(::DataFrame, ::Symbol, ::Symbol)
FisherExactTestRxC(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
FisherExactTestRxC(::GroupedDataFrame, ::Symbol)
```

### K-Sample & Variance Tests
Tests comparing 2 or more groups.

```@docs
HypothesisTests.OneWayANOVATest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.OneWayANOVATest(::GroupedDataFrame, ::Symbol)

WelchANOVATest(::DataFrame, ::Symbol, ::Symbol)
WelchANOVATest(::GroupedDataFrame, ::Symbol)

HypothesisTests.KruskalWallisTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.KruskalWallisTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.LeveneTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.LeveneTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.BrownForsytheTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.BrownForsytheTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.FlignerKilleenTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.FlignerKilleenTest(::GroupedDataFrame, ::Symbol)
```

### Two-Sample Tests
Specialized tests for exactly 2 groups.

```@docs
HypothesisTests.EqualVarianceTTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.EqualVarianceTTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.UnequalVarianceTTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.UnequalVarianceTTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.VarianceFTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.VarianceFTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.MannWhitneyUTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.MannWhitneyUTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.ApproximateTwoSampleKSTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.ApproximateTwoSampleKSTest(::GroupedDataFrame, ::Symbol)
```

### Trend and Association Tests
These methods require ordered categorical data where appropriate (e.g., Jonckheere-Terpstra or Cochran-Armitage).

```@docs
CochranArmitageTest(::DataFrame, ::Symbol, ::Symbol)
CochranArmitageTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
CochranArmitageTest(::GroupedDataFrame, ::Symbol)

JonckheereTerpstraTest(::DataFrame, ::Symbol, ::Symbol)
JonckheereTerpstraTest(::GroupedDataFrame, ::Symbol)

LinearByLinearTest(::DataFrame, ::Symbol, ::Symbol)
LinearByLinearTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
LinearByLinearTest(::GroupedDataFrame, ::Symbol)
```
