#FILEPATH: ext/DataFramesExt/grouped/twosample.jl

"""
    HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)

Two-sample Student t-test with equal variances from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.EqualVarianceTTest(x, y)
end

"""
    HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)

Welch two-sample t-test from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.UnequalVarianceTTest(x, y)
end

"""
    HypothesisTests.SignTest(gd::GroupedDataFrame, data_col::Symbol, median::Real=0)

Paired sign test using group difference (`x - y`) from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.SignTest(gd::GroupedDataFrame, data_col::Symbol, median::Real = 0)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignTest(x - y, median)
end

"""
    HypothesisTests.SignedRankTest(gd::GroupedDataFrame, data_col::Symbol)

Paired Wilcoxon signed-rank test from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.SignedRankTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignedRankTest(x, y)
end

"""
    HypothesisTests.VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)

F test for equality of variances from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.VarianceFTest(x, y)
end

"""
    HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)

Mann-Whitney U test from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric or Ordered).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "MannWhitneyU requires numeric or ordered DV.")
    force_num = _is_ordered(parent_df[!, data_col])
    x, y = _extract_two_groups(gd, data_col; force_numeric_data=force_num)
    return HypothesisTests.MannWhitneyUTest(x, y)
end

"""
    HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)

Approximate two-sample Kolmogorov-Smirnov test from a `GroupedDataFrame`.
Type requirements: `data_col` (Numeric).
`gd` must contain exactly 2 groups.
"""
function HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.ApproximateTwoSampleKSTest(x, y)
end
