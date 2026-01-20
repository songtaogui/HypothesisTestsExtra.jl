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

## DataFrame Extensions
*Note: These methods extend `HypothesisTests.jl` functions to accept DataFrame as inputs.*

### Categorical Tests
```@docs
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.ChisqTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.FisherExactTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.PowerDivergenceTest(::DataFrame, ::Symbol, ::Symbol, ::Symbol)
```

### K-Sample & Variance Tests
```@docs
HypothesisTests.OneWayANOVATest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.KruskalWallisTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.LeveneTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.BrownForsytheTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.FlignerKilleenTest(::DataFrame, ::Symbol, ::Symbol)
```

### Two-Sample Tests

```@docs
HypothesisTests.EqualVarianceTTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.UnequalVarianceTTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.VarianceFTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.MannWhitneyUTest(::DataFrame, ::Symbol, ::Symbol)
HypothesisTests.ApproximateTwoSampleKSTest(::DataFrame, ::Symbol, ::Symbol)
```
