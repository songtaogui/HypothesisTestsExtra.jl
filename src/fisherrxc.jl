# fisherrxc.jl 

function lgamma(x) logabsgamma(x)[1] end

"""
    FisherExactTestMC(tbl::AbstractMatrix{<:Integer})

Internal struct for performing Monte Carlo Fisher's exact test on R x C tables.
Users should generally use `FisherExactTestRxC` which automatically selects
between this and the exact 2x2 test.
"""
struct FisherExactTestMC <: HypothesisTest
    tbl::AbstractMatrix{Int}
    log_prob_obs::Float64 

    function FisherExactTestMC(tbl::AbstractMatrix{<:Integer})
        # Calculate the sum of log factorials for the observed table.
        # This metric is inversely proportional to the probability of the table.
        l_obs = sum(lgamma.(tbl .+ 1))
        new(convert(Matrix{Int}, tbl), l_obs)
    end
end

"""
    FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})

A smart constructor that acts as a drop-in replacement for Fisher's Exact Test.

- If `tbl` is **2x2**, it returns a standard `HypothesisTests.FisherExactTest` object 
  (calculating the exact p-value deterministically and supporting Odds Ratio CI).
- If `tbl` is **RxC** (where R>2 or C>2), it returns a `FisherExactTestMC` object 
  (estimating the p-value via Monte Carlo simulation).
"""
function FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})
    r, c = size(tbl)
    if r == 2 && c == 2
        # fallback to HypothesisTests.FisherExactTest
        return FisherExactTest(vec(tbl')...)
    else
        return FisherExactTestMC(tbl)
    end
end

HypothesisTests.testname(::FisherExactTestMC) = "Fisher's Exact Test for RxC Tables (Monte Carlo)"
# The parameter of interest here is the P-value itself, as we are estimating it.
HypothesisTests.population_param_of_interest(x::FisherExactTestMC) = ("P-value", 0.0, NaN)
HypothesisTests.default_tail(test::FisherExactTestMC) = :right 

function HypothesisTests.show_params(io::IO, x::FisherExactTestMC, ident="")
    println(io, ident, "contingency table (size $(size(x.tbl))):")
    Base.print_matrix(io, x.tbl, repeat(ident, 2))
    println(io)
end

"""
    _simulate_fisher_mc(x::FisherExactTestMC, n_sim::Int, burnin::Int)

Internal helper function to run the Monte Carlo simulation.
Returns the number of sampled tables that are more extreme than or equal to the observed table.
"""
function _simulate_fisher_mc(x::FisherExactTestMC, n_sim::Int, burnin::Int)
    rows, cols = size(x.tbl)
    current_tbl = copy(x.tbl)
    
    # Metric: sum(log(n!)). 
    # Fisher probability P(T) ~ 1 / product(n_ij!).
    # Therefore, log(P(T)) ~ -sum(lgamma(n_ij + 1)).
    # Higher sum(lgamma) means Lower Probability (More Extreme).
    threshold = x.log_prob_obs
    
    count_extreme = 0
    
    # 1. Burn-in phase
    for _ in 1:burnin
        _perform_swap!(current_tbl, rows, cols)
    end
    
    # 2. Sampling phase
    for i in 1:n_sim
        _perform_swap!(current_tbl, rows, cols)
        current_metric = sum(lgamma.(current_tbl .+ 1))
        
        # Check if "more extreme or equal" (Higher sum of log facts)
        if current_metric >= threshold - 1e-10
            count_extreme += 1
        end
    end
    
    return count_extreme
end

"""
    pvalue(x::FisherExactTestMC; n_sim::Int=100_000, burnin::Int=10000)

Estimate the p-value using Monte Carlo simulation for RxC tables.
The estimate uses the add-one smoothing rule: (k + 1) / (N + 1).
"""
function StatsAPI.pvalue(x::FisherExactTestMC; n_sim::Int=100_000, burnin::Int=10000)
    count_extreme = _simulate_fisher_mc(x, n_sim, burnin)
    return (count_extreme + 1) / (n_sim + 1)
end

"""
    confint(x::FisherExactTestMC; level::Float64=0.95, n_sim::Int=100_000, burnin::Int=10000)

Compute the confidence interval for the **estimated p-value** obtained via Monte Carlo simulation.

Since the p-value for RxC tables is estimated stochastically, this function returns the 
confidence interval reflecting the Monte Carlo sampling error (using the Normal approximation 
of the Binomial proportion).

Arguments:
- `level`: The confidence level (default 0.95).
- `n_sim`: Number of Monte Carlo simulations.
- `burnin`: Number of burn-in steps for the Markov Chain.

Returns:
- A tuple `(lower, upper)` representing the confidence interval for the p-value.
"""
function StatsAPI.confint(x::FisherExactTestMC; level::Float64=0.95, n_sim::Int=100_000, burnin::Int=10000)
    # Warn the user that this CI is for the p-value estimate, not the Odds Ratio.
    # @warn "The returned confidence interval for FisherExactTestMC reflects the sampling error of the Monte Carlo simulation for the P-value. It does not represent a confidence interval for an effect size measure (such as the Odds Ratio)."

    # Run the simulation to get the count of extreme tables
    count_extreme = _simulate_fisher_mc(x, n_sim, burnin)
    
    # Point estimate of the p-value (using add-one smoothing)
    p_hat = (count_extreme + 1) / (n_sim + 1)
    
    # Calculate Standard Error of the proportion
    # SE = sqrt( p * (1-p) / N )
    se = sqrt(p_hat * (1.0 - p_hat) / (n_sim + 1))
    
    # Calculate Z-score for the given confidence level
    # e.g., for 95% level, alpha = 0.05, we want z at 0.975
    alpha = 1.0 - level
    z = quantile(Normal(), 1.0 - (alpha / 2.0))
    
    # Calculate margins
    margin = z * se
    
    lower = max(0.0, p_hat - margin)
    upper = min(1.0, p_hat + margin)
    
    return (lower, upper)
end


# --- Helper Functions ---

"""
    _perform_swap!(tbl::AbstractMatrix{Int}, R::Int, C::Int)

Performs a random swap on the contingency table preserving row and column sums.
This implements the Markov Chain step.
"""
function _perform_swap!(tbl::AbstractMatrix{Int}, R::Int, C::Int)
    r1 = rand(1:R); r2 = rand(1:R)
    while r1 == r2; r2 = rand(1:R); end
    
    c1 = rand(1:C); c2 = rand(1:C)
    while c1 == c2; c2 = rand(1:C); end
    
    a = tbl[r1, c1]; b = tbl[r1, c2]
    c = tbl[r2, c1]; d = tbl[r2, c2]
    
    min_k = -min(a, d)
    max_k = min(b, c)
    
    if min_k >= max_k
        return 
    end
    
    k = rand(min_k:max_k)
    
    if k != 0
        tbl[r1, c1] += k; tbl[r1, c2] -= k
        tbl[r2, c1] -= k; tbl[r2, c2] += k
    end
end
