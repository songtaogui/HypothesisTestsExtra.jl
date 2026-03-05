#FILEPATH: ext/DataFramesExt/grouped/multisample.jl

"""
    HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)

One-way ANOVA across groups defined by `gd`.
Type requirements: `data_col` (Numeric).
"""
function HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)

Welch one-way ANOVA across groups defined by `gd`.
Type requirements: `data_col` (Numeric).
"""
function WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return WelchANOVATest(groups...)
end

"""
    HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)

Kruskal-Wallis rank-sum test across groups defined by `gd`.
Type requirements: `data_col` (Numeric or Ordered).
Ordered data are converted to numeric level codes internally.
"""
function HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "KruskalWallis requires numeric or ordered DV.")
    force_num = _is_ordered(parent_df[!, data_col])
    groups, _ = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return HypothesisTests.KruskalWallisTest(groups...)
end

"""
    HypothesisTests.LeveneTest(gd::GroupedDataFrame, data_col::Symbol)

Levene test for homogeneity of variances across groups defined by `gd`.
Type requirements: `data_col` (Numeric).
"""
function HypothesisTests.LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.LeveneTest(groups...)
end

"""
    HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)

Brown-Forsythe test for homogeneity of variances across groups defined by `gd`.
Type requirements: `data_col` (Numeric).
"""
function HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.BrownForsytheTest(groups...)
end

"""
    HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)

Fligner-Killeen test for homogeneity of variances across groups defined by `gd`.
Type requirements: `data_col` (Numeric).
"""
function HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.FlignerKilleenTest(groups...)
end
