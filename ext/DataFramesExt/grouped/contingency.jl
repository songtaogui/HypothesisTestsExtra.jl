#FILEPATH: ext/DataFramesExt/grouped/contingency.jl

"""
    PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; pairs=nothing, kwargs...)

Post-hoc row-wise comparisons for contingency tables from grouped records.
Type requirements: `col_col` (Categorical).
`pairs` may limit tested row-pairs.
"""
function PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, r_labels, _ = _pivot_freq_table(gd, col_col, nothing)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; pairs=nothing, kwargs...)

Post-hoc row-wise comparisons for weighted grouped contingency tables.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, r_labels, _ = _pivot_freq_table(gd, col_col, freq_col)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)

Post-hoc cell-wise tests for contingency tables from grouped records.
Type requirements: `col_col` (Categorical).
"""
function PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    return PostHocContingencyCell(tbl; kwargs...)
end

"""
    PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Post-hoc cell-wise tests for weighted grouped contingency tables.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

"""
    HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol)

Pearson chi-square test of independence from grouped records.
Type requirements: `col_col` (Categorical).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "ChisqTest requires at least 2x2 table.")
    return HypothesisTests.ChisqTest(tbl)
end

"""
    HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Pearson chi-square test of independence from weighted grouped records.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    return HypothesisTests.ChisqTest(tbl)
end

"""
    HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)

Fisher exact test from grouped records.
Type requirements: `col_col` (Categorical).
Requires a 2x2 contingency table.
"""
function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

"""
    HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Fisher exact test from weighted grouped records.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
Requires a 2x2 contingency table.
"""
function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)

Fisher exact test for general `R x C` tables from grouped records.
Type requirements: `col_col` (Categorical).
"""
function FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    return FisherExactTestRxC(tbl)
end

"""
    FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Fisher exact test for general `R x C` weighted tables from grouped records.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)

Power-divergence family test of independence from grouped records.
Type requirements: `col_col` (Categorical).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end

"""
    HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Power-divergence family test of independence from weighted grouped records.
Type requirements: `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(gd, col_col, freq_col)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end
