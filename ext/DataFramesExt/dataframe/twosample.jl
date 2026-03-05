function HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.EqualVarianceTTest(x, y)
end

function HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.UnequalVarianceTTest(x, y)
end

function HypothesisTests.SignTest(df::DataFrame, group_col::Symbol, data_col::Symbol, median::Real = 0)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.SignTest(x - y, median)
end

function HypothesisTests.SignedRankTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.SignedRankTest(x, y)
end

function HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.VarianceFTest(x, y)
end

function HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "MannWhitneyU requires numeric or ordered DV.")
    force_num = _is_ordered(df[!, data_col])
    x, y = _extract_two_groups(df, group_col, data_col; force_numeric_data=force_num)
    return HypothesisTests.MannWhitneyUTest(x, y)
end

function HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return HypothesisTests.ApproximateTwoSampleKSTest(x, y)
end
