# src/NewTests/trends.jl 

# --- Internal Helper for Scores ---

"""
    _get_scores(counts::AbstractVector{Int}, method::Symbol)

Calculate scores for ordinal levels.
- `:equidistant`: Assigns 1, 2, ..., k.
- `:midrank`: Assigns the average rank of observations in each level based on `counts`.
"""
function _get_scores(counts::AbstractVector{Int}, method::Symbol)
    k = length(counts)
    if method == :equidistant
        return collect(1.0:k)
    elseif method == :midrank
        n = sum(counts)
        scores = zeros(Float64, k)
        cumulative = 0
        for i in 1:k
            # Average rank: (FirstRank + LastRank) / 2
            # FirstRank = cumulative + 1, LastRank = cumulative + counts[i]
            scores[i] = cumulative + (counts[i] + 1) / 2
            cumulative += counts[i]
        end
        return scores
    else
        throw(ArgumentError("Unknown score method: $method. Use :equidistant, :midrank or provide a Vector."))
    end
end

# ==============================================================================
# 1. Cochran-Armitage Trend Test
# ==============================================================================

"""
    CochranArmitageTest(success, total; scores=:equidistant)

Perform the Cochran-Armitage test for trend in proportions. 

# Arguments
- `success`: Vector of success counts for each level.
- `total`: Vector of total counts for each level.
- `scores`: `:equidistant` (default), `:midrank`, or a `Vector{Float64}`.

Implements: `pvalue`, `confint`

# Example
```julia
success = [10, 15, 25]
total = [100, 100, 100]
test = CochranArmitageTest(success, total; scores=:equidistant)
pvalue(test)
confint(test) # Confidence interval for the slope
```
"""
struct CochranArmitageTest <: HypothesisTest
    n_success::Vector{Int}
    n_total::Vector{Int}
    scores::Vector{Float64}
    score_method::Any
    Z::Float64
    slope::Float64
    se_slope::Float64
    n::Int
end

function CochranArmitageTest(success::AbstractVector{<:Integer}, 
                             total::AbstractVector{<:Integer}; 
                             scores=:equidistant)
    k = length(success)
    actual_scores = scores isa Symbol ? _get_scores(Vector{Int}(total), scores) : Vector{Float64}(scores)
    
    R = sum(success)
    N = sum(total)
    p_bar = R / N
    
    w_bar = sum(total .* actual_scores) / N
    s_ww = sum(total .* (actual_scores .- w_bar).^2)
    
    # Linear trend slope estimate: b = sum(x_i * (p_i - p_bar)) / s_ww
    numerator_val = sum(success .* (actual_scores .- w_bar))
    
    Z = numerator_val / sqrt(p_bar * (1 - p_bar) * s_ww)
    slope = numerator_val / s_ww
    se_slope = sqrt(p_bar * (1 - p_bar) / s_ww)
    
    CochranArmitageTest(Vector(success), Vector(total), actual_scores, scores, Z, slope, se_slope, Int(N))
end

HypothesisTests.testname(::CochranArmitageTest) = "Cochran-Armitage Trend Test"
HypothesisTests.teststatisticname(::CochranArmitageTest) = "Z"
HypothesisTests.teststatistic(t::CochranArmitageTest) = t.Z
HypothesisTests.population_param_of_interest(t::CochranArmitageTest) = ("Slope", 0.0, t.slope)

StatsAPI.pvalue(t::CochranArmitageTest; tail=:both) = pvalue(Normal(), t.Z; tail=tail)

function StatsAPI.confint(t::CochranArmitageTest; level::Float64=0.95)
    alpha = 1.0 - level
    z_crit = quantile(Normal(), 1.0 - alpha/2)
    return (t.slope - z_crit * t.se_slope, t.slope + z_crit * t.se_slope)
end

function HypothesisTests.show_params(io::IO, t::CochranArmitageTest, ident="")
    println(io, ident, "Z-statistic:         ", round(t.Z, digits=4))
    println(io, ident, "Trend Slope:         ", round(t.slope, digits=6))
    println(io, ident, "Scores Method:       ", t.score_method)
    println(io, ident, "Total Observations:  ", t.n)
end

# ==============================================================================
# 2. Jonckheere-Terpstra Trend Test (with Tie Correction)
# ==============================================================================

"""
    JonckheereTerpstraTest(groups)

Perform the Jonckheere-Terpstra test for monotonic trend among k independent samples.
Includes correction for ties in the data.

Implements: `pvalue`

# Example
```julia
g1 = [10, 12, 12, 14]
g2 = [13, 15, 15, 17]
g3 = [18, 20, 22, 22]
test = JonckheereTerpstraTest([g1, g2, g3])
```
"""
struct JonckheereTerpstraTest <: HypothesisTest
    J::Float64
    Z::Float64
    n_groups::Int
    n_total::Int
end

function JonckheereTerpstraTest(groups::AbstractVector{<:AbstractVector{<:Real}})
    k = length(groups)
    nᵢ = length.(groups)
    N = sum(nᵢ)
    
    # Calculate J statistic
    J = 0.0
    for i in 1:(k-1), j in (i+1):k
        for x in groups[i], y in groups[j]
            if y > x
                J += 1.0
            elseif y == x
                J += 0.5
            end
        end
    end
    
    # Mean of J
    μ_J = (N^2 - sum(nᵢ.^2)) / 4.0
    
    # Variance of J with Tie Correction
    all_obs = vcat(groups...)
    counts = values(countmap(all_obs))
    t = collect(Int, counts) # tie sizes
    
    term1 = N*(N-1)*(2N+5)
    term2 = sum(nᵢ .* (nᵢ .- 1) .* (2nᵢ .+ 5))
    term3 = sum(t .* (t .- 1) .* (2t .+ 5))
    
    var_J = (term1 - term2 - term3) / 72.0 + 
            (sum(nᵢ .* (nᵢ .- 1) .* (nᵢ .- 2)) * sum(t .* (t .- 1) .* (t .- 2))) / (36N*(N-1)*(N-2)) +
            (sum(nᵢ .* (nᵢ .- 1)) * sum(t .* (t .- 1))) / (8N*(N-1))

    Z = (J - μ_J) / sqrt(var_J)
    
    JonckheereTerpstraTest(J, Z, k, Int(N))
end

HypothesisTests.testname(::JonckheereTerpstraTest) = "Jonckheere-Terpstra Trend Test"
HypothesisTests.teststatisticname(::JonckheereTerpstraTest) = "J"
HypothesisTests.teststatistic(t::JonckheereTerpstraTest) = t.J

StatsAPI.pvalue(t::JonckheereTerpstraTest; tail=:both) = pvalue(Normal(), t.Z; tail=tail)

function HypothesisTests.show_params(io::IO, t::JonckheereTerpstraTest, ident="")
    println(io, ident, "J-statistic:         ", t.J)
    println(io, ident, "Standardized Z:      ", round(t.Z, digits=4))
    println(io, ident, "Tie-corrected:       Yes")
end

# ==============================================================================
# 3. Linear-by-Linear Association Test
# ==============================================================================

"""
    LinearByLinearTest(tbl; row_scores=:equidistant, col_scores=:equidistant)

Perform the Linear-by-Linear Association test for RxC contingency tables.

Implements: `pvalue`, `confint`

`confint(t::LinearByLinearTest; level=0.95)`: Returns the confidence interval for the Pearson correlation coefficient `r` 
using Fisher's Z-transformation.

# Example
```julia
tbl = [10 5 2; 3 8 12; 1 2 15]
test = LinearByLinearTest(tbl; row_scores=:midrank)
confint(test) # Confidence interval for Pearson correlation r
```
"""
struct LinearByLinearTest <: HypothesisTest
    M2::Float64
    r::Float64
    n::Int
    row_score_method::Any
    col_score_method::Any
end

function LinearByLinearTest(tbl::AbstractMatrix{<:Integer}; 
                            row_scores=:equidistant, 
                            col_scores=:equidistant)
    r_dim, c_dim = size(tbl)
    row_marg = sum(tbl, dims=2)[:]
    col_marg = sum(tbl, dims=1)[:]
    
    s_row = row_scores isa Symbol ? _get_scores(row_marg, row_scores) : Vector{Float64}(row_scores)
    s_col = col_scores isa Symbol ? _get_scores(col_marg, col_scores) : Vector{Float64}(col_scores)
    
    N = sum(tbl)
    
    μ_u = sum(row_marg .* s_row) / N
    μ_v = sum(col_marg .* s_col) / N
    
    σ2_u = sum(row_marg .* (s_row .- μ_u).^2) / (N - 1)
    σ2_v = sum(col_marg .* (s_col .- μ_v).^2) / (N - 1)
    
    cov_uv = 0.0
    for i in 1:r_dim, j in 1:c_dim
        cov_uv += tbl[i,j] * (s_row[i] - μ_u) * (s_col[j] - μ_v)
    end
    cov_uv /= (N - 1)
    
    pearson_r = cov_uv / (sqrt(σ2_u) * sqrt(σ2_v))
    M2 = (N - 1) * pearson_r^2
    
    LinearByLinearTest(M2, pearson_r, Int(N), row_scores, col_scores)
end

HypothesisTests.testname(::LinearByLinearTest) = "Linear-by-Linear Association Test"
HypothesisTests.teststatisticname(::LinearByLinearTest) = "M²"
HypothesisTests.teststatistic(t::LinearByLinearTest) = t.M2
HypothesisTests.population_param_of_interest(t::LinearByLinearTest) = ("Pearson Correlation", 0.0, t.r)

StatsAPI.pvalue(t::LinearByLinearTest) = pvalue(Chisq(1), t.M2; tail=:right)


function StatsAPI.confint(t::LinearByLinearTest; level::Float64=0.95)
    # Fisher Z-transform
    z = 0.5 * log((1 + t.r) / (1 - t.r))
    se = 1.0 / sqrt(t.n - 3)
    
    alpha = 1.0 - level
    z_crit = quantile(Normal(), 1.0 - alpha/2)
    
    low_z, high_z = z - z_crit*se, z + z_crit*se
    
    return (tanh(low_z), tanh(high_z))
end

function HypothesisTests.show_params(io::IO, t::LinearByLinearTest, ident="")
    println(io, ident, "M² statistic:        ", round(t.M2, digits=4))
    println(io, ident, "Pearson correlation: ", round(t.r, digits=4))
    println(io, ident, "Row Score Method:    ", t.row_score_method)
    println(io, ident, "Col Score Method:    ", t.col_score_method)
    println(io, ident, "Sample size:         ", t.n)
end
