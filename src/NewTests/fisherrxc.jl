# src/NewTests/fisherrxc.jl

# This implementation provides a unified Fisher exact test interface for
# both 2x2 tables (exact enumeration delegated to HypothesisTests.FisherExactTest)
# and general RxC tables (Monte Carlo under fixed margins).

const _FISHER_MODE_EXACT2X2 = :exact2x2
const _FISHER_MODE_MC = :mc

_lgamma(x::Real) = logabsgamma(x)[1]

"""
    FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})

Unified Fisher exact test object for contingency tables.

- For 2x2 tables, this object wraps `HypothesisTests.FisherExactTest` and uses exact p-values.
- For RxC tables (R>2 or C>2), this object stores the observed table and supports
  Monte Carlo p-value estimation under fixed margins.

Use:
- `pvalue(test; kwargs...)`
- `confint(test; kwargs...)`

For Monte Carlo mode:
- `pvalue(test; n_sim=100_000, burnin=10_000, thin=1)`
- `confint(test; level=0.95, n_sim=100_000, burnin=10_000, thin=1)`
"""
struct FisherExactTestRxC <: HypothesisTest
    mode::Symbol
    tbl::Matrix{Int}
    exact2x2::Union{Nothing, FisherExactTest}
    log_denom_obs::Float64
end

"""
    FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})

Constructor with input validation and automatic mode selection.
"""
function FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})
    r, c = size(tbl)
    r >= 2 || throw(ArgumentError("table must have at least 2 rows, got $r"))
    c >= 2 || throw(ArgumentError("table must have at least 2 columns, got $c"))

    t = Matrix{Int}(tbl)
    any(t .< 0) && throw(ArgumentError("table counts must be non-negative integers"))
    sum(t) > 0 || throw(ArgumentError("table total count must be positive"))

    if r == 2 && c == 2
        exact = FisherExactTest(vec(t')...)
        return FisherExactTestRxC(_FISHER_MODE_EXACT2X2, t, exact, NaN)
    else
        # Under fixed margins, probability is proportional to 1/prod(n_ij!).
        # We store sum(log(n_ij!)) as a monotone "rarity" score.
        log_denom_obs = sum(_lgamma.(t .+ 1))
        return FisherExactTestRxC(_FISHER_MODE_MC, t, nothing, log_denom_obs)
    end
end

HypothesisTests.testname(::FisherExactTestRxC) = "Fisher's Exact Test for Contingency Tables"

function HypothesisTests.population_param_of_interest(x::FisherExactTestRxC)
    if x.mode == _FISHER_MODE_EXACT2X2
        return ("Odds ratio (ω)", 1.0, NaN)
    else
        return ("P-value", 0.0, NaN)
    end
end

HypothesisTests.default_tail(::FisherExactTestRxC) = :right

function HypothesisTests.show_params(io::IO, x::FisherExactTestRxC, ident="")
    println(io, ident, "contingency table (size $(size(x.tbl))):")
    Base.print_matrix(io, x.tbl, repeat(ident, 2))
    println(io)
    if x.mode == _FISHER_MODE_EXACT2X2
        println(io, ident, "mode: exact 2x2")
    else
        println(io, ident, "mode: Monte Carlo RxC")
    end
end

"""
    _fisher_log_denom(tbl::AbstractMatrix{<:Integer})

Compute sum(log(n_ij!)), a monotone transform of rarity under fixed margins.
Larger values indicate lower table probability (up to a constant).
"""
_fisher_log_denom(tbl::AbstractMatrix{<:Integer}) = sum(_lgamma.(tbl .+ 1))

"""
    _propose_switch_step!(tbl::Matrix{Int}, R::Int, C::Int)

One proposal step on a random 2x2 submatrix preserving row/column margins.
The proposal is symmetric and accepted unconditionally, yielding a valid
ergodic chain over tables with fixed margins (for connected support).
"""
function _propose_switch_step!(tbl::Matrix{Int}, R::Int, C::Int)
    r1 = rand(1:R)
    r2 = rand(1:R)
    while r1 == r2
        r2 = rand(1:R)
    end

    c1 = rand(1:C)
    c2 = rand(1:C)
    while c1 == c2
        c2 = rand(1:C)
    end

    a = tbl[r1, c1]
    b = tbl[r1, c2]
    c = tbl[r2, c1]
    d = tbl[r2, c2]

    min_k = -min(a, d)
    max_k = min(b, c)

    # No feasible move on this chosen 2x2 block.
    if min_k > max_k
        return false
    end

    # Include k=0 to keep proposal symmetric and aperiodic.
    k = rand(min_k:max_k)
    if k == 0
        return true
    end

    tbl[r1, c1] += k
    tbl[r1, c2] -= k
    tbl[r2, c1] -= k
    tbl[r2, c2] += k
    return true
end

"""
    FisherMCSummary

Container for Monte Carlo result reuse across p-value and confidence interval.
"""
struct FisherMCSummary
    n_sim::Int
    n_extreme::Int
    p_hat::Float64
end

"""
    mc_result(x::FisherExactTestRxC; n_sim=100_000, burnin=10_000, thin=1)

Run Monte Carlo simulation for RxC mode and return a reusable summary.

"Extreme" means the sampled table has probability <= observed table probability,\nequivalently sum(log(n_ij!)) >= observed sum(log(n_ij!)).
"""
function mc_result(x::FisherExactTestRxC; n_sim::Int=100_000, burnin::Int=10_000, thin::Int=1)
    x.mode == _FISHER_MODE_MC || throw(ArgumentError("mc_result is only defined for RxC Monte Carlo mode"))
    n_sim > 0 || throw(ArgumentError("n_sim must be > 0"))
    burnin >= 0 || throw(ArgumentError("burnin must be >= 0"))
    thin > 0 || throw(ArgumentError("thin must be > 0"))

    rows, cols = size(x.tbl)
    current_tbl = copy(x.tbl)
    threshold = x.log_denom_obs
    n_extreme = 0

    for _ in 1:burnin
        _propose_switch_step!(current_tbl, rows, cols)
    end

    for _ in 1:n_sim
        for __ in 1:thin
            _propose_switch_step!(current_tbl, rows, cols)
        end
        m = _fisher_log_denom(current_tbl)
        if m >= threshold - 1e-12
            n_extreme += 1
        end
    end

    p_hat = (n_extreme + 1) / (n_sim + 1)
    return FisherMCSummary(n_sim, n_extreme, p_hat)
end

"""
    StatsAPI.pvalue(x::FisherExactTestRxC; kwargs...)

Unified p-value interface.

- 2x2 mode: delegated exact p-value from wrapped FisherExactTest.
- RxC mode: Monte Carlo estimate with add-one smoothing.
"""
function StatsAPI.pvalue(x::FisherExactTestRxC; n_sim::Int=100_000, burnin::Int=10_000, thin::Int=1)
    if x.mode == _FISHER_MODE_EXACT2X2
        return pvalue(x.exact2x2)
    else
        s = mc_result(x; n_sim=n_sim, burnin=burnin, thin=thin)
        return s.p_hat
    end
end

"""
    _clopper_pearson(k::Int, n::Int, level::Float64)

Exact binomial confidence interval using Clopper-Pearson method.
"""
function _clopper_pearson(k::Int, n::Int, level::Float64)
    (0.0 < level < 1.0) || throw(ArgumentError("level must be in (0,1)"))
    0 <= k <= n || throw(ArgumentError("require 0 <= k <= n"))

    α = 1.0 - level
    lower = (k == 0) ? 0.0 : quantile(Beta(k, n - k + 1), α / 2)
    upper = (k == n) ? 1.0 : quantile(Beta(k + 1, n - k), 1.0 - α / 2)
    return (lower, upper)
end

"""
    StatsAPI.confint(x::FisherExactTestRxC; kwargs...)

Unified confidence interval interface.

- 2x2 mode: delegated to wrapped exact test confidence interval (odds ratio CI).
- RxC mode: confidence interval for Monte Carlo p-value estimation error
  via exact Binomial (Clopper-Pearson), based on the simulated extreme count.
"""
function StatsAPI.confint(x::FisherExactTestRxC; level::Float64=0.95, n_sim::Int=100_000, burnin::Int=10_000, thin::Int=1)
    if x.mode == _FISHER_MODE_EXACT2X2
        return confint(x.exact2x2; level=level)
    else
        s = mc_result(x; n_sim=n_sim, burnin=burnin, thin=thin)
        # n_extreme among n_sim Bernoulli trials.
        return _clopper_pearson(s.n_extreme, s.n_sim, level)
    end
end
