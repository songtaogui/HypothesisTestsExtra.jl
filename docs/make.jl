using Documenter
using HypothesisTestsExtra
using DataFrames

makedocs(
    sitename = "HypothesisTestsExtra.jl",
    modules  = [HypothesisTestsExtra],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        sidebar_sitename = false
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Welch ANOVA & Fisher RxC" => "man/welch_fisher.md",
            "Post-Hoc Analysis Guide" => "man/posthoc_theory.md",
            "DataFrame Integration" => "man/dataframes.md",
        ],
        "API Reference" => "lib/public.md"
    ],
    warnonly=true,
    # remotes = nothing
)

deploydocs(
    repo = "github.com/songtaogui/HypothesisTestsExtra.jl.git",
    devbranch = "master"
)