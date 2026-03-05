function JonckheereTerpstraTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    g_cols = groupcols(gd)

    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Jonckheere-Terpstra requires ordered groups.")
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "Jonckheere-Terpstra requires numeric or ordered DV.")

    force_num = _is_ordered(parent_df[!, data_col])
    groups, _ = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return JonckheereTerpstraTest(groups)
end

function CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, data_col => :binary)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Cochran-Armitage requires ordered groups.")

    tbl, _, _ = _pivot_freq_table(gd, data_col, nothing)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

function CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol, freq_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, data_col => :binary, freq_col => :numeric)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Cochran-Armitage requires ordered groups.")

    tbl, _, _ = _pivot_freq_table(gd, data_col, freq_col)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

function LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, col_col => :ordered)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Linear-by-Linear requires ordered groups.")

    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end

function LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, col_col => :ordered, freq_col => :numeric)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Linear-by-Linear requires ordered groups.")

    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end
