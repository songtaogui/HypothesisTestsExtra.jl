#FILEPATH: ext/DataFramesExt/grouped/posthoc.jl

"""
    PostHocPar(gd::GroupedDataFrame, data_col::Symbol; pairs=nothing, kwargs...)

Parametric post-hoc multiple comparisons from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` groups define the compared populations.
"""
function PostHocPar(gd::GroupedDataFrame, data_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, labels = _extract_groups_with_labels(gd, data_col)
    idx_pairs = _normalize_pairs(pairs, labels)
    return PostHocPar(groups; row_labels=labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; pairs=nothing, kwargs...)

Non-parametric post-hoc multiple comparisons from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric or Ordered).
Ordered data are converted to numeric level codes internally.
"""
function PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; pairs=nothing, kwargs...)
    parent_df = parent(gd)
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "Column :$data_col must be numeric or ordered.")

    force_num = _is_ordered(parent_df[!, data_col])
    groups, labels = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    idx_pairs = _normalize_pairs(pairs, labels)
    return PostHocNonPar(groups; row_labels=labels, pairs=idx_pairs, kwargs...)
end
