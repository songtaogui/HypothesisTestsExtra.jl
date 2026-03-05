function HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.OneWayANOVATest(groups...)
end

function WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return WelchANOVATest(groups...)
end

function HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(_is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), "KruskalWallis requires numeric or ordered DV.")
    force_num = _is_ordered(parent_df[!, data_col])
    groups, _ = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return HypothesisTests.KruskalWallisTest(groups...)
end

function HypothesisTests.LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.LeveneTest(groups...)
end

function HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.BrownForsytheTest(groups...)
end

function HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return HypothesisTests.FlignerKilleenTest(groups...)
end
