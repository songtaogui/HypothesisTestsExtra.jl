# helpers.jl

# using DataFrames
# using NamedArrays
# using HypothesisTests

# ==============================================================================
#  Helper Functions
# ==============================================================================

"""
    _format_group_key(key)

Internal helper to format a `GroupKey` or row-like object into a readable string string.
If the key consists of multiple columns, they are joined by " | ".
"""
function _format_group_key(key)
    # Extract values from the GroupKey (which acts like a NamedTuple/Row)
    vals = values(key)
    if length(vals) == 1
        return string(vals[1])
    else
        return join(string.(vals), " | ")
    end
end

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
    _extract_groups_with_labels(gd::GroupedDataFrame, data_col::Symbol)

Internal helper function to extract numerical data from a `GroupedDataFrame`.

# Behavior
1. Iterates through the groups defined in `gd`.
2. Extracts corresponding data from `data_col` for each group.
3. Skips `missing` values within the data column.
4. Warns if a group becomes empty after filtering.

# Returns
- `groups`: A `Vector{Vector{Float64}}` where each element is the data for a group.
- `labels_str`: A `Vector{String}` containing the group keys formatted as strings.
"""
function _extract_groups_with_labels(gd::GroupedDataFrame, data_col::Symbol)
    groups = Vector{Vector{Float64}}()
    labels_str = String[]

    for (key, subdf) in pairs(gd)
        group_data = collect(skipmissing(subdf[!, data_col]))
        lbl = _format_group_key(key)
        
        if isempty(group_data)
            @warn "Group '$lbl' is empty after removing missing values."
        end

        push!(groups, Vector{Float64}(group_data))
        push!(labels_str, lbl)
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
    _extract_two_groups(gd::GroupedDataFrame, data_col::Symbol)

Internal helper function to extract exactly two groups from a `GroupedDataFrame`.
Throws an error if the `GroupedDataFrame` does not contain exactly two groups.

# Returns
- `group1`: Vector{Float64}
- `group2`: Vector{Float64}
"""
function _extract_two_groups(gd::GroupedDataFrame, data_col::Symbol)
    groups, labels = _extract_groups_with_labels(gd, data_col)
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

"""
    _pivot_freq_table(gd::GroupedDataFrame, col_col::Symbol)

Internal helper to generate a contingency table from a `GroupedDataFrame` and a column symbol.
Rows correspond to the groups in `gd`, and columns correspond to unique values in `col_col`.

# Returns
- `NamedArray`: A matrix with named dimensions.
"""
function _pivot_freq_table(gd::GroupedDataFrame, col_col::Symbol)
    # Collect all unique values for the column (columns of the contingency table)
    # We iterate over all sub-dataframes to find all unique non-missing values
    all_vals = Set{Any}()
    for subdf in gd
        union!(all_vals, skipmissing(subdf[!, col_col]))
    end
    c_labels_raw = sort(collect(all_vals))
    c_labels = string.(c_labels_raw)
    c_map = Dict(val => i for (i, val) in enumerate(c_labels_raw))
    
    # Row labels from GroupedDataFrame keys using the formatter
    r_labels = [_format_group_key(key) for key in keys(gd)]
    
    # Build Matrix
    n_rows = length(gd)
    n_cols = length(c_labels)
    data_mat = zeros(Int, n_rows, n_cols)
    
    for (i, subdf) in enumerate(gd)
        for val in skipmissing(subdf[!, col_col])
            if haskey(c_map, val)
                data_mat[i, c_map[val]] += 1
            end
        end
    end
    
    return NamedArray(data_mat, (r_labels, c_labels), ("Group", string(col_col)))
end
