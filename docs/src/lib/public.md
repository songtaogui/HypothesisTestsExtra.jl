# API Reference

## New Hypothesis Tests

```@docs
WelchANOVATest
FisherExactTestRxC
FisherExactTestMC
```

## Post-Hoc Analysis

### Parametric & Non-Parametric
```@docs
PostHocTest
PostHocNonPar
```

### Contingency Tables
```@docs
PostHocContingencyRow
PostHocContingencyCell
```

### Structures & Results
```@docs
PostHocTestResult
PostHocComparison
ContingencyCellTestResult
GroupTestToDataframe
CellTestToDataframe
```

## DataFrames Extensions
*Note: These methods extend `HypothesisTests.jl` functions to accept `DataFrame` and `GroupedDataFrame` as inputs.*

### Categorical Tests
```@docs
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.ChisqTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::GroupedDataFrame, ::Symbol)

HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::GroupedDataFrame, ::Symbol)
```

### K-Sample & Variance Tests
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