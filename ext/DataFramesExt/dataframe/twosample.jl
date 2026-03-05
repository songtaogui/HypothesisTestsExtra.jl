#FILEPATH: ext/DataFramesExt/dataframe/twosample.jl

"""
    HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Two-sample Student t-test with equal variances.
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.EqualVarianceTTest(x, y)
end

"""
    HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Welch two-sample t-test (unequal variances).
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.UnequalVarianceTTest(x, y)
end

"""
    HypothesisTests.SignTest(df::DataFrame, group_col::Symbol, data_col::Symbol, median::Real=0)

Paired sign test using the difference between two groups (`x - y`).
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.SignTest(df::DataFrame, group_col::Symbol, data_col::Symbol, median::Real = 0)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.SignTest(x - y, median)
end

"""
    HypothesisTests.SignedRankTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Paired Wilcoxon signed-rank test between two groups.
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.SignedRankTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.SignedRankTest(x, y)
end

"""
    HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

F test for equality of variances between two groups.
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.VarianceFTest(x, y)
end

"""
    HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Mann-Whitney U test for two independent groups.
Type requirements: `group_col` (Binary), `data_col` (Numeric or Ordered).
Ordered data are converted to numeric level codes internally.
"""
function HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "MannWhitneyU requires numeric or ordered DV.")
    force_num = _is_ordered(df[!, data_col])
    x, y = _extract_two_groups(df, group_col, data_col; force_numeric_data=force_num)
    return HypothesisTests.MannWhitneyUTest(x, y)
end

"""
    HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Approximate two-sample Kolmogorov-Smirnov test.
Type requirements: `group_col` (Binary), `data_col` (Numeric).
The grouping column must define exactly 2 groups.
"""
function HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.ApproximateTwoSampleKSTest(x, y)
end
