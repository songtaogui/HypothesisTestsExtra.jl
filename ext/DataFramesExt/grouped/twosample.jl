function HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.EqualVarianceTTest(x, y)
end

function HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.UnequalVarianceTTest(x, y)
end

function HypothesisTests.SignTest(gd::GroupedDataFrame, data_col::Symbol, median::Real = 0)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignTest(x - y, median)
end

function HypothesisTests.SignedRankTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignedRankTest(x, y)
end

function HypothesisTests.VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.VarianceFTest(x, y)
end

function HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "MannWhitneyU requires numeric or ordered DV.")
    force_num = _is_ordered(parent_df[!, data_col])
    x, y = _extract_two_groups(gd, data_col; force_numeric_data=force_num)
    return HypothesisTests.MannWhitneyUTest(x, y)
end

function HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.ApproximateTwoSampleKSTest(x, y)
end
