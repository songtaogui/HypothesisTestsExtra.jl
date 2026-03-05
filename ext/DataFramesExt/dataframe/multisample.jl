#FILEPATH: ext/DataFramesExt/dataframe/multisample.jl

"""
    HypothesisTests.OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

One-way ANOVA across multiple groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function HypothesisTests.OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Welch one-way ANOVA across multiple groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return WelchANOVATest(groups...)
end

"""
    HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Kruskal-Wallis rank-sum test across multiple groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric or Ordered).
Ordered data are converted to numeric level codes internally.
"""
function HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "KruskalWallis requires numeric or ordered DV.")
    force_num = _is_ordered(df[!, data_col])
    groups, _ = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return HypothesisTests.KruskalWallisTest(groups...)
end

"""
    HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Levene test for homogeneity of variances across groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.LeveneTest(groups...)
end

"""
    HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Brown-Forsythe test for homogeneity of variances across groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.BrownForsytheTest(groups...)
end

"""
    HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Fligner-Killeen test for homogeneity of variances across groups.
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.FlignerKilleenTest(groups...)
end
