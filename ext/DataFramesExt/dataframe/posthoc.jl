#FILEPATH: ext/DataFramesExt/dataframe/posthoc.jl

"""
    PostHocPar(df::DataFrame, group_col::Symbol, data_col::Symbol; pairs=nothing, kwargs...)

Parametric post-hoc multiple comparisons from a `DataFrame`.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
`pairs` may be `nothing` or a subset of pairwise comparisons.
"""
function PostHocPar(df::DataFrame, group_col::Symbol, data_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    idx_pairs = _normalize_pairs(pairs, labels)
    return PostHocPar(groups; row_labels=labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; pairs=nothing, kwargs...)

Non-parametric post-hoc multiple comparisons from a `DataFrame`.
Type requirements: `group_col` (Categorical), `data_col` (Numeric or Ordered).
Ordered data are converted to numeric level codes internally.
"""
function PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, group_col => :categorical)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "Column :$data_col must be numeric or ordered.")
    force_num = _is_ordered(df[!, data_col])
    groups, labels = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    idx_pairs = _normalize_pairs(pairs, labels)
    return PostHocNonPar(groups; row_labels=labels, pairs=idx_pairs, kwargs...)
end
