# HypothesisTestsExtra.jl

---

<!-- Documentation & Status -->
[![][docs-online-img]][docs-online-url] [![][aqua-img]][aqua-url]

[![][build-status-img]][build-status-url] [![][code-cov-img]][code-cov-url] 

<!-- Meta Info -->
[![][License-img]][License-url] [![][Lifecycle-img]][Lifecycle-url]

---

[docs-online-img]: https://img.shields.io/badge/docs-online-informational?style=for-the-badge&logo=Read%20The%20Docs&logoColor=white&labelColor=black
[docs-online-url]: https://songtaogui.github.io/HypothesisTestsExtra.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-informational?style=for-the-badge&logo=Read%20The%20Docs&logoColor=white&labelColor=black
[docs-stable-url]: https://songtaogui.github.io/HypothesisTestsExtra.jl/

[docs-latest-img]: https://img.shields.io/badge/docs-dev-informational?style=for-the-badge&logo=Read%20The%20Docs&logoColor=white&labelColor=black
[docs-latest-url]: https://songtaogui.github.io/HypothesisTestsExtra.jl/dev

[build-status-img]: https://img.shields.io/github/actions/workflow/status/songtaogui/HypothesisTestsExtra.jl/CI.yml?branch=master&style=for-the-badge&logo=Julia&logoColor=white&labelColor=darkgreen&color=C7E9C0
[build-status-url]: https://github.com/songtaogui/HypothesisTestsExtra.jl/actions/workflows/CI.yml?query=branch%3Amaster

[code-cov-img]: https://img.shields.io/codecov/c/github/songtaogui/HypothesisTestsExtra.jl?token=DYlPBrm49f&style=for-the-badge&logo=Codecov&logoColor=C7E9C0&labelColor=darkgreen&color=C7E9C0
[code-cov-url]: https://codecov.io/github/songtaogui/HypothesisTestsExtra.jl

[aqua-img]: https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%8A-DEEBF7?style=for-the-badge&logo=Julia&&labelColor=black&logoColor=white
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[License-img]: https://img.shields.io/badge/license-MIT-purple.svg?style=for-the-badge&logo=coursera&labelColor=purple&color=EFEDF5
[License-url]: https://github.com/songtaogui.github.io/HypothesisTestsExtra.jl?tab=MIT-1-ov-file

[Lifecycle-img]: https://img.shields.io/badge/lifecycle-wip-EFEDF5.svg?style=for-the-badge&logo=stagetimer&logoColor=white&labelColor=6A51A3
[Lifecycle-url]: https://github.com/songtaogui.github.io/HypothesisTestsExtra.jl/releases

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
ph = PostHocPar(groups; method=:tukey, cld=true)
println(ph)

# 3. DataFrame Support
df = DataFrame(Group=["A","A","B","B"], Value=[1,2, 10,11])
PostHocPar(df, :Group, :Value; method=:tukey)
```
