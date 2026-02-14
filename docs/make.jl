using Documenter
using DocumenterVitepress
using HypothesisTestsExtra
using DataFrames

makedocs(
    sitename = "HypothesisTestsExtra.jl",
    modules  = [HypothesisTestsExtra],
    # format   = Documenter.HTML(
    #     prettyurls = get(ENV, "CI", nothing) == "true",
    #     sidebar_sitename = false
    # ),
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/songtaogui/HypothesisTestsExtra.jl",
        devbranch = "master",
        devurl = "dev"
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Quick start" => "man/getstarted.md",
            "Additional Test methods" => "man/newtests.md",
            "Post-Hoc Analysis Guide" => "man/posthoc_theory.md",
            "DataFrame Integration" => "man/dataframes.md",
        ],
        "API Reference" => "lib/public.md"
    ],
    warnonly=true,
    # remotes = nothing
),

# deploydocs(
#     repo = "github.com/songtaogui/HypothesisTestsExtra.jl.git",
#     devbranch = "master"
# )

DocumenterVitepress.deploydocs(;
    repo = "github.com/songtaogui/HypothesisTestsExtra.jl",
    target = joinpath(@__DIR__, "build"),
    branch = "gh-pages",
    devbranch = "master",
    push_preview = true,
)