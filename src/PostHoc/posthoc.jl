# src/PostHoc/posthoc.jl

include("types.jl")
include("utils/pvalue_adj.jl")
include("utils/labels.jl")
include("utils/ranking.jl")
include("utils/cld_logic.jl")
include("engines/parametric.jl")
include("engines/nonparametric.jl")
include("engines/contingency.jl")


"""
    PostHocPar(groups; method=:tukey, alpha=0.05, alpha_levene=0.05, cld=false, pairs=nothing, row_labels=[])

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
PostHocPar([randn(10), randn(10).+5, randn(10).+0.1]; cld = true, row_labels=["Control", "TreatA", "TreatB"])
```
"""
function PostHocPar(groups::AbstractVector{<:AbstractVector{<:Real}};
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
PostHocPar(groups::AbstractVector{<:Real}...; kwargs...) = PostHocPar([groups...]; kwargs...)# src/PostHoc/posthoc_structures.jl


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


"""
    PostHocContingencyCell(table::AbstractMatrix{<:Integer}; method=:asr, adjustment=:bonferroni, alpha=0.05, row_labels=[], col_labels=[])

Perform cell-level post-hoc analysis on a contingency table to identify specific cells that contribute significantly to the overall association.

# Arguments
- `table`: RxC contingency table (Matrix of Integers).
- `method`: 
    - `:asr`: Adjusted Standardized Residuals. Tests if a cell deviates from independence.
    - `:fisher_1vsall`: Fisher's Exact Test for each cell (One vs Rest).
- `adjustment::Symbol`: The method to adjust p-values for multiple comparisons.
    - `:bonferroni`: Strong control of FWER (p * m).
    - `:bh` (or `:fdr`): Benjamini-Hochberg procedure for False Discovery Rate control.
    - `:none`: No adjustment.
- `row_labels`: Optional vector of strings for row names.
- `col_labels`: Optional vector of strings for column names.

# Returns
A `ContingencyCellTestResult` object containing matrices for statistics, raw p-values, adjusted p-values, and significance flags.

# Examples

```julia
using HypothesisTests, Distributions

# Create a 3x3 contingency table (e.g., 3 Age Groups vs 3 Preferences)
# Rows: Young, Middle, Old
# Cols: Option A, Option B, Option C
table = [
    30 10 10;  # Young mostly prefer A
    10 30 10;  # Middle mostly prefer B
    10 10 30   # Old mostly prefer C
]
r_labs = ["Young", "Middle", "Old"]
c_labs = ["Opt_A", "Opt_B", "Opt_C"]

# 1. Use Adjusted Standardized Residuals (ASR) with Bonferroni correction
res_asr = PostHocContingencyCell(table, method=:asr, adjustment=:bonferroni,
                                 row_labels=r_labs, col_labels=c_labs)

# Check the matrix of adjusted residuals (Z-scores)
# println(res_asr.stats_mat)

# Check which cells are significant (True/False matrix)
# println(res_asr.sig_mat)

# 2. Use One-vs-Rest Fisher's Exact Test with FDR (Benjamini-Hochberg) adjustment
res_fisher = PostHocContingencyCell(table, method=:fisher_1vsall, adjustment=:bh,
                                    row_labels=r_labs, col_labels=c_labs)
```
"""
function PostHocContingencyCell(table::AbstractMatrix{<:Integer};
    method::Symbol=:asr,
    adjustment::Symbol=:bonferroni,
    alpha::Float64=0.05,
    row_labels::Vector{String}=String[],
    col_labels::Vector{String}=String[])

    rows, cols = size(table)

    # Auto-detect labels if not provided
    row_labels = _get_auto_labels(table, 1, row_labels, "R")
    col_labels = _get_auto_labels(table, 2, col_labels, "C")

    total = sum(table)
    row_sums = sum(table, dims=2)
    col_sums = sum(table, dims=1)

    stats_mat = zeros(Float64, rows, cols)
    pvals_mat = zeros(Float64, rows, cols)

    if method == :asr
        # Adjusted Standardized Residuals
        # Z = (Obs - Exp) / sqrt(Exp * (1 - RowProp) * (1 - ColProp))
        for i in 1:rows, j in 1:cols
            expected = (row_sums[i] * col_sums[j]) / total
            obs = table[i, j]
            r_prop = row_sums[i] / total
            c_prop = col_sums[j] / total

            denom = sqrt(expected * (1 - r_prop) * (1 - c_prop))
            z_score = (denom == 0) ? 0.0 : (obs - expected) / denom

            stats_mat[i, j] = z_score
            # Two-tailed p-value from Normal distribution
            pvals_mat[i, j] = 2.0 * ccdf(Normal(), abs(z_score))
        end

    elseif method == :fisher_1vsall
        # One-vs-Rest Fisher's Exact Test
        # Constructs a 2x2 table for each cell: [Cell, RowRest; ColRest, TableRest]
        for i in 1:rows, j in 1:cols
            a = table[i, j]
            b = row_sums[i] - a
            c = col_sums[j] - a
            d = total - row_sums[i] - col_sums[j] + a

            # Using standard exact test for 2x2
            ft = FisherExactTest(a, b, c, d)
            pvals_mat[i, j] = pvalue(ft)

            # Calculate Odds Ratio with simple smoothing to avoid division by zero
            safe_b = (b == 0) ? 0.5 : b
            safe_c = (c == 0) ? 0.5 : c
            safe_a = (a == 0) ? 0.5 : a
            safe_d = (d == 0) ? 0.5 : d
            stats_mat[i, j] = (safe_a * safe_d) / (safe_b * safe_c)
        end
    else
        error("Unknown cell method :$method. Supported: :asr, :fisher_1vsall")
    end

    # Flatten, Adjust, and Reshape P-values
    flat_p = vec(pvals_mat)
    flat_adj = adjust_pvalues(flat_p, adjustment)
    adj_pvals_mat = reshape(flat_adj, rows, cols)

    sig_mat = adj_pvals_mat .< alpha

    return ContingencyCellTestResult(method, adjustment, table, stats_mat, pvals_mat, adj_pvals_mat, sig_mat, alpha, row_labels, col_labels)
end



"""
    PostHocContingencyRow(table::AbstractMatrix{<:Integer}; method=:chisq, adjustment=:bonferroni, cld=false, alpha=0.05, pairs=nothing, row_labels=[])

Perform pairwise comparisons between rows of a contingency table to identify which groups differ significantly in their distribution across columns.

# Arguments
- `table::AbstractMatrix{<:Integer}`: The RxC contingency table.

# Keyword Arguments
- `method::Symbol`: The statistical test to use for pairwise comparisons.
    - `:chisq` (Default): Pearson's Chi-square test. Fast and standard for large samples.
    - `:fisher`: Fisher's Exact Test. 
        - For **2x2** sub-tables, it computes the exact p-value.
        - For **2xC** sub-tables (where C > 2), it estimates the p-value via Monte Carlo simulation (see `FisherExactTestRxC`).
- `adjustment::Symbol`: The method to adjust p-values for multiple comparisons.
    - `:bonferroni`: Strong control of FWER (p * m).
    - `:bh` (or `:fdr`): Benjamini-Hochberg procedure for False Discovery Rate control.
    - `:none`: No adjustment.
- `alpha::Float64`: Significance level. Defaults to `0.05`.
- `cld::Bool`: If `true`, generates Compact Letter Display codes based on the proportion of the first column. Defaults to `false`.
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of row indices to compare (e.g., `[(1, 2), (1, 3)]`). If `nothing` (default), all possible pairwise combinations are tested.
- `row_labels`: Optional vector of strings to label the rows in the output.

# Returns
Returns a `PostHocTestResult` object containing comparison statistics and adjusted p-values.

# Example

```julia
using HypothesisTests

# Data: 4 Groups (Rows) vs 3 Outcomes (Cols: Success, Neutral, Fail)
# Group 1 and 2 are similar, Group 3 is different, Group 4 is very different
table = [
    50 30 20; # Group 1
    48 32 20; # Group 2 (Similar to 1)
    20 40 40; # Group 3 (Different)
    10 10 80  # Group 4 (Very different)
]
row_labs = ["Grp1", "Grp2", "Grp3", "Grp4"]

# 1. Standard Pairwise Chi-Square with Bonferroni adjustment
# Also requesting Compact Letter Display (cld=true)
res_chisq = PostHocContingencyRow(table, method=:chisq, adjustment=:bonferroni, 
                                  cld=true, row_labels=row_labs)

# Inspect the Compact Letter Display (if generated)
# println(res_chisq.letters) 
# Expected: Grp1 and Grp2 might share a letter (e.g., "a"), Grp3 "b", Grp4 "c"

# 2. Pairwise Fisher's Exact Test (Robust for small counts and supports RxC)
# Only comparing Group 1 vs Group 4 and Group 1 vs Group 3
specific_pairs = [(1, 4), (1, 3)]
res_fisher = PostHocContingencyRow(table, method=:fisher, adjustment=:none,
                                   pairs=specific_pairs, row_labels=row_labs)

# Print p-values for the specific pairs
for cmp in res_fisher.comparisons
    println("Comparing \$(row_labs[cmp.idx_a]) vs \$(row_labs[cmp.idx_b]): p = \$(cmp.p_val)")
end
```
"""
function PostHocContingencyRow(table::AbstractMatrix{<:Integer};
    method::Symbol=:chisq,
    adjustment::Symbol=:bonferroni,
    cld::Bool=false,
    alpha::Float64=0.05,
    pairs::Union{Nothing,Vector{Tuple{Int,Int}}}=nothing,
    row_labels::Vector{String}=String[])

    if !haskey(CONTINGENCY_METHOD_DISPATCH, method)
        error("Unknown method :$method. Supported: $(keys(CONTINGENCY_METHOD_DISPATCH))")
    end

    rows, cols = size(table)

    # Auto-detect row labels if not provided
    row_labels = _get_auto_labels(table, 1, row_labels, "Row")

    # Determine pairs to compare
    target_pairs = Vector{Tuple{Int,Int}}()
    if isnothing(pairs)
        for i in 1:rows, j in (i+1):rows
            push!(target_pairs, (i, j))
        end
    else
        target_pairs = pairs
    end

    # Create Data Context
    data = ContingencyData(table, target_pairs, alpha)

    # Run selected algorithm
    raw_results = CONTINGENCY_METHOD_DISPATCH[method](data)

    # Extract P-values for adjustment
    raw_pvals = [r.pval for r in raw_results]
    adj_pvals = adjust_pvalues(raw_pvals, adjustment)

    # Build Final Comparisons objects
    final_comparisons = PostHocComparison[]
    for k in 1:length(raw_results)
        res = raw_results[k]
        adj_p = adj_pvals[k]
        
        # Construct a descriptive note including the adjustment method
        final_note = isempty(res.note) ? "Adj: $adjustment" : "$(res.note); Adj: $adjustment"

        push!(final_comparisons, PostHocComparison(
            res.r1, res.r2, 0.0, 0.0, res.stat, 0.0, adj_p, 0.0, 0.0, adj_p < alpha, final_note
        ))
    end

    # Generate Compact Letter Display (CLD) if requested
    letters = Dict{Int,String}()
    if cld
        row_sums = sum(table, dims=2)
        # Use proportion of the first column for ordering in CLD
        props = [row_sums[i] > 0 ? table[i, 1] / row_sums[i] : 0.0 for i in 1:rows]
        letters = generate_cld(props, final_comparisons, alpha)
    end

    # Create Label Map
    label_map = Dict{Int,String}()
    for (i, l) in enumerate(row_labels)
        label_map[i] = l
    end

    return PostHocTestResult(Symbol("Row_$(method)"), final_comparisons, alpha, cld, letters, label_map)
end