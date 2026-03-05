# src/PostHoc/types.jl


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

struct KWStatData
    k::Int
    n_total::Int
    mean_ranks::Vector{Float64}
    ns::Vector{Int}
    tie_correction::Float64
    alpha::Float64
    pairs::Vector{Tuple{Int, Int}}
end


# Internal struct to pass data to algorithms
struct ContingencyData
    table::AbstractMatrix{<:Integer}
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

function Base.show(io::IO, res::PostHocTestResult)
    println(io, "")
    println(io, repeat("-", 30))
    println(io, "Post-hoc Test: :$(res.method) (alpha=$(res.alpha))")
    println(io, repeat("-", 30))

    # Helper to get label or fallback to index
    get_label(idx::Int) = get(res.label_map, idx, string(idx))

    if res.use_cld && !isempty(res.cld_letters)
        group_indices = collect(keys(res.label_map))
        if isempty(group_indices)
            group_indices = collect(keys(res.cld_letters))
        end
        sort!(group_indices)

        cld_data = Matrix{Any}(undef, length(group_indices), 3)
        for (i, g) in enumerate(group_indices)
            cld_data[i, 1] = g
            cld_data[i, 2] = get_label(g)
            cld_data[i, 3] = get(res.cld_letters, g, "")
        end

        println(io, "\nCompact Letter Display (Means sorted descending):")
        pretty_table(
            io,
            cld_data;
            column_labels = ["GroupIndex", "GroupLabel", "CLD"]
        )
    end

    println(io, "\nPairwise Comparisons:")
    n = length(res.comparisons)
    cmp_data = Matrix{Any}(undef, n, 10)

    for (i, c) in enumerate(res.comparisons)
        cmp_data[i, 1]  = "$(get_label(c.group1)) - $(get_label(c.group2))"
        cmp_data[i, 2]  = c.diff
        cmp_data[i, 3]  = c.se
        cmp_data[i, 4]  = c.statistic
        cmp_data[i, 5]  = c.crit_val
        cmp_data[i, 6]  = c.p_value
        cmp_data[i, 7]  = c.lower_ci
        cmp_data[i, 8]  = c.upper_ci
        cmp_data[i, 9]  = c.rejected ? "*" : ""
        cmp_data[i, 10] = c.note
    end

    all_labels = ["Contrast", "Diff", "Std.Err", "Stat", "Critical", "P-value", "Lower 95%", "Upper 95%", "Sig", "Note"]

    # Drop columns that are entirely NaN
    keep_cols = trues(size(cmp_data, 2))
    if n > 0
        for j in 1:size(cmp_data, 2)
            col = cmp_data[:, j]
            if all(x -> (x isa AbstractFloat) && isnan(x), col)
                keep_cols[j] = false
            end
        end
    end

    cmp_data_show = cmp_data[:, keep_cols]
    labels_show   = all_labels[keep_cols]

    pretty_table(
        io,
        cmp_data_show;
        column_labels = labels_show
    )
end


function Base.show(io::IO, res::ContingencyCellTestResult)
    println(io, "")
    println(io, repeat("=", 40))
    println(io, "Post-hoc Cell Analysis: :$(res.method)")
    println(io, "Adjustment: :$(res.adjust_method) (alpha=$(res.alpha))")
    println(io, repeat("=", 40))

    stat_name = (res.method == :asr) ? "Z" : "OR"
    rows, cols = size(res.observed)

    # Build matrix-style display without relying on DataFrames extension
    table_data = Matrix{Any}(undef, rows, cols + 1)
    for i in 1:rows
        table_data[i, 1] = res.row_labels[i]
        for j in 1:cols
            val = round(res.stats_matrix[i, j], digits=2)
            mark = res.sig_matrix[i, j] ? "*" : ""
            table_data[i, j + 1] = string(val, mark)
        end
    end

    header = vcat(["RowLabel"], res.col_labels)

    println(io, "\nTable content: $stat_name (Significance*)")
    pretty_table(
        io,
        table_data;
        column_labels = header,
        alignment = :c
    )

    println(io, "\n* Significant at p < $(res.alpha) after correction.")
end

"""
    CellTestToDataframe(res::ContingencyCellTestResult)

Generate a matrix-form DataFrame from ContingencyCellTestResult.
Cell content format is "Value*" (if significant) or "Value".

**NOTE**: activate the extension `HypothesisTestsExtraDataFramesExt` to use this function:
```julia
using HypothesisTestsExtra
using DataFrames, CategoricalArrays, FreqTables, NamedArrays
```
"""
function CellTestToDataframe end


"""
    GroupTestToDataframe(res::PostHocTestResult)

Get CLD (Compact Letter Display) labels of PostHocTestResult as a DataFrame.
Returns columns: `GroupIndex`, `GroupLabel`, and `CLD`.

**NOTE**: activate the extension `HypothesisTestsExtraDataFramesExt` to use this function:
```julia
using HypothesisTestsExtra
using DataFrames, CategoricalArrays, FreqTables, NamedArrays
```
"""
function GroupTestToDataframe end

function DataFrame end
