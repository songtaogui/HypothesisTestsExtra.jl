# dataframe_ext.jl

# ==============================================================================
#  Helper Functions
# ==============================================================================

"""
    _extract_groups_with_labels(df::DataFrame, group_col::Symbol, data_col::Symbol)

Internal helper function to extract numerical data grouped by a categorical column.

# Behavior
1. Identifies unique labels in `group_col`, excluding `missing`.
2. Iterates through labels to extract corresponding data from `data_col`.
3. Skips `missing` values within the data column.
4. Warns if a group becomes empty after filtering.

# Returns
- `groups`: A `Vector{Vector{Float64}}` where each element is the data for a group.
- `labels_str`: A `Vector{String}` containing the sorted group names.
"""
function _extract_groups_with_labels(df::DataFrame, group_col::Symbol, data_col::Symbol)
    unique_labels = sort(unique(skipmissing(df[!, group_col])))
    
    groups = Vector{Vector{Float64}}()
    labels_str = String[]
    
    for lbl in unique_labels
        group_mask = isequal.(df[!, group_col], lbl)
        group_data = collect(skipmissing(df[group_mask, data_col]))
        
        if isempty(group_data)
            @warn "Group '$lbl' is empty after removing missing values."
        end

        push!(groups, Vector{Float64}(group_data))
        push!(labels_str, string(lbl))
    end
    
    return groups, labels_str
end

"""
    _extract_two_groups(df::DataFrame, group_col::Symbol, data_col::Symbol)

Internal helper function to extract exactly two groups for T-tests or similar binary comparisons.
Throws an error if the grouping column does not contain exactly two unique non-missing labels.

# Returns
- `group1`: Vector{Float64}
- `group2`: Vector{Float64}
"""
function _extract_two_groups(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    if length(groups) != 2
        error("This test requires exactly 2 groups. Found $(length(groups)) valid groups: $labels")
    end
    return groups[1], groups[2]
end

"""
    _pivot_freq_table(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Internal helper to convert long-format frequency data into a Named Matrix (Contingency Table).
Fills missing combinations with 0.

# Returns
- `NamedArray`: A matrix with named dimensions corresponding to the row and column labels.
"""
function _pivot_freq_table(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    # 1. Drop rows where any of the keys or the count is missing
    df_clean = dropmissing(df[:, [row_col, col_col, freq_col]])
    
    # 2. Pivot: Unstack to Wide Format (Rows x Cols), filling gaps with 0
    wide_df = unstack(df_clean, row_col, col_col, freq_col, fill=0)
    
    # 3. Extract Labels
    # The first column of wide_df is the row identifier
    r_labels = string.(wide_df[!, 1])
    # The remaining columns are the column identifiers
    c_labels = names(wide_df)[2:end]
    
    # 4. Extract Data Matrix
    data_mat = Matrix{Int}(wide_df[:, 2:end])
    
    # 5. Return NamedArray
    # Dimensions are named after the original DataFrame columns
    return NamedArray(data_mat, (r_labels, c_labels), (string(row_col), string(col_col)))
end

# ==============================================================================
# Extension: Post-hoc Tests
# ==============================================================================

"""
    PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform non-parametric post-hoc pairwise comparisons (e.g., Dunn's Test) directly on a DataFrame.

# Arguments
- `df`: The DataFrame containing the raw data.
- `group_col`: Symbol representing the column with group labels.
- `data_col`: Symbol representing the column with numerical observations.
- `kwargs`: Arguments passed to the core `PostHocNonPar` function (e.g., `method`, `alpha`, `p_adjust`).
"""
function PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    return PostHocNonPar(groups; row_labels=labels, kwargs...)
end

"""
    PostHocTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform parametric post-hoc pairwise comparisons (e.g., Tukey's HSD) directly on a DataFrame.

# Arguments
- `df`: The DataFrame containing the raw data.
- `group_col`: Symbol representing the column with group labels.
- `data_col`: Symbol representing the column with numerical observations.
- `kwargs`: Arguments passed to the core `PostHocTest` function.
"""
function PostHocTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    return PostHocTest(groups; row_labels=labels, kwargs...)
end

# --- Contingency Table Post-Hoc: Raw Data (Row-wise) ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons (e.g., Chi-Sq or Fisher) on raw categorical data.
The function automatically aggregates the data into a contingency table (counts) before analysis.

# Arguments
- `df`: DataFrame containing raw observations (one row per subject).
- `row_col`: Column determining the table rows (groups to compare).
- `col_col`: Column determining the table columns (outcomes).
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

# --- Contingency Table Post-Hoc: Frequency Data (Row-wise) ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons on aggregated frequency data (Long format).

# Arguments
- `df`: DataFrame containing aggregated counts.
- `row_col`: Column determining the table rows.
- `col_col`: Column determining the table columns.
- `freq_col`: Column containing the integer counts/frequencies.

# Process
Pivots the DataFrame into a matrix (using `unstack`), filling missing combinations with 0, then calls the core logic.
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

# --- Contingency Table Post-Hoc: Raw Data (Cell-wise) ---

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis (e.g., ASR) on raw categorical data.

The function automatically aggregates the data into a contingency table (counts) before analysis.

# Arguments
- `df`: DataFrame containing raw observations (one row per subject).
- `row_col`: Column determining the table rows (groups to compare).
- `col_col`: Column determining the table columns (outcomes).
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

# --- Contingency Table Post-Hoc: Frequency Data (Cell-wise) ---

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis on aggregated frequency data (Long format).

# Arguments
- `df`: DataFrame containing aggregated counts.
- `row_col`: Column determining the table rows.
- `col_col`: Column determining the table columns.
- `freq_col`: Column containing the integer counts/frequencies.
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

# ==============================================================================
# Extension: Standard Categorical Tests
# ==============================================================================

"""
    ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Pearson's Chi-square test from a raw DataFrame.
Generates a contingency table internally. Requires at least a 2x2 table.
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("ChisqTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return ChisqTest(tbl)
end


"""
    ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Pearson's Chi-square test from aggregated frequency data (Long format).
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("ChisqTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return ChisqTest(tbl)
end

"""
    FisherExactTest(tbl::AbstractMatrix{<:Integer})

Compute Fisher's Exact Test from a contingency table. 
Currently supports only 2x2 tables. For RxC tables, use `FisherExactTestRxC`,
which supports both the Monte Carlo Fisher's exact test (RxC) and the exact 2x2 test.
"""
function HypothesisTests.FisherExactTest(tbl::AbstractMatrix{<:Integer})
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test from a raw DataFrame.
Currently supports only 2x2 tables. For RxC tables, use `FisherExactTestRxC`,
which supports both the Monte Carlo Fisher's exact test (RxC) and the exact 2x2 test.
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test for general RxC tables from a raw DataFrame.

This function aggregates the DataFrame columns into a contingency table and then
applies `FisherExactTestRxC`.

- If the resulting table is 2x2, it calculates the exact p-value.
- If the resulting table is RxC (larger than 2x2), it estimates the p-value via Monte Carlo simulation.

# Arguments
- `df`: DataFrame containing raw observations.
- `row_col`: Column determining the table rows.
- `col_col`: Column determining the table columns.
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    # The matrix dispatch handles the logic for 2x2 vs RxC
    return FisherExactTestRxC(tbl)
end

"""
    FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test (2x2) from aggregated frequency data (Long format).
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test (RxC or 2x2) from aggregated frequency data (Long format).
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; lambda::Real=1.0)

Compute Power Divergence Test (e.g., G-test if lambda=0) from a raw DataFrame.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("PowerDivergenceTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return PowerDivergenceTest(tbl; kwargs...)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; lambda::Real=1.0)

Compute Power Divergence Test from aggregated frequency data (Long format).
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("PowerDivergenceTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return PowerDivergenceTest(tbl; kwargs...)
end


# ==============================================================================
# Extension: K-Sample & Variance Tests
# ==============================================================================

"""
    OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform One-Way ANOVA to test equality of means across groups in a DataFrame.
"""
function HypothesisTests.OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's ANOVA (does not assume equal variances) on a DataFrame.
"""
function WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return WelchANOVATest(groups...)
end

"""
    KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Kruskal-Wallis Rank Sum Test (non-parametric ANOVA) on a DataFrame.
"""
function HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return KruskalWallisTest(groups...)
end

"""
    LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Levene's Test for equality of variances across groups in a DataFrame.
"""
function HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return LeveneTest(groups...)
end

"""
    BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Brown-Forsythe Test (robust Levene's test using median) for equality of variances.
"""
function HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return BrownForsytheTest(groups...)
end

"""
    FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Fligner-Killeen Test (non-parametric) for equality of variances.
"""
function HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return FlignerKilleenTest(groups...)
end

# ==============================================================================
# Extension: 2-Sample Tests
# ==============================================================================

"""
    EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Student's T-Test (assuming equal variance) between exactly two groups in a DataFrame.
"""
function HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return EqualVarianceTTest(x, y)
end

"""
    UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's T-Test (not assuming equal variance) between exactly two groups in a DataFrame.
"""
function HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return UnequalVarianceTTest(x, y)
end

"""
    VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform F-Test to compare the variances of exactly two groups in a DataFrame.
"""
function HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return VarianceFTest(x, y)
end

"""
    MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Mann-Whitney U Test (Wilcoxon Rank Sum) between exactly two groups in a DataFrame.
"""
function HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return MannWhitneyUTest(x, y)
end

"""
    ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Approximate Two-Sample Kolmogorov-Smirnov Test between exactly two groups in a DataFrame.
"""
function HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return ApproximateTwoSampleKSTest(x, y)
end
