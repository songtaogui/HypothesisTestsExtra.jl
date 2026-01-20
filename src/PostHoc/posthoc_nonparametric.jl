# PostHoc/posthoc_nonparametric.jl

# ==============================================================================
# Non-Parametric Post-hoc (Kruskal-Wallis)
# ==============================================================================

"""
    PostHocNonPar(groups; method=:dunn_bonferroni, alpha=0.05, cld=false, pairs=nothing, row_labels=[])

Perform non-parametric post-hoc pairwise comparisons on a set of data groups. 
This function is typically used after a significant Kruskal-Wallis test to determine which specific groups differ. It operates on the **ranks** of the data rather than the raw values.

# Arguments
- `groups::AbstractVector{<:AbstractVector{<:Real}}`: A vector of vectors, where each inner vector contains the numerical observations for a specific group.

# Keyword Arguments
- `method::Symbol`: The post-hoc algorithm to use. Defaults to `:dunn_bonferroni`. See the **Supported Methods** section below for details.
- `alpha::Float64`: The significance level (Type I error rate). Defaults to `0.05`.
- `cld::Bool`: If `true`, generates Compact Letter Display (CLD) codes based on the rank comparisons. Groups sharing the same letter are not significantly different. Defaults to `false`.
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of group indices to compare. If `nothing` (default), all possible pairwise combinations are tested.
- `row_labels`: Optional vector of strings to label the groups in the output. If empty, defaults to "Group1", "Group2", etc.

# Supported Methods
The `method` argument accepts the following symbols. All methods automatically apply a tie correction factor to the standard error if ties are present in the data.

**1. Dunn's Test (Z-test based):**
Dunn's test approximates the distribution of the difference in mean ranks using a normal distribution (Z-test). It allows for various p-value adjustment methods to control the Family-Wise Error Rate (FWER).
*   `:dunn`: **Unadjusted Dunn's Test**.
    Performs raw comparisons without correcting for multiple testing. High power but high risk of Type I errors (false positives).
*   `:dunn_bonferroni` (Default): **Dunn's Test with Bonferroni Correction**.
    Adjusts p-values by multiplying by the number of tests. Strict FWER control, conservative.
*   `:dunn_sidak`: **Dunn's Test with Sidak Correction**.
    Adjusts p-values using `1 - (1 - p)^m`. Slightly more powerful than Bonferroni while maintaining FWER control.

**2. Nemenyi Test (Studentized Range based):**
*   `:nemenyi`: **Nemenyi Test**.
    This is the non-parametric equivalent of Tukey's HSD. It uses the Studentized Range distribution (approximated with infinite degrees of freedom) to determine critical values. It controls FWER for all pairwise comparisons and is generally more conservative than Dunn's test, especially for large numbers of groups.

# Returns
Returns a `PostHocTestResult` object containing detailed comparison statistics (diff in mean ranks, standard error, Z/Q statistic, critical value, p-value, confidence intervals) and CLD letters if requested.

# Example

```julia
# 3 groups with different distributions
g1 = rand(10)
g2 = rand(10) .+ 2
g3 = rand(10) .+ 0.5

# Perform Dunn's test with Bonferroni correction and generate CLD letters
result = PostHocNonPar([g1, g2, g3]; method=:dunn_bonferroni, cld=true, row_labels=["Ctrl", "TrtA", "TrtB"])
```
"""
function PostHocNonPar(groups::AbstractVector{<:AbstractVector{<:Real}}; 
                        method::Symbol=:dunn_bonferroni,
                        alpha=0.05, 
                        cld=false,
                        pairs::Union{Nothing, Vector{Tuple{Int, Int}}} = nothing,
                        row_labels::Vector{String}=String[])
    
    ranked_groups, tie_corr, N = calculate_ranks(groups)
    k = length(groups)
    mean_ranks = mean.(ranked_groups)
    ns = length.(groups)
    
    if isempty(row_labels) row_labels = ["Group$i" for i in 1:k] end

    target_pairs = Vector{Tuple{Int, Int}}()
    if isnothing(pairs)
        for i in 1:k, j in (i+1):k
            push!(target_pairs, (i, j))
        end
    else
        target_pairs = pairs
    end
    
    data = KWStatData(k, N, mean_ranks, ns, tie_corr, alpha, target_pairs)
    comparisons = PostHocComparison[]
    
    if method == :dunn
        comparisons = _run_dunn(data, :none)
    elseif method == :dunn_bonferroni
        comparisons = _run_dunn(data, :bonferroni)
    elseif method == :dunn_sidak
        comparisons = _run_dunn(data, :sidak)
    elseif method == :nemenyi
        comparisons = _run_nemenyi(data)
    else
        error("Unknown KW method :$method. Supported: :dunn, :dunn_bonferroni, :dunn_sidak, :nemenyi")
    end
    
    letters = Dict{Int, String}()
    if cld
        letters = generate_cld(mean_ranks, comparisons, alpha)
    end
    
    # Label Map
    label_map = Dict{Int, String}()
    for (i, l) in enumerate(row_labels)
        label_map[i] = l
    end
    
    return PostHocTestResult(method, comparisons, alpha, cld, letters, label_map)
end

# Vararg constructor to match HypothesisTests style
PostHocNonPar(groups::AbstractVector{<:Real}...; kwargs...) = PostHocNonPar([groups...]; kwargs...)

struct KWStatData
    k::Int
    n_total::Int
    mean_ranks::Vector{Float64}
    ns::Vector{Int}
    tie_correction::Float64
    alpha::Float64
    pairs::Vector{Tuple{Int, Int}}
end

function calculate_ranks(groups::AbstractVector{<:AbstractVector{<:Real}})
    data_flat = Float64[]
    group_ids = Int[]
    for (i, g) in enumerate(groups)
        append!(data_flat, g)
        append!(group_ids, fill(i, length(g)))
    end
    
    N = length(data_flat)
    p = sortperm(data_flat)
    sorted_data = data_flat[p]
    ranks = zeros(Float64, N)
    
    i = 1
    while i <= N
        j = i
        while j < N && sorted_data[j+1] == sorted_data[i]
            j += 1
        end
        avg_rank = (i + j) / 2.0
        for k in i:j
            ranks[p[k]] = avg_rank
        end
        i = j + 1
    end
    
    counts = Dict{Float64, Int}()
    for x in data_flat
        counts[x] = get(counts, x, 0) + 1
    end
    
    sum_T = 0.0
    for t in values(counts)
        if t > 1
            sum_T += (t^3 - t)
        end
    end
    tie_corr = 1.0 - sum_T / (N^3 - N)
    if tie_corr == 0 
        tie_corr = 1.0 
    end

    group_ranks = [Float64[] for _ in 1:length(groups)]
    for idx in 1:N
        gid = group_ids[idx]
        push!(group_ranks[gid], ranks[idx])
    end
    
    return group_ranks, tie_corr, N
end

function _run_dunn(d::KWStatData, adjustment::Symbol)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    base_variance = (d.n_total * (d.n_total + 1) / 12.0) * d.tie_correction
    
    adj_alpha = d.alpha
    note_str = "None"
    
    if adjustment == :bonferroni
        adj_alpha = d.alpha / num_tests
        note_str = "Bonferroni"
    elseif adjustment == :sidak
        adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
        note_str = "Sidak"
    end
    
    dist = Normal(0, 1)
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in d.pairs
        diff = d.mean_ranks[i] - d.mean_ranks[j]
        se = sqrt(base_variance * (1/d.ns[i] + 1/d.ns[j]))
        z_stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, z_stat)
        
        final_pval = raw_pval
        if adjustment == :bonferroni
            final_pval = min(1.0, raw_pval * num_tests)
        elseif adjustment == :sidak
            final_pval = 1.0 - (1.0 - raw_pval)^num_tests
        end
        
        margin = crit * se
        push!(comparisons, PostHocComparison(
            i, j, diff, se, z_stat, crit, final_pval, 
            diff - margin, diff + margin, final_pval < d.alpha, "Adj: $note_str"
        ))
    end
    return comparisons
end

function _run_nemenyi(d::KWStatData)
    comparisons = PostHocComparison[]
    k = d.k
    base_variance = (d.n_total * (d.n_total + 1) / 12.0) * d.tie_correction
    q_crit = Rmath.qtukey(1.0 - d.alpha, k, Inf, 1)
    crit_val_scaled = q_crit / sqrt(2)
    
    for (i, j) in d.pairs
        diff = d.mean_ranks[i] - d.mean_ranks[j]
        se = sqrt(base_variance * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se 
        pval = 1.0 - Rmath.ptukey(stat * sqrt(2), k, Inf, 1)
        margin = crit_val_scaled * se
        push!(comparisons, PostHocComparison(
            i, j, diff, se, stat, crit_val_scaled, pval, 
            diff - margin, diff + margin, pval < d.alpha, "Nemenyi"
        ))
    end
    return comparisons
end
