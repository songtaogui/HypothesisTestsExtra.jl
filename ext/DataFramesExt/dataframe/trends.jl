#FILEPATH: ext/DataFramesExt/dataframe/trends.jl

"""
    JonckheereTerpstraTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Jonckheere-Terpstra trend test across ordered groups.
Type requirements: `group_col` (Ordered categorical), `data_col` (Numeric or Ordered).
Ordered response data are converted to numeric level codes internally.
"""
function JonckheereTerpstraTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :ordered)
    _assert_requirement(
        _is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]),
        "JonckheereTerpstra requires numeric or ordered DV."
    )

    force_num = _is_ordered(df[!, data_col])
    groups, _ = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return JonckheereTerpstraTest(groups)
end

"""
    CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Cochran-Armitage trend test for binary outcome across ordered groups.
Type requirements: `group_col` (Ordered categorical), `data_col` (Binary).
"""
function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary)
    tbl, _, _ = _pivot_freq_table(df, data_col, group_col, nothing)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

"""
    CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; kwargs...)

Cochran-Armitage trend test with frequency weights.
Type requirements: `group_col` (Ordered categorical), `data_col` (Binary), `freq_col` (Numeric integer-like counts).
"""
function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, data_col, group_col, freq_col)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

"""
    LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Linear-by-linear association test for two ordered categorical variables.
Type requirements: `row_col` (Ordered categorical), `col_col` (Ordered categorical).
"""
function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end

"""
    LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Linear-by-linear association test for weighted ordered contingency tables.
Type requirements: `row_col` (Ordered categorical), `col_col` (Ordered categorical), `freq_col` (Numeric integer-like counts).
"""
function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end
