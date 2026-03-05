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

function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary)
    tbl, _, _ = _pivot_freq_table(df, data_col, group_col, nothing)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, data_col, group_col, freq_col)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end

function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end
