# HypothesisTestsExtra.jl

---

[![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url] [![][build-status-img]][build-status-url]  [![][code-cov-img]][code-cov-url] 

[docs-latest-img]: https://img.shields.io/badge/docs-dev-informational?style=for-the-badge&logo=Read%20The%20Docs&logoColor=white
[docs-latest-url]: https://songtaogui.github.io/HypothesisTestsExtra.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-informational?style=for-the-badge&logo=Read%20The%20Docs&logoColor=white
[docs-stable-url]: https://songtaogui.github.io/HypothesisTestsExtra.jl/

[build-status-img]: https://img.shields.io/github/actions/workflow/status/songtaogui/HypothesisTestsExtra.jl/CI.yml?branch=main&style=for-the-badge&logo=Julia&logoColor=white&labelColor=black&color=C7E9C0
[build-status-url]: https://github.com/jonathanBieler/BurrowsWheelerAligner.jl/actions/workflows/CI.yml?query=branch%3Amain)

[code-cov-img]: https://img.shields.io/codecov/c/github/songtaogui/HypothesisTestsExtra.jl?token=DYlPBrm49f&style=for-the-badge&logo=Codecov&logoColor=D4B9DA&labelColor=black&color=purple
[code-cov-url]: https://codecov.io/github/songtaogui/HypothesisTestsExtra.jl

---

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
