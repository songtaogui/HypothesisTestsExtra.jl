# HypothesisTestsExtra.jl

[![Build Status](https://github.com/songtaogui/HypothesisTestsExtra.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/songtaogui/HypothesisTestsExtra.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![codecov](https://codecov.io/github/songtaogui/HypothesisTestsExtra.jl/branch/master/graph/badge.svg?token=DYlPBrm49f)](https://codecov.io/github/songtaogui/HypothesisTestsExtra.jl)

**HypothesisTestsExtra.jl** is an extension library for the Julia ecosystem's standard [`HypothesisTests.jl`](https://github.com/JuliaStats/HypothesisTests.jl). It fills critical gaps in statistical analysis by providing robust support for:

1.  **Heteroscedastic Data**: Welch's ANOVA for unequal variances.
2.  **Complex Categorical Data**: Fisher's Exact Test for $R \times C$ tables via Monte Carlo simulation.
3.  **Post-Hoc Analysis**: A comprehensive suite of pairwise comparison tools (Parametric, Non-Parametric, and Contingency tables) with support for Compact Letter Displays (CLD).
4.  **DataFrames Integration**: Native support for passing `DataFrame` objects to both standard and new hypothesis tests.

## Installation

```julia
using Pkg
Pkg.add("HypothesisTestsExtra")
```

## Quick Start

```julia
using HypothesisTestsExtra, DataFrames

# 1. Welch ANOVA (Unequal Variances)
groups = [[1,2,3], [10,11,12], [5,6,7]]
wt = WelchANOVATest(groups...)

# 2. Post-Hoc Test with Tukey's HSD
ph = PostHocTest(groups; method=:tukey, cld=true)
println(ph)

# 3. DataFrame Support
df = DataFrame(Group=["A","A","B","B"], Value=[1,2, 10,11])
PostHocTest(df, :Group, :Value; method=:tukey)
```