# welch.jl

# ==============================================================================
# Welch's ANOVA
# ==============================================================================

"""
    WelchANOVATest(groups)
    WelchANOVATest(groups::AbstractVector{<:Real}...)
    WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's ANOVA test of the hypothesis that the `groups` means are equal.
This test is an alternative to the standard One-Way ANOVA when the assumption of 
equal variances (homoscedasticity) is violated.

The test statistic is approximately F-distributed.

Implements: [`pvalue`](@ref)

# Example

```julia
# input arrays
WelchANOVATest(randn(10), randn(15).+1, randn(12).+2)

# input DataFrame
using StatsBase, DataFrames
cdf = DataFrame(A = sample(["G1","G2"], 100), B = sample(randn(10), 100))
WelchANOVATest(cdf, :A, :B)
```
# External links
  * [Welch's t-test and ANOVA on Wikipedia](https://en.wikipedia.org/wiki/Welch%27s_t-test)
"""
struct WelchANOVATest <: HypothesisTest
    Nᵢ::Vector{Int}      # Sample sizes
    F::Float64           # Test statistic
    df1::Float64         # Numerator degrees of freedom
    df2::Float64         # Denominator degrees of freedom (fractional)
end

function WelchANOVATest(groups::AbstractVector{<:AbstractVector{<:Real}})
    k = length(groups)
    if k < 2
        throw(ArgumentError("WelchANOVATest requires at least 2 groups"))
    end
    
    # Calculate basic statistics
    Nᵢ = length.(groups)
    mᵢ = mean.(groups)
    vᵢ = var.(groups)
    
    # Weights
    wᵢ = Nᵢ ./ vᵢ
    W = sum(wᵢ)
    
    # Weighted grand mean
    m_prime = sum(wᵢ .* mᵢ) / W
    
    # Between-group variance component (Numerator)
    numerator = sum(wᵢ .* (mᵢ .- m_prime).^2) / (k - 1)
    
    # Lambda for denominator correction
    # Note: Using formula consistent with standard Welch ANOVA implementations
    Λ = sum((1 ./ (Nᵢ .- 1)) .* (1 .- wᵢ ./ W).^2)
    denom_correction = 1 + (2 * (k - 2) / (k^2 - 1)) * Λ
    
    F_stat = numerator / denom_correction
    df1 = k - 1
    df2 = (k^2 - 1) / (3 * Λ)
    
    WelchANOVATest(Nᵢ, F_stat, df1, df2)
end

# Vararg constructor to match HypothesisTests style
WelchANOVATest(groups::AbstractVector{<:Real}...) = WelchANOVATest([groups...])

# ==============================================================================
# Interface Implementation (Consistency with HypothesisTests.jl)
# ==============================================================================

# Metadata
HypothesisTests.testname(::WelchANOVATest) = "Welch's ANOVA test (Unequal Variances)"
HypothesisTests.population_param_of_interest(::WelchANOVATest) = ("Means", "all equal", NaN)
HypothesisTests.teststatisticname(::WelchANOVATest) = "F"

# StatsAPI methods
StatsAPI.nobs(t::WelchANOVATest) = t.Nᵢ
StatsAPI.dof(t::WelchANOVATest) = (t.df1, t.df2)

# Accessor for the statistic
HypothesisTests.teststatistic(t::WelchANOVATest) = t.F

# P-value calculation (computed on demand, consistent with other tests)
StatsAPI.pvalue(t::WelchANOVATest; tail=:right) = 
    pvalue(FDist(t.df1, t.df2), t.F; tail=tail)

# ==============================================================================
# Show Methods (Output Formatting)
# ==============================================================================

# 1. Helper function for consistent parameter display
function HypothesisTests.show_params(io::IO, t::WelchANOVATest, indent="")
    println(io, indent, "number of observations: ", nobs(t))
    println(io, indent, rpad("$(HypothesisTests.teststatisticname(t)) statistic:", 24), HypothesisTests.teststatistic(t))
    println(io, indent, "degrees of freedom:     ", dof(t))
end

# 2. Standard REPL display
function Base.show(io::IO, t::WelchANOVATest)
    println(io, HypothesisTests.testname(t))
    println(io, repeat("-", length(HypothesisTests.testname(t))))
    
    # Use the standard HypothesisTests parameter display
    println(io, "Population details:")
    println(io, "    parameter of interest:   ", HypothesisTests.population_param_of_interest(t)[1])
    println(io, "    value under h_0:         ", "\"$(HypothesisTests.population_param_of_interest(t)[2])\"")
    println(io, "    point estimate:          ", HypothesisTests.population_param_of_interest(t)[3])
    println(io, "")
    println(io, "Test summary:")
    println(io, "    outcome with 95% confidence: ", pvalue(t) < 0.05 ? "reject h_0" : "fail to reject h_0")
    println(io, "    two-sided p-value:           ", pvalue(t))
    println(io, "")
    println(io, "Details:")
    HypothesisTests.show_params(io, t, "    ")
end
