# PostHoc/posthoc_structures.jl

# using DataFrames
# using Printf
# using PrettyTables

# ==============================================================================
# Post-hoc Structures
# ==============================================================================

"""
    PostHocComparison

Stores the statistical results of a single pairwise comparison between two groups.

# Fields
- `group1::Int`: Index of the first group in the comparison.
- `group2::Int`: Index of the second group in the comparison.
- `diff::Float64`: The difference between means (Group1 - Group2).
- `se::Float64`: Standard Error of the difference.
- `statistic::Float64`: Test statistic (e.g., t-value or q-value).
- `crit_val::Float64`: Critical value for the test statistic at the specified alpha.
- `p_value::Float64`: Calculated p-value for the comparison.
- `lower_ci::Float64`: Lower bound of the confidence interval.
- `upper_ci::Float64`: Upper bound of the confidence interval.
- `rejected::Bool`: Boolean flag indicating if the null hypothesis was rejected (significant difference).
- `note::String`: Additional annotations or warnings (e.g., "ns", "***").
"""
struct PostHocComparison
    group1::Int
    group2::Int
    diff::Float64
    se::Float64
    statistic::Float64
    crit_val::Float64
    p_value::Float64
    lower_ci::Float64
    upper_ci::Float64
    rejected::Bool
    note::String
end

"""
    PostHocTestResult

Container for the results of a post-hoc multiple comparison test.

# Fields
- `method::Symbol`: The name of the post-hoc method used (e.g., `:tukey`, `:bonferroni`).
- `comparisons::Vector{PostHocComparison}`: A list of all pairwise comparisons performed.
- `alpha::Float64`: The significance level used for the test (e.g., 0.05).
- `use_cld::Bool`: Whether Compact Letter Display (CLD) was calculated.
- `cld_letters::Dict{Int, String}`: Mapping of group indices to CLD letters (if applicable).
- `label_map::Dict{Int, String}`: Mapping of internal group indices back to original labels (e.g., "Control", "Treat").

# Methods
- `DataFrame(res)`: Convert detailed pairwise results to a DataFrame.
- `GroupTestToDataframe(res)`: Convert CLD results to a DataFrame.
"""
struct PostHocTestResult
    method::Symbol
    comparisons::Vector{PostHocComparison}
    alpha::Float64
    use_cld::Bool
    cld_letters::Dict{Int, String}
    # Map internal index (1, 2...) back to original DataFrame labels (e.g., "Control", "Treat")
    label_map::Dict{Int, String} 
end

"""
    GroupTestToDataframe(res::PostHocTestResult)

Get CLD (Compact Letter Display) labels of PostHocTestResult as a DataFrame.
Returns columns: `GroupIndex`, `GroupLabel`, and `CLD`.
"""
function GroupTestToDataframe(res::PostHocTestResult)
    group_indices = collect(keys(res.label_map))
    
    if isempty(group_indices) && !isempty(res.cld_letters)
        group_indices = collect(keys(res.cld_letters))
    end
    
    sort!(group_indices)
    
    labels = [get(res.label_map, g, string(g)) for g in group_indices]
    
    letters = [get(res.cld_letters, g, "") for g in group_indices]
    
    return DataFrame(
        GroupIndex = group_indices,
        GroupLabel = labels,
        CLD = letters
    )
end

function DataFrames.DataFrame(res::PostHocTestResult)
    get_label(idx::Int) = get(res.label_map, idx, string(idx))
    n = length(res.comparisons)
    contrasts = Vector{String}(undef, n)
    diffs = Vector{Float64}(undef, n)
    ses = Vector{Float64}(undef, n)
    stats = Vector{Float64}(undef, n)
    crits = Vector{Float64}(undef, n)
    p_values = Vector{Float64}(undef, n)
    lower_cis = Vector{Float64}(undef, n)
    upper_cis = Vector{Float64}(undef, n)
    sigs = Vector{String}(undef, n)
    notes = Vector{String}(undef, n)

    for (i, c) in enumerate(res.comparisons)
        l1 = get_label(c.group1)
        l2 = get_label(c.group2)
        contrasts[i] = "$l1 - $l2"
        
        diffs[i] = c.diff
        ses[i] = c.se
        stats[i] = c.statistic
        crits[i] = c.crit_val
        p_values[i] = c.p_value
        lower_cis[i] = c.lower_ci
        upper_cis[i] = c.upper_ci
        sigs[i] = c.rejected ? "*" : ""
        notes[i] = c.note
    end

    return DataFrame(
        "Contrast"    => contrasts,
        "Diff"        => diffs,
        "Std.Err"     => ses,
        "Stat"        => stats,
        "Critical"    => crits,
        "P-value"     => p_values,
        "Lower 95%"   => lower_cis,
        "Upper 95%"   => upper_cis,
        "Sig"         => sigs,
        "Note"        => notes
    )
end

function Base.show(io::IO, res::PostHocTestResult)
    println(io, "")
    println(io, repeat("-", 30))
    println(io, "Post-hoc Test: :$(res.method) (alpha=$(res.alpha))")
    println(io, repeat("-", 30))
    
    # Helper to get label or fallback to index
    function get_label(idx::Int)
        return get(res.label_map, idx, string(idx))
    end

    if res.use_cld && !isempty(res.cld_letters)
        println(io, "\nCompact Letter Display (Means sorted descending):")
        pretty_table(io, GroupTestToDataframe(res))
    end

    println(io, "\nPairwise Comparisons:")
    pretty_table(io, DataFrame(res))
end

# Internal struct for passing data between algorithms
struct StatData
    k::Int
    means::Vector{Float64}
    vars::Vector{Float64}
    ns::Vector{Int}
    mse::Float64
    df_resid::Float64
    alpha::Float64
    pairs::Vector{Tuple{Int, Int}} 
end

"""
    ContingencyCellTestResult

Stores the results of post-hoc cell-wise analysis for contingency tables (e.g., Adjusted Standardized Residuals).

# Fields
- `method::Symbol`: The method used for cell analysis (e.g., `:asr` for Adjusted Standardized Residuals).
- `adjust_method::Symbol`: P-value adjustment method for multiple comparisons (e.g., `:bonferroni`, `:fdr`).
- `observed::Matrix{Int}`: The original matrix of observed counts.
- `stats_matrix::Matrix{Float64}`: Matrix of test statistics (e.g., Z-scores for ASR or Odds Ratios).
- `pvals_matrix::Matrix{Float64}`: Matrix of raw p-values.
- `adj_pvals_matrix::Matrix{Float64}`: Matrix of adjusted p-values.
- `sig_matrix::Matrix{Bool}`: Boolean matrix indicating significance at the given alpha level.
- `alpha::Float64`: Significance level.
- `row_labels::Vector{String}`: Labels for the rows of the contingency table.
- `col_labels::Vector{String}`: Labels for the columns of the contingency table.
"""
struct ContingencyCellTestResult
    method::Symbol
    adjust_method::Symbol
    observed::Matrix{Int}
    stats_matrix::Matrix{Float64} # ASR or Odds Ratio
    pvals_matrix::Matrix{Float64}
    adj_pvals_matrix::Matrix{Float64}
    sig_matrix::Matrix{Bool}
    alpha::Float64
    row_labels::Vector{String}
    col_labels::Vector{String}
end

# ==============================================================================
# ContingencyCellTestResult Extensions
# ==============================================================================

"""
    DataFrames.DataFrame(res::ContingencyCellTestResult)

Convert ContingencyCellTestResult to a detailed DataFrame (Long Format).
Each row represents a cell in the contingency table.
"""
function DataFrames.DataFrame(res::ContingencyCellTestResult)
    rows, cols = size(res.observed)
    n_total = rows * cols
    
    # Pre-allocate vectors
    r_labels = Vector{String}(undef, n_total)
    c_labels = Vector{String}(undef, n_total)
    observed = Vector{Int}(undef, n_total)
    stats    = Vector{Float64}(undef, n_total)
    pvals    = Vector{Float64}(undef, n_total)
    adj_pvals= Vector{Float64}(undef, n_total)
    is_sig   = Vector{Bool}(undef, n_total)
    
    idx = 1
    for i in 1:rows
        for j in 1:cols
            r_labels[idx]  = res.row_labels[i]
            c_labels[idx]  = res.col_labels[j]
            observed[idx]  = res.observed[i, j]
            stats[idx]     = res.stats_matrix[i, j]
            pvals[idx]     = res.pvals_matrix[i, j]
            adj_pvals[idx] = res.adj_pvals_matrix[i, j]
            is_sig[idx]    = res.sig_matrix[i, j]
            idx += 1
        end
    end
    
    stat_col_name = (res.method == :asr) ? "ASR (Z)" : "OddsRatio"

    return DataFrame(
        "Row"           => r_labels,
        "Column"        => c_labels,
        "Observed"      => observed,
        stat_col_name   => stats,
        "P-value"       => pvals,
        "Adj. P-value"  => adj_pvals,
        "Significant"   => is_sig
    )
end

"""
    CellTestToDataframe(res::ContingencyCellTestResult)

Generate a matrix-form DataFrame from ContingencyCellTestResult.
Cell content format is "Value*" (if significant) or "Value".
"""
function CellTestToDataframe(res::ContingencyCellTestResult)
    rows, cols = size(res.observed)
    
    # Create base DataFrame, first column is row labels
    df = DataFrame(RowLabel = res.row_labels)
    
    # Iterate through each column (corresponding to contingency table columns)
    for j in 1:cols
        col_label = res.col_labels[j]
        col_data = Vector{String}(undef, rows)
        
        for i in 1:rows
            val = res.stats_matrix[i, j]
            is_sig = res.sig_matrix[i, j]
            sig_mark = is_sig ? "*" : ""
            
            # Format: "Value (Sig)"
            col_data[i] = @sprintf("%.2f%s", val, sig_mark)
        end
        
        # Add the column to the DataFrame
        # Note: Using column labels directly as DataFrame column names
        df[!, col_label] = col_data
    end
    
    return df
end

function Base.show(io::IO, res::ContingencyCellTestResult)
    println(io, "")
    println(io, repeat("=", 40))
    println(io, "Post-hoc Cell Analysis: :$(res.method)")
    println(io, "Adjustment: :$(res.adjust_method) (alpha=$(res.alpha))")
    println(io, repeat("=", 40))
    
    stat_name = (res.method == :asr) ? "Z" : "OR"
    
    # Get DataFrame for display
    display_df = CellTestToDataframe(res)
    
    println(io, "\nTable content: $stat_name (Significance*)")
    
    # Print DataFrame using PrettyTables
    # Header is automatically taken from DataFrame column names
    pretty_table(io, display_df; 
        alignment = :c
    )
    
    println(io, "\n* Significant at p < $(res.alpha) after correction.")
end
