# PostHoc/posthoc_contingency.jl

# ==============================================================================
# Post-hoc tests for RxC Contingency Tables (Chi-sq / Fisher)
# ==============================================================================

# using HypothesisTests
# using Distributions
# using StatsAPI

# ==============================================================================
# Helper: Labels and P-value Adjustments
# ==============================================================================

"""
    _get_auto_labels(table::AbstractMatrix, dim::Int, manual_labels::Vector{String}, prefix::String)

Internal helper function to resolve row or column labels.

Resolution Priority:
1. User-provided `manual_labels`.
2. Automatic extraction via `names(table, dim)` (supports `NamedArrays.jl`).
3. Default generated labels (e.g., "R1", "R2").

# Arguments
- `table`: The contingency table.
- `dim`: Dimension to extract (1 for rows, 2 for columns).
- `manual_labels`: Vector of strings provided by the user.
- `prefix`: Prefix for default label generation (e.g., "Row").
"""
function _get_auto_labels(table::AbstractMatrix, dim::Int, manual_labels::Vector{String}, prefix::String)
    # 1. Use manual labels if provided and valid
    if !isempty(manual_labels)
        return manual_labels
    end

    # 2. Try to extract names (Support for NamedArrays.jl and similar structures)
    try
        extracted = names(table, dim)
        if length(extracted) == size(table, dim)
            return string.(extracted)
        end
    catch
        # Fallthrough on MethodError (not a NamedArray) or other indexing issues
    end

    # 3. Default fallback: Generate generic labels
    return ["$prefix$i" for i in 1:size(table, dim)]
end

"""
    adjust_pvalues(pvals::Vector{Float64}, method::Symbol)

Adjust a vector of p-values for multiple comparisons to control the family-wise error rate or false discovery rate.

# Arguments
- `pvals`: A vector of raw p-values.
- `method`: The adjustment method.
    - `:bonferroni`: Bonferroni correction (p * n). Strong control of FWER.
    - `:bh` (or `:fdr`): Benjamini-Hochberg procedure. Controls False Discovery Rate.
    - `:none`: Returns p-values unchanged.
"""
function adjust_pvalues(pvals::Vector{Float64}, method::Symbol)
    n = length(pvals)
    if n <= 1
        return pvals
    end

    adj_p = copy(pvals)

    if method == :bonferroni
        adj_p .= min.(1.0, pvals .* n)
    elseif method == :bh || method == :fdr
        # Benjamini-Hochberg procedure
        perm = sortperm(pvals)
        inv_perm = sortperm(perm)
        sorted_p = pvals[perm]

        cummin_val = 1.0
        for i in n:-1:1
            val = sorted_p[i] * (n / i)
            cummin_val = min(cummin_val, val)
            sorted_p[i] = min(1.0, cummin_val)
        end
        adj_p = sorted_p[inv_perm]
    elseif method == :none
        return pvals
    else
        error("Unknown adjustment method: :$method. Supported: :bonferroni, :bh (fdr), :none")
    end
    return adj_p
end

# ==============================================================================
# Part 1: Cell-Level Post-hoc (ASR & One-vs-Rest Fisher)
# ==============================================================================

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

# ==============================================================================
# Part 2: Group-Level (Row-wise) Post-hoc Algorithms
# ==============================================================================

# Internal struct to pass data to algorithms
struct ContingencyData
    table::AbstractMatrix{Int}
    pairs::Vector{Tuple{Int,Int}}
    alpha::Float64
end

# Helper struct to return raw results from _run_ methods
struct RawComparisonResult
    r1::Int
    r2::Int
    stat::Float64
    pval::Float64
    note::String
end

# --- Chi-Square Method ---
"""
    _run_chisq_row(d::ContingencyData)

Runs pairwise Chi-square tests for row comparisons.
"""
function _run_chisq_row(d::ContingencyData)
    results = RawComparisonResult[]

    for (r1, r2) in d.pairs
        sub_table = d.table[[r1, r2], :]

        # Clean: Remove columns where sum is 0 to avoid DoF errors
        col_mask = vec(sum(sub_table, dims=1) .> 0)
        clean_sub = sub_table[:, col_mask]

        stat_val = 0.0
        p_val = 1.0
        note = ""

        try
            if size(clean_sub, 2) < 2
                note = "Degenerate"
            else
                ct = ChisqTest(clean_sub)
                stat_val = ct.chisq
                p_val = pvalue(ct)
            end
        catch
            p_val = 1.0
            note = "Error"
        end

        push!(results, RawComparisonResult(r1, r2, stat_val, p_val, note))
    end
    return results
end

# --- Fisher Method (Exact 2x2 or Monte Carlo RxC) ---
"""
    _run_fisher_row(d::ContingencyData)

Runs pairwise Fisher's Exact tests. Uses the `FisherExactTestRxC` smart constructor
to automatically select between the exact 2x2 test and the Monte Carlo simulation for RxC tables.
"""
function _run_fisher_row(d::ContingencyData)
    results = RawComparisonResult[]

    for (r1, r2) in d.pairs
        sub_table = d.table[[r1, r2], :]

        # Clean: Remove columns where sum is 0
        col_mask = vec(sum(sub_table, dims=1) .> 0)
        clean_sub = sub_table[:, col_mask]

        stat_val = 0.0
        p_val = 1.0
        note = ""

        cols = size(clean_sub, 2)

        if cols < 2
            note = "Degenerate"
        else
            # Use the smart constructor.
            # It returns either HypothesisTests.FisherExactTest (for 2x2)
            # or FisherExactTestMC (for 2xC where C > 2).
            ft = FisherExactTestRxC(clean_sub)
            
            p_val = pvalue(ft)
            
            # Determine statistic and note based on the returned type
            if isa(ft, FisherExactTestMC)
                # For Monte Carlo, the statistic is the log-probability metric
                stat_val = ft.log_prob_obs 
                note = "MC RxC"
            else
                # For Standard 2x2, use the Odds Ratio (omega)
                stat_val = ft.omega
                note = "Exact 2x2"
            end
        end

        push!(results, RawComparisonResult(r1, r2, stat_val, p_val, note))
    end
    return results
end

const CONTINGENCY_METHOD_DISPATCH = Dict(
    :chisq => _run_chisq_row,
    :fisher => _run_fisher_row
)

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
