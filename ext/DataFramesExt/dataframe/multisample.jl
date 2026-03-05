function HypothesisTests.OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.OneWayANOVATest(groups...)
end

function WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return WelchANOVATest(groups...)
end

function HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "KruskalWallis requires numeric or ordered DV.")
    force_num = _is_ordered(df[!, data_col])
    groups, _ = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return HypothesisTests.KruskalWallisTest(groups...)
end

function HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.LeveneTest(groups...)
end

function HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.BrownForsytheTest(groups...)
end

function HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return HypothesisTests.FlignerKilleenTest(groups...)
end
