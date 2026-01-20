# PostHoc/posthoc_parametric.jl

# ==============================================================================
# Parametric Post-hoc Algorithms
# ==============================================================================

# Helper to iterate only over requested pairs
function _iter_pairs(d::StatData)
    return d.pairs
end

# --- LSD ---
function _run_lsd(d::StatData)
    comparisons = PostHocComparison[]
    dist = TDist(d.df_resid)
    crit = quantile(dist, 1 - d.alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        pval = 2 * ccdf(dist, stat)
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Bonferroni ---
function _run_bonferroni(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    
    dist = TDist(d.df_resid)
    adj_alpha = d.alpha / num_tests
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = min(1.0, raw_pval * num_tests)
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "m=$num_tests"))
    end
    return comparisons
end

# --- Sidak ---
function _run_sidak(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    
    dist = TDist(d.df_resid)
    adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = 1.0 - (1.0 - raw_pval)^num_tests
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "m=$num_tests"))
    end
    return comparisons
end

# --- Scheffe ---
function _run_scheffe(d::StatData)
    comparisons = PostHocComparison[]
    f_dist = FDist(d.k-1, d.df_resid)
    crit = sqrt((d.k-1) * quantile(f_dist, 1 - d.alpha))
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        pval = ccdf(f_dist, stat^2 / (d.k-1))
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Tukey HSD ---
function _run_tukey(d::StatData)
    comparisons = PostHocComparison[]
    q_crit = Rmath.qtukey(1.0 - d.alpha, d.k, d.df_resid, 1)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        q_stat = abs(diff) / (se / sqrt(2))
        pval = 1.0 - Rmath.ptukey(q_stat, d.k, d.df_resid, 1)
        margin = (q_crit / sqrt(2)) * se
        push!(comparisons, PostHocComparison(i, j, diff, se, q_stat, q_crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Tamhane T2 ---
function _run_tamhane(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.vars[i]/d.ns[i] + d.vars[j]/d.ns[j])
        df_pair = (d.vars[i]/d.ns[i] + d.vars[j]/d.ns[j])^2 / 
                  ((d.vars[i]/d.ns[i])^2/(d.ns[i]-1) + (d.vars[j]/d.ns[j])^2/(d.ns[j]-1))
        
        dist = TDist(df_pair)
        crit = quantile(dist, 1 - adj_alpha/2)
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = 1.0 - (1.0 - raw_pval)^num_tests
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "Welch+Sidak"))
    end
    return comparisons
end

# --- SNK & Duncan ---
function _run_stepwise(d::StatData, type::Symbol)
    comparisons = PostHocComparison[]
    sorted_idx = sortperm(d.means) 
    n_harmonic = d.k / sum(1 ./ d.ns)
    se_stepwise = sqrt(d.mse / n_harmonic) 
    
    sig_map = Dict{Tuple{Int, Int}, Bool}()
    all_comps = PostHocComparison[]
    
    for p in d.k:-1:2
        for i in 1:(d.k - p + 1)
            j = i + p - 1
            idx_low = sorted_idx[i]
            idx_high = sorted_idx[j]
            
            real_diff = d.means[idx_high] - d.means[idx_low]
            abs_diff = abs(real_diff)
            real_se = sqrt(d.mse * (1/d.ns[idx_low] + 1/d.ns[idx_high]))
            
            q_stat = abs_diff / se_stepwise 
            
            if type == :snk
                q_crit = Rmath.qtukey(1.0 - d.alpha, p, d.df_resid, 1)
            else # :duncan
                alpha_p = 1.0 - (1.0 - d.alpha)^(p - 1)
                q_crit = Rmath.qtukey(1.0 - alpha_p, p, d.df_resid, 1)
            end
            
            is_sig_calc = q_stat > q_crit
            
            # Protection logic
            is_protected = false
            if p < d.k
                if j < d.k && haskey(sig_map, (i, j+1)) && !sig_map[(i, j+1)]
                    is_protected = true
                end
                if i > 1 && haskey(sig_map, (i-1, j)) && !sig_map[(i-1, j)]
                    is_protected = true
                end
            end
            
            final_sig = is_sig_calc && !is_protected
            sig_map[(i, j)] = final_sig
            
            pval = 1.0 - Rmath.ptukey(q_stat, p, d.df_resid, 1)
            margin = (q_crit / sqrt(2)) * real_se
            
            g1, g2 = idx_low < idx_high ? (idx_low, idx_high) : (idx_high, idx_low)
            d_val = d.means[g1] - d.means[g2]
            
            push!(all_comps, PostHocComparison(
                g1, g2, d_val, real_se, q_stat, q_crit, pval, 
                d_val - margin, d_val + margin, final_sig, "Span=$p"
            ))
        end
    end
    
    target_set = Set([(min(p[1], p[2]), max(p[1], p[2])) for p in d.pairs])
    for c in all_comps
        if (c.group1, c.group2) in target_set
            push!(comparisons, c)
        end
    end
    sort!(comparisons, by = x -> (x.group1, x.group2))
    return comparisons
end

function _run_snk(d::StatData) _run_stepwise(d, :snk) end
function _run_duncan(d::StatData) _run_stepwise(d, :duncan) end

const METHOD_DISPATCH = Dict(
    :lsd => _run_lsd,
    :bonferroni => _run_bonferroni,
    :sidak => _run_sidak,
    :scheffe => _run_scheffe,
    :tukey => _run_tukey,
    :tamhane => _run_tamhane,
    :snk => _run_snk,
    :duncan => _run_duncan
)

"""
    PostHocTest(groups; method=:tukey, alpha=0.05, alpha_levene=0.05, cld=false, pairs=nothing, row_labels=[])

Perform parametric post-hoc pairwise comparisons (Multiple Comparison Procedures) on a set of data groups.

# Arguments
- `groups::AbstractVector{<:AbstractVector{<:Real}}`: A vector of vectors, where each inner vector contains the numerical observations for a specific group.

# Keyword Arguments
- `method::Symbol`: The post-hoc algorithm to use. Defaults to `:tukey`. See the **Supported Methods** section below for details on each option.
- `alpha::Float64`: The significance level (Type I error rate) for the hypothesis tests and confidence intervals. Defaults to `0.05`.
- `alpha_levene::Float64`: The threshold used for the internal Levene's test. If the p-value of Levene's test is below this value, a warning is issued suggesting the data has unequal variances (heteroscedasticity) and recommending `:tamhane`. Defaults to `0.05`.
- `cld::Bool`: If `true`, generates Compact Letter Display (CLD) codes. Groups sharing the same letter are not significantly different. Defaults to `false`.
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of group indices to compare (e.g., `[(1, 2), (1, 3)]`). If `nothing` (default), all possible pairwise combinations are tested.
- `row_labels`: Optional vector of strings to label the groups in the output. If empty, defaults to "Group1", "Group2", etc.

# Supported Methods
The `method` argument accepts the following symbols:

**1. Equal Variance Assumed (Homoscedasticity):**
*   `:tukey` (Default): **Tukey's HSD (Honest Significant Difference)**.
    Based on the Studentized Range distribution. It controls the Family-Wise Error Rate (FWER) for all pairwise comparisons. It is the standard choice for balanced or slightly unbalanced designs.
*   `:lsd`: **Fisher's LSD (Least Significant Difference)**.
    Performs individual t-tests without FWER adjustment. It is the most powerful (least conservative) but carries a high risk of Type I errors (false positives) as the number of groups increases.
*   `:bonferroni`: **Bonferroni Correction**.
    Adjusts the significance level to `alpha / m` (where m is the number of tests). It is very conservative and strictly controls FWER, but often lacks power.
*   `:sidak`: **Sidak Correction**.
    Adjusts the significance level to `1 - (1 - alpha)^(1/m)`. It is slightly more powerful than Bonferroni while maintaining strict FWER control (assuming independence).
*   `:scheffe`: **Scheffe's Method**.
    Based on the F-distribution. It is designed to control FWER for *all possible* linear contrasts, not just pairwise comparisons. Consequently, it is extremely conservative for simple pairwise tests.
*   `:snk`: **Student-Newman-Keuls**.
    A stepwise multiple range procedure. It adjusts the critical value based on the number of steps between means. It is less conservative than Tukey but does not strictly control FWER in the strong sense.
*   `:duncan`: **Duncan's New Multiple Range Test**.
    Similar to SNK but uses a more liberal protection level. It has higher power but a higher rate of Type I errors compared to SNK or Tukey.

**2. Unequal Variance Assumed (Heteroscedasticity):**
*   `:tamhane`: **Tamhane's T2**.
    Uses Welch's t-test (which adjusts degrees of freedom for unequal variances) combined with a Sidak-like multiplicative correction for the p-value. This is the recommended method when Levene's test is significant.

# Returns
Returns a `PostHocTestResult` object containing detailed comparison statistics (diff, standard error, test statistic, critical value, p-value, confidence intervals) and CLD letters if requested.

# Example
```julia
PostHocTest([randn(10), randn(10).+5, randn(10).+0.1]; cld = true, row_labels=["Control", "TreatA", "TreatB"])
```
"""
function PostHocTest(groups::AbstractVector{<:AbstractVector{<:Real}};
                    method::Symbol=:tukey,
                    alpha=0.05, 
                    alpha_levene=0.05, 
                    cld=false,
                    pairs::Union{Nothing, Vector{Tuple{Int, Int}}} = nothing,
                    row_labels::Vector{String}=String[])
    
    if !haskey(METHOD_DISPATCH, method)
        error("Unknown method :$method. Supported: $(keys(METHOD_DISPATCH))")
    end

    # Levene's Test
    levene_res = LeveneTest(groups...; statistic=mean)
    p_levene = pvalue(levene_res)
    if p_levene < alpha_levene
        @warn @sprintf("Levene's test: Unequal variances (p=%.4f). Consider using :tamhane.", p_levene)
    end

    # Basic Stats
    k = length(groups)
    if isempty(row_labels) row_labels = ["Group$i" for i in 1:k] end
    
    means = mean.(groups)
    vars = var.(groups)
    ns = length.(groups)
    
    df_resid = sum(ns) - k
    ss_resid = sum([(ns[i]-1)*vars[i] for i in 1:k])
    mse = ss_resid / df_resid
    
    target_pairs = Vector{Tuple{Int, Int}}()
    if isnothing(pairs)
        for i in 1:k, j in (i+1):k
            push!(target_pairs, (i, j))
        end
    else
        target_pairs = pairs
    end

    data = StatData(k, means, vars, ns, mse, df_resid, alpha, target_pairs)
    comparisons = METHOD_DISPATCH[method](data)
    
    letters = Dict{Int, String}()
    if cld
        letters = generate_cld(means, comparisons, alpha)
    end
    
    # Label Map
    label_map = Dict{Int, String}()
    for (i, l) in enumerate(row_labels)
        label_map[i] = l
    end
    
    return PostHocTestResult(method, comparisons, alpha, cld, letters, label_map)
end

# Vararg constructor to match HypothesisTests style
PostHocTest(groups::AbstractVector{<:Real}...; kwargs...) = PostHocTest([groups...]; kwargs...)